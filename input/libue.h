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

#ifndef __LIBUE_H
#define __LIBUE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/poll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#include <linux/netlink.h>

#define LIBUE_VERSION_MAJOR  "0"
#define LIBUE_VERSION_MINOR  "3.0"
#define LIBUE_VERSION        LIBUE_VERSION_MAJOR "." LIBUE_VERSION_MINOR
#define LIBUE_VERSION_NUMBER 10000

// Enable debug logging in Debug builds
#ifdef DEBUG
#	define UE_DEBUG 1
#else
#	define UE_DEBUG 0
#endif

// We don't log to syslog
#define UE_SYSLOG 0

// Logging helpers
#define UE_LOG(prio, fmt, ...)                                                                                           \
	({                                                                                                               \
		if (UE_SYSLOG) {                                                                                         \
			syslog(prio, fmt, ##__VA_ARGS__);                                                                \
		} else {                                                                                                 \
			fprintf(stderr, fmt "\n", ##__VA_ARGS__);                                                        \
		}                                                                                                        \
	})

// Same, but with __PRETTY_FUNCTION__:__LINE__ right before fmt
#define UE_PFLOG(prio, fmt, ...)                                                                                         \
	({                                                                                                               \
		if ((prio != LOG_DEBUG) || (prio == LOG_DEBUG && UE_DEBUG)) {                                            \
			UE_LOG(prio, "[%s:%d] " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);                      \
		}                                                                                                        \
	})

struct uevent_listener
{
	struct pollfd      pfd;
	struct sockaddr_nl nls;
};

#define ERR_LISTENER_NOT_ROOT     -1
#define ERR_LISTENER_BIND         -2
#define ERR_LISTENER_POLL         -3
#define ERR_LISTENER_RECV         -4
#define ERR_PARSE_UDEV            -1
#define ERR_PARSE_INVALID_HDR     -2
#define UE_STR_EQ(str, const_str) (strncmp((str), (const_str), sizeof(const_str) - 1U) == 0)

enum uevent_action
{
	UEVENT_ACTION_INVALID = 0,
	UEVENT_ACTION_ADD,
	UEVENT_ACTION_REMOVE,
	UEVENT_ACTION_CHANGE,
	UEVENT_ACTION_MOVE,
	UEVENT_ACTION_ONLINE,
	UEVENT_ACTION_OFFLINE,
};

static const char* uev_action_str[] = { "invalid", "add", "remove", "change", "move", "online", "offline" };

struct uevent
{
	enum uevent_action action;
	char*              devpath;
	char               buf[PIPE_BUF];
	size_t             buflen;
};

/*
 * Reference for uevent format:
 * https://www.kernel.org/doc/pending/hotplug.txt
 * https://stackoverflow.com/a/22813783
 */
static int
    ue_parse_event_msg(struct uevent* uevp, size_t buflen)
{
	/* skip udev events */
	if (memcmp(uevp->buf, "libudev", 7) == 0 || memcmp(uevp->buf, "udev", 4) == 0) {
		return ERR_PARSE_UDEV;
	}

	/* validate message header */
	size_t body_start = strlen(uevp->buf) + 1U;
	if (body_start < sizeof("a@/d") || body_start >= buflen || (strstr(uevp->buf, "@/") == NULL)) {
		return ERR_PARSE_INVALID_HDR;
	}

	size_t i = body_start;
	char*  cur_line;
	uevp->buflen = buflen;

	while (i < buflen) {
		cur_line = uevp->buf + i;
		UE_PFLOG(LOG_DEBUG, "line: `%s`", cur_line);
		char* p = cur_line;
		if (UE_STR_EQ(p, "ACTION")) {
			p += sizeof("ACTION");
			if (UE_STR_EQ(p, "add")) {
				uevp->action = UEVENT_ACTION_ADD;
			} else if (UE_STR_EQ(p, "change")) {
				uevp->action = UEVENT_ACTION_CHANGE;
			} else if (UE_STR_EQ(p, "remove")) {
				uevp->action = UEVENT_ACTION_REMOVE;
			} else if (UE_STR_EQ(p, "move")) {
				uevp->action = UEVENT_ACTION_MOVE;
			} else if (UE_STR_EQ(p, "online")) {
				uevp->action = UEVENT_ACTION_ONLINE;
			} else if (UE_STR_EQ(p, "offline")) {
				uevp->action = UEVENT_ACTION_OFFLINE;
			}
		} else if (UE_STR_EQ(p, "DEVPATH")) {
			uevp->devpath = p + sizeof("DEVPATH");
		}
		/* proceed to next line */
		i += strlen(cur_line) + 1U;
	}
	return EXIT_SUCCESS;
}

static inline void
    ue_dump_event(struct uevent* uevp)
{
	printf("%s %s\n", uev_action_str[uevp->action], uevp->devpath);
}

static inline void
    ue_reset_event(struct uevent* uevp)
{
	uevp->action  = UEVENT_ACTION_INVALID;
	uevp->devpath = NULL;
	uevp->buflen  = 0U;
}

static int
    ue_init_listener(struct uevent_listener* l)
{
	memset(&l->nls, 0, sizeof(struct sockaddr_nl));
	l->nls.nl_family = AF_NETLINK;
	// NOTE: It's actually a pid_t in non-braindead kernels...
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-conversion"
	l->nls.nl_pid = getpid();
#pragma GCC diagnostic pop
	l->nls.nl_groups = -1U;

	l->pfd.events = POLLIN;
	l->pfd.fd     = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
	if (l->pfd.fd == -1) {
		UE_PFLOG(LOG_CRIT, "socket: %m");
		return ERR_LISTENER_NOT_ROOT;
	}

	if (bind(l->pfd.fd, (struct sockaddr*) &(l->nls), sizeof(struct sockaddr_nl))) {
		UE_PFLOG(LOG_CRIT, "bind: %m");
		return ERR_LISTENER_BIND;
	}

	return EXIT_SUCCESS;
}

static int
    ue_wait_for_event(struct uevent_listener* l, struct uevent* uevp)
{
	while (poll(&(l->pfd), 1, -1) != -1) {
		ue_reset_event(uevp);
		ssize_t len = recv(l->pfd.fd, uevp->buf, sizeof(uevp->buf), MSG_DONTWAIT);
		if (len == -1) {
			UE_PFLOG(LOG_CRIT, "recv: %m");
			return ERR_LISTENER_RECV;
		}
		int rc = ue_parse_event_msg(uevp, (size_t) len);
		if (rc == EXIT_SUCCESS) {
			UE_PFLOG(LOG_DEBUG, "uevent successfully parsed");
			return EXIT_SUCCESS;
		} else if (rc == ERR_PARSE_UDEV) {
			UE_PFLOG(LOG_DEBUG, "skipped udev uevent: `%s`", uevp->buf);
		} else if (rc == ERR_PARSE_INVALID_HDR) {
			UE_PFLOG(LOG_DEBUG, "skipped malformed uevent: `%s`", uevp->buf);
		} else {
			UE_PFLOG(LOG_DEBUG, "skipped unsupported uevent: `%s`", uevp->buf);
		}
	}
	UE_PFLOG(LOG_CRIT, "poll: %m");
	return ERR_LISTENER_POLL;
}

static int
    ue_destroy_listener(struct uevent_listener* l)
{
	if (l->pfd.fd != -1) {
		return close(l->pfd.fd);
	} else {
		return EXIT_SUCCESS;
	}
}

#endif    // __LIBUE_H
