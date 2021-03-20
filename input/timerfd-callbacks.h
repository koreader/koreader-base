/*
    KOReader: timerfd implementation of GestureDetector's timed input callback mechanism
    Copyright (C) 2021 NiLuJe <ninuje@gmail.com>

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

#include <stdio.h>
#include <stdint.h>
#include <sys/timerfd.h>

// So that the main input code knows it's built w/ timerfd support
#define WITH_TIMERFD 1

// FIXME: Less unwieldy storage handling (linked list?)
#define NUM_TFDS 24U
int timerfds[NUM_TFDS] = {
    -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1
};

static inline int getTfdSlot() {
    for (size_t i = 0U; i < NUM_TFDS; i++) {
        if (timerfds[i] == -1) {
            return i;
        }
    }
    return -1;
}

// clockid_t clock, time_t deadline_sec, suseconds_t deadline_usec
static inline int setTimer(lua_State *L) {
    int fd_idx = getTfdSlot();
    if (fd_idx == -1) {
        fprintf(stderr, "no free slot for new timer fd\n");
        return 0;
    }

    clockid_t clock           = luaL_checkint(L, 1);
    time_t deadline_sec       = luaL_checkinteger(L, 2);
    suseconds_t deadline_usec = luaL_checkinteger(L, 3);

    // Unlike in input.c, we know we're running a kernel recent enough to support the flags
    timerfds[fd_idx] = timerfd_create(clock, TFD_NONBLOCK | TFD_CLOEXEC);
    if (timerfds[fd_idx] == -1) {
        fprintf(stderr, "timerfd_create: %m\n");
        return 0;
    }

    // Arm the timer for the specified *absolute* deadline
    struct itimerspec clock_timer;
    clock_timer.it_value.tv_sec  = deadline_sec;
    // TIMEVAL_TO_TIMESPEC
    clock_timer.it_value.tv_nsec = deadline_usec * 1000;
    // We only need a single-shot timer
    clock_timer.it_interval.tv_sec  = 0;
    clock_timer.it_interval.tv_nsec = 0;

    if (timerfd_settime(timerfds[fd_idx], TFD_TIMER_ABSTIME, &clock_timer, NULL) == -1) {
        fprintf(stderr, "timerfd_settime: %m\n");
        // Cleanup
        close(timerfds[fd_idx]);
        timerfds[fd_idx] = -1;
        return 0;
    }

    // Need to update select's nfds, too...
    if (timerfds[fd_idx] >= nfds) {
        nfds = timerfds[fd_idx] + 1;
    }

    // Success!
    lua_pushinteger(L, timerfds[fd_idx]);
    return 1; // timerfd
}

static inline int findTfdSlot(int fd) {
    for (size_t i = 0U; i < NUM_TFDS; i++) {
        if (timerfds[i] == fd) {
            return i;
        }
    }
    return -1;
}

// int timerfd
static inline int clearTimer(lua_State *L) {
    int timerfd = luaL_checkint(L, 1);

    int fd_idx = findTfdSlot(timerfd);
    if (fd_idx == -1) {
        fprintf(stderr, "failed to find the torage slot of timerfd %d\n", timerfd);
        return 0;
    }

    // Cleanup
    close(timerfds[fd_idx]);
    timerfds[fd_idx] = -1;

    // FIXME: We kinda cheat by not recomputing nfds here...

    // Success!
    lua_pushboolean(L, true);
    return 1; // true
}

static void clearAllTimers(void) {
    for (size_t i = 0U; i < NUM_TFDS; i++) {
        if (timerfds[i] != -1) {
            close(inputfds[i]);
            timerfds[i] = 1;
        }
    }
}
