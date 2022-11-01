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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/poll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <syslog.h>
#include <unistd.h>

#include <linux/limits.h>
#include <linux/netlink.h>

// c.f., https://github.com/NiLuJe/kfmon/tree/master/openssh
#include "atomicio.h"

#define LIBUE_VERSION_MAJOR "1"
#define LIBUE_VERSION_MINOR "4"
#define LIBUE_VERSION_PATCH "0"
#define LIBUE_VERSION       LIBUE_VERSION_MAJOR "." LIBUE_VERSION_MINOR "." LIBUE_VERSION_PATCH
// Much like SQLite, this is (MAJOR*1000000 + MINOR*1000 + PATCH)
#define LIBUE_VERSION_NUMBER 1004000

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
// NOTE: This is a *prefix* match, str just needs to *begin* with const_str for it to match!
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
	char*              subsystem;
	char*              modalias;
	char*              devname;
	char   buf[PIPE_BUF];    // i.e., 4*1024, which is between busybox's mdev (3kB, stack) and uevent (16kB, mmap).
	size_t buflen;
};

/*
 * Reference for uevent format:
 * https://www.kernel.org/doc/pending/hotplug.txt
 * https://stackoverflow.com/a/22813783
 */
static int
    ue_parse_event_msg(struct uevent* uevp, size_t buflen)
{
	/* skip udev events, which we should not receive in the first place */
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
		} else if (UE_STR_EQ(p, "SUBSYSTEM")) {
			uevp->subsystem = p + sizeof("SUBSYSTEM");
		} else if (UE_STR_EQ(p, "MODALIAS")) {
			uevp->modalias = p + sizeof("MODALIAS");
		} else if (UE_STR_EQ(p, "DEVNAME")) {
			uevp->devname = p + sizeof("DEVNAME");
		}
		/* proceed to next line */
		i += strlen(cur_line) + 1U;
	}
	return EXIT_SUCCESS;
}

static inline void
    ue_dump_event(struct uevent* uevp)
{
	UE_LOG(LOG_INFO, "%s %s", uev_action_str[uevp->action], uevp->devpath);
}

static inline void
    ue_reset_event(struct uevent* uevp)
{
	uevp->action    = UEVENT_ACTION_INVALID;
	uevp->devpath   = NULL;
	uevp->subsystem = NULL;
	uevp->modalias  = NULL;
	uevp->devname   = NULL;
	uevp->buflen    = 0U;
}

/*
 * c.f., https://git.busybox.net/busybox/tree/util-linux/uevent.c
 */
static int
    ue_init_listener(struct uevent_listener* l)
{
	memset(&l->nls, 0, sizeof(l->nls));
	l->nls.nl_family = AF_NETLINK;
	// NOTE: It's actually a pid_t in non-braindead kernels...
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-conversion"
	l->nls.nl_pid = getpid();
#pragma GCC diagnostic pop
	// We only care about kernel events
	// (c.f., https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/lib/kobject_uevent.c
	// & https://github.com/gentoo/eudev/blob/9aadd2bfd66333318461c97cc7744ccdb84c24b5/src/libudev/libudev-monitor.c#L65-L69
	// & https://git.busybox.net/busybox/tree/util-linux/uevent.c)
	l->nls.nl_groups = 1U << 0U;

	l->pfd.events = POLLIN;
	l->pfd.fd     = socket(PF_NETLINK, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
	if (l->pfd.fd == -1) {
		UE_PFLOG(LOG_CRIT, "socket: %m");
		return ERR_LISTENER_NOT_ROOT;
	}

	// See udev & busybox for the reasoning behind the insanely large value used here
	// (default is from /proc/sys/net/core/rmem_default)
	// That's thankfully lazily allocated by the kernel, so we don't really waste anything.
	int recvbuf_size = 128 * 1024 * 1024;
	setsockopt(l->pfd.fd, SOL_SOCKET, SO_RCVBUFFORCE, &recvbuf_size, sizeof(recvbuf_size));

	if (bind(l->pfd.fd, (const struct sockaddr*) &(l->nls), sizeof(l->nls))) {
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
		ssize_t len = xread(l->pfd.fd, uevp->buf, sizeof(uevp->buf) - 1U);
		if (len == -1) {
			if (errno == ENOBUFS) {
				// NOTE: Events will be lost! But our only recourse is to restart from scratch.
				UE_PFLOG(LOG_WARNING, "uevent overrun!");
				close(l->pfd.fd);
				int rc = ue_init_listener(l);
				if (rc < 0) {
					UE_PFLOG(LOG_CRIT, "Failed to reinitialize libue listener (%d)", rc);
					return rc;
				}
				return ue_wait_for_event(l, uevp);
			}
			UE_PFLOG(LOG_CRIT, "read: %m");
			return ERR_LISTENER_RECV;
		}
		char* end = uevp->buf + len;
		*end      = '\0';

		int rc = ue_parse_event_msg(uevp, (size_t) len);
		if (rc == EXIT_SUCCESS) {
			UE_PFLOG(LOG_DEBUG, "uevent successfully parsed");
			return EXIT_SUCCESS;
		} else if (rc == ERR_PARSE_UDEV) {
			UE_PFLOG(LOG_DEBUG, "skipped %zd bytes udev uevent: `%.*s`", len, (int) len, uevp->buf);
		} else if (rc == ERR_PARSE_INVALID_HDR) {
			UE_PFLOG(LOG_DEBUG, "skipped %zd bytes malformed uevent: `%.*s`", len, (int) len, uevp->buf);
		} else {
			UE_PFLOG(LOG_DEBUG, "skipped %zd bytes unsupported uevent: `%.*s`", len, (int) len, uevp->buf);
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
