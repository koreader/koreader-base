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

#define CODE_FAKE_IN_SAVER     10000
#define CODE_FAKE_OUT_SAVER    10001
#define CODE_FAKE_USB_PLUG_IN  10010
#define CODE_FAKE_USB_PLUG_OUT 10011
#define CODE_FAKE_CHARGING     10020
#define CODE_FAKE_NOT_CHARGING 10021

#define NUM_FDS 4U
int    nfds                  = 0;
int    inputfds[NUM_FDS]     = { -1, -1, -1, -1 };
size_t num_fds               = 0U;
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
    if (num_fds >= NUM_FDS) {
        return luaL_error(L, "No free slot for new input device <%s>", inputdevice);
    }
    // Otherwise, we're golden, and num_fds is the index of the next free slot in the inputfds array ;).
    const char* restrict ko_dont_grab_input = getenv("KO_DONT_GRAB_INPUT");

#if defined(POCKETBOOK)
    int inkview_events = luaL_checkint(L, 2);
    if (inkview_events == 1) {
        startInkViewMain(L, num_fds, inputdevice);
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
            inputfds[num_fds]     = pipefd[0];
            fake_ev_generator_pid = childpid;
        }
    } else {
        inputfds[num_fds] = open(inputdevice, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        if (inputfds[num_fds] != -1) {
            if (ko_dont_grab_input == NULL) {
                ioctl(inputfds[num_fds], EVIOCGRAB, 1);
            }

            // Prevents our children from inheriting the fd, which is unnecessary here,
            // and would potentially be problematic for long-running scripts (e.g., Wi-Fi stuff) and USBMS.
#if defined(KINDLE_LEGACY)
            // NOTE: Legacy fcntl dance because open only supports O_CLOEXEC since Linux 2.6.23,
            //       and legacy Kindles run on 2.6.22...
            //       (It's silently ignored by open when unsupported).
            int fdflags = fcntl(inputfds[num_fds], F_GETFD);
            fcntl(inputfds[num_fds], F_SETFD, fdflags | FD_CLOEXEC);
#endif
        } else {
            return luaL_error(L, "Error opening input device <%s>: %d", inputdevice, errno);
        }
    }

    // Compute select's nfds argument.
    // That's not the actual number of fds in the set, like poll(),
    // but the highest fd number in the set + 1 (c.f., select(2)).
    if (inputfds[num_fds] >= nfds) {
        nfds = inputfds[num_fds] + 1;
    }

    // That, on the other hand, *is* the number of open fds ;).
    num_fds++;

    return 0;
}

static int closeInputDevices(lua_State* L __attribute__((unused)))
{
    for (size_t i = 0U; i < num_fds; i++) {
        if (inputfds[i] != -1) {
            ioctl(inputfds[i], EVIOCGRAB, 0);
            close(inputfds[i]);
            inputfds[i] = -1;
            num_fds--;
        }
    }

#if defined(WITH_TIMERFD)
    clearAllTimers();
#endif
    nfds = 0;

    if (fake_ev_generator_pid != -1) {
        // Kill and wait to reap our child process.
        kill(fake_ev_generator_pid, SIGTERM);
        waitpid(-1, NULL, 0);
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

static inline void set_event_table(lua_State* L, struct input_event input)
{
    lua_newtable(L); // ev = {}
    lua_pushstring(L, "type");
    lua_pushinteger(L, input.type);  // uint16_t
    // NOTE: rawset does t[k] = v, with v @ -1, k @ -2 and t at the specified index, here, that's ev @ -3.
    //       This is why we always follow the same pattern: push table, push key, push value, set table[key] = value (which pops key & value)
    lua_rawset(L, -3); // ev.type = input.type
    lua_pushstring(L, "code");
    lua_pushinteger(L, input.code);  // uint16_t
    lua_rawset(L, -3); // ev.code = input.type
    lua_pushstring(L, "value");
    lua_pushinteger(L, input.value);  // int32_t
    lua_rawset(L, -3); // ev.value = input.value

    lua_pushstring(L, "time");
    // NOTE: This is TimeVal-like, but it doesn't feature its metatable!
    //       The frontend (device/input.lua) will convert it to a proper TimeVal object.
    lua_newtable(L); // time = {}
    lua_pushstring(L, "sec");
    lua_pushinteger(L, input.time.tv_sec);  // time_t
    lua_rawset(L, -3); // time.sec = input.time.tv_sec
    lua_pushstring(L, "usec");
    lua_pushinteger(L, input.time.tv_usec);  // suseconds_t
    lua_rawset(L, -3); // time.usec = input.time.tv_usec
    lua_rawset(L, -3); // ev.time = time
}

static int waitForInput(lua_State* L)
{
    lua_Integer sec  = luaL_optinteger(L, 1, -1);  // Fallback to -1 to handle detecting a nil
    lua_Integer usec = luaL_optinteger(L, 2, 0);

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
    for (size_t i = 0U; i < num_fds; i++) {
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
        lua_pushboolean(L, false);
        lua_pushinteger(L, errno);
        return 2;  // false, errno
    }

    for (size_t i = 0U; i < num_fds; i++) {
        if (FD_ISSET(inputfds[i], &rfds)) {
            struct input_event input;
            size_t j = 0U;
            lua_pushboolean(L, true);
            lua_newtable(L); // We return an *array* of events, ev_array = {}
            while (read(inputfds[i], &input, sizeof(input)) == sizeof(input)) {
                set_event_table(L, input); // New ev table at the top of the stack (that's -1)
                lua_rawseti(L, -2, ++j); // table.insert(ev_array, ev) [, j]
            }
            printf("Read %zu events\n", j);
            return 2;  // true, ev
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

    return 0;  // Unreachable (unless there was a read error)
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
