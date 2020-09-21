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

#define NUM_FDS 4
int inputfds[4] = { -1, -1, -1, -1 };
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
    int i;
    for (i=0; i<NUM_FDS; i++) {
        if(inputfds[i] == -1) return i;
    }
    return -1;
}

static int openInputDevice(lua_State *L) {
    const char *inputdevice = luaL_checkstring(L, 1);
    int childpid;
    int fd = findFreeFdSlot();
    if (fd == -1) return luaL_error(L, "no free slot for new input device <%s>", inputdevice);
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
            printf("[ko-input] Forked off fake event generator(pid:%d).\n", childpid);
            close(pipefd[1]);
            inputfds[fd] = pipefd[0];
            fake_ev_generator_pid = childpid;
        }
    } else {
        inputfds[fd] = open(inputdevice, O_RDONLY | O_NONBLOCK, 0);
        if (inputfds[fd] != -1) {
            if (ko_dont_grab_input == NULL) {
                ioctl(inputfds[fd], EVIOCGRAB, 1);
            }

            /* prevent background command started from exec call from grabbing
             * input fd. for example: wpa_supplicant. */
            fcntl(inputfds[fd], F_SETFD, FD_CLOEXEC);
            return 0;
        } else {
            return luaL_error(L, "error opening input device <%s>: %d", inputdevice, errno);
        }
    }
    return 0;
}

static int closeInputDevices(lua_State *L) {
    int i;
    for (i=0; i<NUM_FDS; i++) {
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
    int i;
    int inputfd = -1;
    struct input_event ev;

    inputfd = open(inputdevice, O_WRONLY | O_NDELAY);
    if (inputfd == -1) return luaL_error(L, "cannot open input device <%s>", inputdevice);

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
    struct input_event input;
    fd_set fds;
    struct timeval timeout;
    struct timeval *timeout_ptr;
    int i, num, readsz, nfds = 0;
    int usecs = luaL_optint(L, 1, -1); // we check for <0 later

    if (usecs < 0) {
        timeout_ptr = NULL;
    } else {
        timeout.tv_sec = usecs / 1000000;
        timeout.tv_usec = usecs % 1000000;
        timeout_ptr = &timeout;
    }

    FD_ZERO(&fds);
    for (i=0; i<NUM_FDS; i++) {
        if (inputfds[i] != -1) FD_SET(inputfds[i], &fds);
        if (inputfds[i] + 1 > nfds) nfds = inputfds[i] + 1;
    }

    /* when no value is given as argument, we pass
     * NULL to select() for the timeout value, setting no
     * timeout at all. */
    num = select(nfds, &fds, NULL, NULL, timeout_ptr);
    if (num == 0) {
        return luaL_error(L, "Waiting for input failed: timeout\n");
    } else if (num < 0) {
        return luaL_error(L, "Waiting for input failed: %d\n", errno);
    }

    for (i=0; i<NUM_FDS; i++) {
        if (inputfds[i] != -1 && FD_ISSET(inputfds[i], &fds)) {
            readsz = read(inputfds[i], &input, sizeof(struct input_event));
            if (readsz == sizeof(struct input_event)) {
                set_event_table(L, input);
                return 1;
            }
        }
    }
    return 0;
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
