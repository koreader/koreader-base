/*
    KOReader: input abstraction for Lua
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>
    Copyright (C) 2016 Qingping Hou <dave2008713@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#define _GNU_SOURCE
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <unistd.h>

#include <linux/input.h>

#include "input.h"
#include <sys/types.h>
#include <sys/wait.h>

#define CODE_FAKE_IN_SAVER            10000
#define CODE_FAKE_OUT_SAVER           10001
#define CODE_FAKE_USB_PLUG_IN         10010
#define CODE_FAKE_USB_PLUG_OUT        10011
#define CODE_FAKE_CHARGING            10020
#define CODE_FAKE_NOT_CHARGING        10021
#define CODE_FAKE_WAKEUP_FROM_SUSPEND 10030
#define CODE_FAKE_READY_TO_SUSPEND    10031

#ifndef ARRAY_SIZE
#    define ARRAY_SIZE(x) (sizeof(x) / sizeof(*(x)))
#endif

int    nfds                  = 0;  // for select()
int    inputfds[]            = { -1, -1, -1, -1 };
size_t fd_idx                = 0U;  // index of the *next* fd in inputfds (also, *current* amount of open fds)
pid_t  fake_ev_generator_pid = -1;

#if defined(POCKETBOOK)
#    include "input-pocketbook.h"
#elif defined(KINDLE)
#    include "input-kindle.h"
#elif defined(KOBO)
#    include "input-kobo.h"
#elif defined(REMARKABLE)
#    include "input-remarkable.h"
#elif defined(SONY_PRSTUX)
#    include "input-sony-prstux.h"
#elif defined(CERVANTES)
#    include "input-cervantes.h"
#endif

// NOTE: Legacy Kindle systems are too old to support timerfd (and we don't really need it there anyway),
//       and PocketBook uses a custom polling loop.
#if !defined(KINDLE_LEGACY) && !defined(POCKETBOOK)
#    include "timerfd-callbacks.h"
#endif

static int openInputDevice(lua_State* L)
{
    const char* restrict inputdevice = luaL_checkstring(L, 1);
    if (fd_idx >= ARRAY_SIZE(inputfds)) {
        return luaL_error(L, "No free slot for new input device <%s>", inputdevice);
    }
    // Otherwise, we're golden, and fd_idx is the index of the next free slot in the inputfds array ;).
    const char* restrict ko_dont_grab_input = getenv("KO_DONT_GRAB_INPUT");

#if defined(POCKETBOOK)
    int inkview_events = luaL_checkint(L, 2);
    if (inkview_events == 1) {
        startInkViewMain(L, fd_idx, inputdevice);
        return 0;
    }
#endif

    if (!strcmp("fake_events", inputdevice)) {
        // Special case: the power slider for Kindle and USB events for Kobo.
        int pipefd[2U];
#if defined(KINDLE_LEGACY)
        // pipe2 requires Linux 2.6.27 & glibc 2.9...
        if (pipe(pipefd) == -1) {
            return luaL_error(L, "Cannot create fake event generator communication pipe (pipe(): %d)", errno);
        }

        // Which means we need the fcntl dance like with open below...
        for (size_t i = 0U; i < 2U; i++) {
            int flflags = fcntl(pipefd[i], F_GETFL);
            fcntl(pipefd[i], F_SETFL, flflags | O_NONBLOCK);
            int fdflags = fcntl(pipefd[i], F_GETFD);
            fcntl(pipefd[i], F_SETFD, fdflags | FD_CLOEXEC);
        }
#else
        if (pipe2(pipefd, O_NONBLOCK | O_CLOEXEC) == -1) {
            return luaL_error(L, "Cannot create fake event generator communication pipe (pipe2(): %d)", errno);
        }
#endif

        pid_t childpid;
        if ((childpid = fork()) == -1) {
            return luaL_error(L, "Cannot fork() fake event generator (%d)", errno);
        }
        if (childpid == 0) {
            // Deliver SIGTERM to child when parent dies.
            prctl(PR_SET_PDEATHSIG, SIGTERM);
            // NOTE: This function needs to be implemented in each platform-specific input header.
            generateFakeEvent(pipefd);
            // We're done, go away :).
            _exit(EXIT_SUCCESS);
        } else {
            printf("[ko-input] Forked off fake event generator (pid: %ld)\n", (long) childpid);
            close(pipefd[1]);
            inputfds[fd_idx]      = pipefd[0];
            fake_ev_generator_pid = childpid;
        }
    } else {
        inputfds[fd_idx] = open(inputdevice, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (inputfds[fd_idx] != -1) {
            if (ko_dont_grab_input == NULL) {
                ioctl(inputfds[fd_idx], EVIOCGRAB, 1);
            }

            // Prevents our children from inheriting the fd, which is unnecessary here,
            // and would potentially be problematic for long-running scripts (e.g., Wi-Fi stuff) and USBMS.
#if defined(KINDLE_LEGACY)
            // NOTE: Legacy fcntl dance because open only supports O_CLOEXEC since Linux 2.6.23,
            //       and legacy Kindles run on 2.6.22...
            //       (It's silently ignored by open when unsupported).
            int fdflags = fcntl(inputfds[fd_idx], F_GETFD);
            fcntl(inputfds[fd_idx], F_SETFD, fdflags | FD_CLOEXEC);
#endif
        } else {
            return luaL_error(L, "Error opening input device <%s>: %d", inputdevice, errno);
        }
    }

    // We're done w/ inputdevice, pop it
    lua_settop(L, 0);
    // Pass the fd to Lua, we might need it for FFI ioctl shenanigans
    lua_pushinteger(L, inputfds[fd_idx]);

    // Compute select's nfds argument.
    // That's not the actual number of fds in the set, like poll(),
    // but the highest fd number in the set + 1 (c.f., select(2)).
    if (inputfds[fd_idx] >= nfds) {
        nfds = inputfds[fd_idx] + 1;
    }

    // That, on the other hand, *is* the number of open fds ;).
    fd_idx++;

    return 1; // fd
}

static int closeInputDevices(lua_State* L __attribute__((unused)))
{
    // Right now, we close everything, but, in the future, we may want to keep *some* slots open.
    // Note that doing that would (currently) require making sure those slots are at the start of the array,
    // in ascending fd number order, and that the array itself isn't sparse.
    for (ssize_t i = fd_idx - 1; i >= 0; i--) {
        if (inputfds[i] != -1) {
            ioctl(inputfds[i], EVIOCGRAB, 0);
            close(inputfds[i]);
            inputfds[i] = -1;
            fd_idx--;
        }
    }

#if defined(WITH_TIMERFD)
    clearAllTimers();
#endif

    if (fake_ev_generator_pid != -1) {
        // Kill and wait to reap our child process.
        kill(fake_ev_generator_pid, SIGTERM);
        waitpid(-1, NULL, 0);
        fake_ev_generator_pid = -1;
    }

    // Re-compute select's nfds
    if (fd_idx == 0U) {
        nfds = 0;
    } else {
        // The idea here being that we *may*, in the future, allow some early slots to stay put.
        nfds = inputfds[fd_idx - 1U] + 1;
    }

    return 0;
}

static int fakeTapInput(lua_State* L)
{
    const char* restrict inputdevice = luaL_checkstring(L, 1);
    int                  x           = luaL_checkint(L, 2);
    int                  y           = luaL_checkint(L, 3);

    int inputfd = open(inputdevice, O_WRONLY | O_NONBLOCK);
    if (inputfd == -1) {
        return luaL_error(L, "Cannot open input device <%s>: %d", inputdevice, errno);
    }

    // Pop function args, now that we're done w/ inputdevice
    lua_settop(L, 0);

    struct input_event ev = { 0 };
    gettimeofday(&ev.time, NULL);
    ev.type  = 3;
    ev.code  = 57;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 3;
    ev.code  = 53;
    ev.value = x;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 3;
    ev.code  = 54;
    ev.value = y;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 1;
    ev.code  = 330;
    ev.value = 1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 1;
    ev.code  = 325;
    ev.value = 1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 0;
    ev.code  = 0;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 3;
    ev.code  = 57;
    ev.value = -1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 1;
    ev.code  = 330;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 1;
    ev.code  = 325;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type  = 0;
    ev.code  = 0;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));

    ioctl(inputfd, EVIOCGRAB, 0);
    close(inputfd);
    return 0;
}

static inline void set_event_table(lua_State* L, const struct input_event* input)
{
    lua_createtable(L, 0, 4);  // ev = {} (pre-allocated for its four fields)
    lua_pushstring(L, "type");
    lua_pushinteger(L, input->type);  // uint16_t
    // NOTE: rawset does t[k] = v, with v @ -1, k @ -2 and t at the specified index, here, that's ev @ -3.
    //       This is why we always follow the same pattern: push table, push key, push value, set table[key] = value (which pops key & value)
    lua_rawset(L, -3);  // ev.type = input.type
    lua_pushstring(L, "code");
    lua_pushinteger(L, input->code);  // uint16_t
    lua_rawset(L, -3);                // ev.code = input.type
    lua_pushstring(L, "value");
    lua_pushinteger(L, input->value);  // int32_t
    lua_rawset(L, -3);                 // ev.value = input.value

    lua_pushstring(L, "time");
    // NOTE: This is TimeVal-like, but it doesn't feature its metatable!
    //       The frontend (device/input.lua) will convert it to a proper TimeVal object.
    lua_createtable(L, 0, 2);  // time = {} (pre-allocated for its two fields)
    lua_pushstring(L, "sec");
    lua_pushinteger(L, input->time.tv_sec);  // time_t
    lua_rawset(L, -3);                       // time.sec = input.time.tv_sec
    lua_pushstring(L, "usec");
    lua_pushinteger(L, input->time.tv_usec);  // suseconds_t
    lua_rawset(L, -3);                        // time.usec = input.time.tv_usec
    lua_rawset(L, -3);                        // ev.time = time
}

static inline size_t drain_input_queue(lua_State* L, struct input_event* input_queue, size_t ev_count, size_t j)
{
    if (lua_gettop(L) == 1) {
        // Only a single element in the stack? (that would be our `true` bool)?
        // That means this is the first call, create our array, pre-allocated to the necessary number of elements...
        // ...for this call, at least. Subsequent ones will insert event by event.
        // That said, multiple calls should be extremely rare:
        // We'd need to have filled the input_queue buffer *during* a single batch of events on the same fd ;).
        lua_createtable(L, ev_count, 0);  // We return an *array* of events, ev_array = {}
    }

    // Iterate over every input event in the queue buffer
    for (const struct input_event* event = input_queue; event < input_queue + ev_count; event++) {
        set_event_table(L, event);  // Pushed a new ev table all filled up at the top of the stack (that's -1)
        // NOTE: Here, rawseti basically inserts -1 in -2 @ [j]. We ensure that j always points at the tail.
        lua_rawseti(L, -2, ++j);  // table.insert(ev_array, ev) [, j]
    }
    return j;
}

static int waitForInput(lua_State* L)
{
    lua_Integer sec  = luaL_optinteger(L, 1, -1);  // Fallback to -1 to handle detecting a nil
    lua_Integer usec = luaL_optinteger(L, 2, 0);
    lua_settop(L, 0);  // Pop the function arguments

    struct timeval  timeout;
    struct timeval* timeout_ptr = NULL;
    // If sec was nil, leave the timeout as NULL (i.e., block).
    if (sec != -1) {
        timeout.tv_sec  = sec;
        timeout.tv_usec = usec;
        timeout_ptr     = &timeout;
    }

    fd_set rfds;
    FD_ZERO(&rfds);
    for (size_t i = 0U; i < fd_idx; i++) {
        FD_SET(inputfds[i], &rfds);
    }
#if defined(WITH_TIMERFD)
    for (timerfd_node_t* restrict node = timerfds.head; node != NULL; node = node->next) {
        FD_SET(node->fd, &rfds);
    }
#endif

    int num = select(nfds, &rfds, NULL, NULL, timeout_ptr);
    if (num == 0) {
        lua_pushboolean(L, false);
        lua_pushinteger(L, ETIME);
        return 2;  // false, ETIME
    } else if (num < 0) {
        // NOTE: The retry on EINTR is handled on the Lua side here.
        lua_pushboolean(L, false);
        lua_pushinteger(L, errno);
        return 2;  // false, errno
    }

    for (size_t i = 0U; i < fd_idx; i++) {
        if (FD_ISSET(inputfds[i], &rfds)) {
            lua_pushboolean(L, true);
            size_t j        = 0U;  // Index of ev_array's tail
            size_t ev_count = 0U;  // Amount of buffered events
            // NOTE: This should be more than enough ;).
            //       FWIW, this matches libevdev's default on most of our target devices,
            //       because they generally don't support querying the exact slot count via ABS_MT_SLOT.
            //       c.f., https://gitlab.freedesktop.org/libevdev/libevdev/-/blob/8d70f449892c6f7659e07bb0f06b8347677bb7d8/libevdev/libevdev.c#L66-101
            struct input_event  input_queue[256U];  // 4K on 32-bit, 6K on 64-bit
            struct input_event* queue_pos            = input_queue;
            size_t              queue_available_size = sizeof(input_queue);
            for (;;) {
                ssize_t len = read(inputfds[i], queue_pos, queue_available_size);

                if (len < 0) {
                    if (errno == EINTR) {
                        continue;
                    } else if (errno == EAGAIN) {
                        // Kernel queue drained :)
                        break;
                    } else {
                        lua_settop(L, 0);  // Kick our bogus bool (and potentially the ev_array table) from the stack
                        lua_pushboolean(L, false);
                        lua_pushinteger(L, errno);
                        return 2;  // false, errno
                    }
                }
                if (len == 0) {
                    // Should never happen
                    lua_settop(L, 0);
                    lua_pushboolean(L, false);
                    lua_pushinteger(L, EPIPE);
                    return 2;  // false, EPIPE
                }
                if (len > 0 && len % sizeof(*input_queue) != 0) {
                    // Truncated read?! (not a multiple of struct input_event)
                    lua_settop(L, 0);
                    lua_pushboolean(L, false);
                    lua_pushinteger(L, EINVAL);
                    return 2;  // false, EINVAL
                }

                // Okay, the read was sane, compute the amount of events we've just read
                size_t n = len / sizeof(*input_queue);
                ev_count += n;

                if ((size_t) len == queue_available_size) {
                    // If we're out of buffer space in the queue, drain it *now*
                    j = drain_input_queue(L, input_queue, ev_count, j);
                    // Rewind to the start of the queue to recycle the buffer
                    queue_pos            = input_queue;
                    queue_available_size = sizeof(input_queue);
                    ev_count             = 0U;
                } else {
                    // Otherwise, update our position in the queue buffer
                    queue_pos += n;
                    queue_available_size = queue_available_size - (size_t) len;
                }
            }
            // We've drained the kernel's input queue, now drain our buffer
            j = drain_input_queue(L, input_queue, ev_count, j);
            return 2;  // true, ev_array
        }
    }

#if defined(WITH_TIMERFD)
    // We check timers *last*, so that early timer invalidation has a chance to kick in when we're lagging behind input events,
    // as we will necessarily be at least 650ms late after a flashing refresh, for instance.
    for (timerfd_node_t* restrict node = timerfds.head; node != NULL; node = node->next) {
        if (FD_ISSET(node->fd, &rfds)) {
            // It's a single-shot timer, don't even need to read it ;p.
            lua_pushboolean(L, false);
            lua_pushinteger(L, ETIME);
            lua_pushlightuserdata(L, (void*) node);
            return 3;  // false, ETIME, node
        }
    }
#endif

    return 0;  // Unreachable (unless something is seriously screwy)
}

static const struct luaL_Reg input_func[] = { { "open", openInputDevice },
                                              { "closeAll", closeInputDevices },
                                              { "waitForEvent", waitForInput },
                                              { "fakeTapInput", fakeTapInput },
#if defined(POCKETBOOK)
                                              { "setSuspendState", setSuspendState },
#endif
#if defined(WITH_TIMERFD)
                                              { "setTimer", setTimer },
                                              { "clearTimer", clearTimer },
#endif
                                              { NULL, NULL } };

int luaopen_input(lua_State* L)
{
    // Disable buffering on stdout for logging purposes.
    setbuf(stdout, NULL);
    luaL_register(L, "input", input_func);
    return 1;
}
