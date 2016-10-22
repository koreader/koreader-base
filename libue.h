/*
    The MIT License (MIT)

    Copyright (c) <2016> <Qingping Hou>

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

#ifndef _LIBUE_H
#define _LIBUE_H

#include <sys/poll.h>
#include <sys/socket.h>
#include <string.h>
#include <linux/netlink.h>
#include <stdio.h>

#define LIBUE_VERSION_MAJOR "0"
#define LIBUE_VERSION_MINOR "1.0"
#define LIBUE_VERSION LIBUE_VERSION_MAJOR "." LIBUE_VERSION_MINOR
#define LIBUE_VERSION_NUMBER 10000
#ifndef DEBUG
    #define DEBUG 0
#endif
#define UE_DEBUG(...) \
            do { if (DEBUG) fprintf(stderr, __VA_ARGS__); } while(0)

struct uevent_listener {
    struct pollfd pfd;
    struct sockaddr_nl nls;
};

#define ERR_LISTENER_NOT_ROOT -1
#define ERR_LISTENER_BIND -2
#define ERR_LISTENER_POLL -3
#define ERR_LISTENER_RECV -4
#define ERR_PARSE_UDEV -1
#define ERR_PARSE_INVALID_HDR -2
#define UE_STR_EQ(str, const_str) (strncmp((str), (const_str), sizeof(const_str)-1) == 0)

enum uevent_action {
    UEVENT_ACTION_INVALID = 0,
    UEVENT_ACTION_ADD,
    UEVENT_ACTION_REMOVE,
    UEVENT_ACTION_CHANGE,
    UEVENT_ACTION_MOVE,
    UEVENT_ACTION_ONLINE,
    UEVENT_ACTION_OFFLINE,
};

struct uevent {
    enum uevent_action action;
    char *devpath;
    char buf[4096];
    size_t buflen;
};

const char* uev_action_str[] = { "invalid", "add", "remove", "change", "move", "online", "offline" };

/*
 * Reference for uevent format:
 * https://www.kernel.org/doc/pending/hotplug.txt
 */
int ue_parse_event_msg(struct uevent *uevp, size_t buflen) {
    /* skip udev events */
    if (memcmp(uevp->buf, "libudev", 8) == 0) return ERR_PARSE_UDEV;

    /* validate message header */
    int body_start = strlen(uevp->buf) + 1;
    if ((size_t)body_start < sizeof("a@/d")
            || body_start >= buflen
            || (strstr(uevp->buf, "@/") == NULL)) {
        return ERR_PARSE_INVALID_HDR;
    }

    int i = body_start;
    char *cur_line;
    uevp->buflen = buflen;

    while (i < buflen) {
        cur_line = uevp->buf + i;
        UE_DEBUG("line: '%s'\n", cur_line);
        if (UE_STR_EQ(cur_line, "ACTION")) {
            cur_line += sizeof("ACTION");
            if (UE_STR_EQ(cur_line, "add")) {
                uevp->action = UEVENT_ACTION_ADD;
            } else if (UE_STR_EQ(cur_line, "change")) {
                uevp->action = UEVENT_ACTION_CHANGE;
            } else if (UE_STR_EQ(cur_line, "remove")) {
                uevp->action = UEVENT_ACTION_REMOVE;
            } else if (UE_STR_EQ(cur_line, "move")) {
                uevp->action = UEVENT_ACTION_MOVE;
            } else if (UE_STR_EQ(cur_line, "online")) {
                uevp->action = UEVENT_ACTION_ONLINE;
            } else if (UE_STR_EQ(cur_line, "offline")) {
                uevp->action = UEVENT_ACTION_OFFLINE;
            }
        } else if (UE_STR_EQ(cur_line, "DEVPATH")) {
            uevp->devpath = cur_line + sizeof("DEVPATH");
        }
        /* proceed to next line */
        i += strlen(cur_line) + 1;
    }
    return 0;
}

inline void ue_dump_event(struct uevent *uevp) {
    printf("%s %s\n", uev_action_str[uevp->action], uevp->devpath);
}

inline void ue_reset_event(struct uevent *uevp) {
    uevp->action = UEVENT_ACTION_INVALID;
    uevp->buflen = 0;
    uevp->devpath = NULL;
}

int ue_init_listener(struct uevent_listener *l) {
    memset(&l->nls, 0, sizeof(struct sockaddr_nl));
    l->nls.nl_family = AF_NETLINK;
    l->nls.nl_pid = getpid();
    l->nls.nl_groups = -1;

    l->pfd.events = POLLIN;
    l->pfd.fd = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
    if (l->pfd.fd == -1) return ERR_LISTENER_NOT_ROOT;

    if (bind(l->pfd.fd, (void *)&(l->nls), sizeof(struct sockaddr_nl))) {
        return ERR_LISTENER_BIND;
    }

    return 0;
}

int ue_wait_for_event(struct uevent_listener *l, struct uevent *uevp) {
    ue_reset_event(uevp);
    while (poll(&(l->pfd), 1, -1) != -1) {
        int i, len = recv(l->pfd.fd, uevp->buf, sizeof(uevp->buf), MSG_DONTWAIT);
        if (len == -1) return ERR_LISTENER_RECV;
        if (ue_parse_event_msg(uevp, len) == 0) {
            UE_DEBUG("uevent successfully parsed\n");
            return 0;
        } else {
            UE_DEBUG("skipped unsupported uevent:\n%s\n", uevp->buf);
        }
    }
    return ERR_LISTENER_POLL;
}

#endif
