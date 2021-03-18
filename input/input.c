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

#include <err.h>
#include <stdio.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>

#include <linux/input.h>

#include "input.h"
#include <sys/types.h>
#include <sys/wait.h>

#define CODE_FAKE_IN_SAVER      10000
#define CODE_FAKE_OUT_SAVER     10001
#define CODE_FAKE_USB_PLUG_IN   10010
#define CODE_FAKE_USB_PLUG_OUT  10011
#define CODE_FAKE_CHARGING      10020
#define CODE_FAKE_NOT_CHARGING  10021

#define NUM_FDS 4U
int nfds = 0;
int inputfds[NUM_FDS] = { -1, -1, -1, -1 };
pid_t fake_ev_generator_pid = -1;

#if defined POCKETBOOK
    #include "input-pocketbook.h"
#elif defined KINDLE
    #include "input-kindle.h"
#elif defined KOBO
    #include "input-kobo.h"
#elif defined REMARKABLE
    #include "input-remarkable.h"
#elif defined SONY_PRSTUX
    #include "input-sony-prstux.h"
#elif defined CERVANTES
    #include "input-cervantes.h"
#endif

static inline int findFreeFdSlot() {
    for (size_t i = 0; i < NUM_FDS; i++) {
        if (inputfds[i] == -1) {
            return i;
        }
    }
    return -1;
}

static int openInputDevice(lua_State *L) {
    const char *inputdevice = luaL_checkstring(L, 1);
    int fd = findFreeFdSlot();
    if (fd == -1) {
        return luaL_error(L, "no free slot for new input device <%s>", inputdevice);
    }
    char *ko_dont_grab_input = getenv("KO_DONT_GRAB_INPUT");


#ifdef POCKETBOOK
    int inkview_events = luaL_checkint(L, 2);
    if (inkview_events == 1) {
        startInkViewMain(L, fd, inputdevice);
        return 0;
    }
#endif

    if (!strcmp("fake_events", inputdevice)) {
        /* special case: the power slider for kindle and plug event for kobo */
        int pipefd[2];
        pipe(pipefd);

        pid_t childpid;
        if ((childpid = fork()) == -1) {
            return luaL_error(L, "cannot fork() fake event generator");
        }
        if (childpid == 0) {
            /* deliver SIGTERM to child when parent crashes */
            prctl(PR_SET_PDEATHSIG, SIGTERM);
            /* this function needs to be implemented in each platform-specific input header */
            generateFakeEvent(pipefd);
            /* We're done, go away :) */
            _exit(EXIT_SUCCESS);
        } else {
            printf("[ko-input] Forked off fake event generator (pid: %ld).\n", (long) childpid);
            close(pipefd[1]);
            inputfds[fd] = pipefd[0];
            fake_ev_generator_pid = childpid;
        }
    } else {
        inputfds[fd] = open(inputdevice, O_RDONLY | O_NONBLOCK);
        if (inputfds[fd] != -1) {
            if (ko_dont_grab_input == NULL) {
                ioctl(inputfds[fd], EVIOCGRAB, 1);
            }

            /* Prevents our children from inheriting the fd, which is unnecessary here,
             * and would potentially be problematic for long-running scripts (e.g., Wi-Fi stuff) and USBMS.
             * NOTE: We do the legacy fcntl dance because open only supports O_CLOEXEC since Linux 2.6.23,
             *       and legacy Kindles run on 2.6.22... */
            int fdflags = fcntl(inputfds[fd], F_GETFD);
            fcntl(inputfds[fd], F_SETFD, fdflags | FD_CLOEXEC);

            /* Compute select's nfds argument.
             * That's not the actual number of fds in the set, like poll(),
             * but the highest fd number in the set + 1 (c.f., select(2)). */
            if (inputfds[i] >= nfds) {
                nfds = inputfds[i] + 1;
            }

            return 0;
        } else {
            return luaL_error(L, "error opening input device <%s>: %d", inputdevice, errno);
        }
    }
    return 0;
}

