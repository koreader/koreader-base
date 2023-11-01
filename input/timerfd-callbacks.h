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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/timerfd.h>

// So that the main input code knows it's built w/ timerfd support
#define WITH_TIMERFD 1

// Unlike the main input module, the way in which we open/close timerfds is much more dynamic.
// As such, we're using a doubly linked list to keep track of it.

// A node in the doubly linked list
typedef struct timerfd_node
{
    int                  fd;
    struct timerfd_node* next;
    struct timerfd_node* prev;
} timerfd_node_t;

// A control structure to keep track of a doubly linked list
typedef struct
{
    size_t          count;
    timerfd_node_t* head;
    timerfd_node_t* tail;
} timerfd_list_t;

// Free all resources allocated by a list and its nodes
static inline void timerfd_list_teardown(timerfd_list_t* list)
{
    timerfd_node_t* restrict node = list->head;
    while (node) {
        timerfd_node_t* restrict p = node->next;
        close(node->fd);
        free(node);
        node = p;
    }
    // Don't leave dangling pointers
    list->head = NULL;
    list->tail = NULL;
}

// Allocate and return a single new node at the tail of the list
static inline timerfd_node_t* timerfd_list_grow(timerfd_list_t* list)
{
    timerfd_node_t* restrict prev = list->tail;
    timerfd_node_t* restrict node = calloc(1, sizeof(*node));
    if (!node) {
        return NULL;
    }
    list->count++;

    // Update the head if this is the first node
    if (!list->head) {
        list->head = node;
    }
    // Update the tail pointer
    list->tail = node;
    // If there was a previous node, link the two together
    if (prev) {
        prev->next = node;
        node->prev = prev;
    }

    return node;
}

// Delete the given node from the list and free the resources associated with it.
// With a little help from https://en.wikipedia.org/wiki/Doubly_linked_list ;).
static inline void timerfd_list_delete_node(timerfd_list_t* list, timerfd_node_t* node)
{
    timerfd_node_t* restrict prev = node->prev;
    timerfd_node_t* restrict next = node->next;

    if (!prev) {
        // We were the head
        list->head = next;
    } else {
        prev->next = next;
    }
    if (!next) {
        // We were the tail
        list->tail = prev;
    } else {
        next->prev = prev;
    }

    // Free this node and its resources.
    close(node->fd);
    free(node);
    list->count--;
}

// Now that we're done with boring list stuff, what's left is actual timerfd handling ;).
timerfd_list_t timerfds = { 0 };

// clockid_t clock, time_t deadline_sec, suseconds_t deadline_usec
static int setTimer(lua_State* L)
{
    clockid_t   clock         = luaL_checkint(L, 1);
    time_t      deadline_sec  = luaL_checkinteger(L, 2);
    suseconds_t deadline_usec = luaL_checkinteger(L, 3);
    lua_settop(L, 0);  // Pop function args

    // Unlike in input.c, we know we're running a kernel recent enough to support the flags
    int fd = timerfd_create(clock, TFD_NONBLOCK | TFD_CLOEXEC);
    if (fd == -1) {
        fprintf(stderr, "timerfd_create: %m\n");
        return 0;
    }

    // Arm the timer for the specified *absolute* deadline
    struct itimerspec clock_timer;
    clock_timer.it_value.tv_sec = deadline_sec;
    // TIMEVAL_TO_TIMESPEC
    clock_timer.it_value.tv_nsec = deadline_usec * 1000;
    // We only need a single-shot timer
    clock_timer.it_interval.tv_sec  = 0;
    clock_timer.it_interval.tv_nsec = 0;

    if (timerfd_settime(fd, TFD_TIMER_ABSTIME, &clock_timer, NULL) == -1) {
        fprintf(stderr, "timerfd_settime: %m\n");
        // Cleanup
        close(fd);
        return 0;
    }

    // Now we can store that in a new node in our list
    timerfd_node_t* restrict node = timerfd_list_grow(&timerfds);
    if (!node) {
        fprintf(stderr, "Failed to allocate a new node in the timerfd list\n");
        // Cleanup
        close(fd);
        return 0;
    }
    node->fd = fd;

    // Need to update select's nfds, too...
    if (fd >= nfds) {
        nfds = fd + 1;
    }

    // Success!
    lua_pushlightuserdata(L, (void*) node);
    return 1;  // node
}

// timerfd_node_t* expired_node
static int clearTimer(lua_State* L)
{
    timerfd_node_t* restrict expired_node = (timerfd_node_t * restrict) lua_touserdata(L, 1);
    lua_settop(L, 0);  // Pop function arg

    timerfd_list_delete_node(&timerfds, expired_node);

    // Re-compute nfds...
    // NOTE: Assumes that we've got at least one fd open, which should always hold true.
    // NOTE: Also assumes that the top fd in the array is the one with the highest fd number, which openInputDevice makes sure of.
    nfds = inputfds[fd_idx - 1U] + 1;
    for (timerfd_node_t* restrict node = timerfds.head; node != NULL; node = node->next) {
        if (node->fd >= nfds) {
            nfds = node->fd + 1;
        }
    }

    // Success!
    lua_pushboolean(L, true);
    return 1;  // true
}

static void clearAllTimers(void)
{
    timerfd_list_teardown(&timerfds);
}