static int closeInputDevices(lua_State *L __attribute__((unused))) {
    for (size_t i = 0; i < NUM_FDS; i++) {
        if(inputfds[i] != -1) {
            ioctl(inputfds[i], EVIOCGRAB, 0);
            close(inputfds[i]);
        }
    }
    if (fake_ev_generator_pid != -1) {
        /* kill and wait for child process */
        kill(fake_ev_generator_pid, SIGTERM);
        waitpid(-1, NULL, 0);
    }
    return 0;
}

static int fakeTapInput(lua_State *L) {
    const char* inputdevice = luaL_checkstring(L, 1);
    int x = luaL_checkint(L, 2);
    int y = luaL_checkint(L, 3);

    int inputfd = open(inputdevice, O_WRONLY | O_NONBLOCK);
    if (inputfd == -1) {
        return luaL_error(L, "cannot open input device <%s>", inputdevice);
    }

    struct input_event ev = { 0 };
    gettimeofday(&ev.time, NULL);
    ev.type = 3;
    ev.code = 57;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 3;
    ev.code = 53;
    ev.value = x;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 3;
    ev.code = 54;
    ev.value = y;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 1;
    ev.code = 330;
    ev.value = 1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 1;
    ev.code = 325;
    ev.value = 1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 0;
    ev.code = 0;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 3;
    ev.code = 57;
    ev.value = -1;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 1;
    ev.code = 330;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 1;
    ev.code = 325;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));
    gettimeofday(&ev.time, NULL);
    ev.type = 0;
    ev.code = 0;
    ev.value = 0;
    write(inputfd, &ev, sizeof(ev));

    ioctl(inputfd, EVIOCGRAB, 0);
    close(inputfd);
    return 0;
}

static inline void set_event_table(lua_State *L, struct input_event input) {
    lua_newtable(L);
    lua_pushstring(L, "type");
    lua_pushinteger(L, (int) input.type);
    lua_settable(L, -3);
    lua_pushstring(L, "code");
    lua_pushinteger(L, (int) input.code);
    lua_settable(L, -3);
    lua_pushstring(L, "value");
    lua_pushinteger(L, (int) input.value);
    lua_settable(L, -3);

    lua_pushstring(L, "time");
    lua_newtable(L);
    lua_pushstring(L, "sec");
    lua_pushinteger(L, (int) input.time.tv_sec);
    lua_settable(L, -3);
    lua_pushstring(L, "usec");
    lua_pushinteger(L, (int) input.time.tv_usec);
    lua_settable(L, -3);
    lua_settable(L, -3);
}

static int waitForInput(lua_State *L) {
    lua_Integer sec = luaL_optinteger(L, 1, -1); // Fallback to -1 to handle detecting a nil
    lua_Integer usec = luaL_optinteger(L, 2, 0);

    struct timeval timeout;
    struct timeval *timeout_ptr = NULL;
    // If sec was nil, leave the timeout as NULL (i.e., block)
    if (sec != -1) {
        timeout.tv_sec = sec;
        timeout.tv_usec = usec;
        timeout_ptr = &timeout;
    }

    fd_set rfds;
    FD_ZERO(&rfds);
    for (size_t i = 0; i < NUM_FDS; i++) {
        if (inputfds[i] != -1) {
            FD_SET(inputfds[i], &rfds);
        }
    }

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

    for (size_t i = 0; i < NUM_FDS; i++) {
        if (inputfds[i] != -1 && FD_ISSET(inputfds[i], &rfds)) {
            struct input_event input;
            ssize_t readsz = read(inputfds[i], &input, sizeof(struct input_event));
            if (readsz == sizeof(struct input_event)) {
                lua_pushboolean(L, true);
                set_event_table(L, input);
                return 2;  // true, ev
            }
        }
    }
    return 0;  // Unreachable (unless there was a read error)
}

static const struct luaL_Reg input_func[] = {
    {"open", openInputDevice},
    {"closeAll", closeInputDevices},
    {"waitForEvent", waitForInput},
    {"fakeTapInput", fakeTapInput},
#ifdef POCKETBOOK
    {"setSuspendState", setSuspendState},
#endif
    {NULL, NULL}
};

int luaopen_input(lua_State *L) {
    /* disable buffering on stdout for logging purpose */
    setbuf(stdout, NULL);
    luaL_register(L, "input", input_func);
    return 1;
}
