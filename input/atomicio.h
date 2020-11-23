/* $OpenBSD: atomicio.c,v 1.30 2019/01/24 02:42:23 dtucker Exp $ */
/*
 * Copyright (c) 2006 Damien Miller. All rights reserved.
 * Copyright (c) 2005 Anil Madhavapeddy. All rights reserved.
 * Copyright (c) 1995,1999 Theo de Raadt.  All rights reserved.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// NOTE: Originally imported from https://github.com/openssh/openssh-portable/blob/master/atomicio.c
//       Rejigged for my own use, with inspiration from git's own read/write wrappers,
//       as well as gnulib's and busybox's
//       c.f., https://github.com/git/git/blob/master/wrapper.c
//             https://git.savannah.gnu.org/cgit/gnulib.git/tree/lib/safe-read.c
//             https://git.savannah.gnu.org/cgit/gnulib.git/tree/lib/full-write.c
//             https://git.busybox.net/busybox/tree/libbb/read.c


#ifndef _ATOMICIO_H
#define _ATOMICIO_H

#include <errno.h>
#include <limits.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

// Clamp IO chunks to the smallest of 8 MiB and SSIZE_MAX,
// to deal with various implementation quirks on really old Linux,
// macOS, or AIX/IRIX.
// c.f., git, gnulib & busybox for similar stories.
// Since we ourselves are 32 bit Linux-bound, 8 MiB suits us just fine.
#define MAX_IO_BUFSIZ (8 * 1024 * 1024)
#if defined(SSIZE_MAX) && (SSIZE_MAX < MAX_IO_BUFSIZ)
#	undef MAX_IO_BUFSIZ
#	define MAX_IO_BUFSIZ SSIZE_MAX
#endif

// read() with retries on recoverable errors (via polling on EAGAIN).
// Not guaranteed to return len bytes, even on success (like read() itself).
// Always returns read()'s return value as-is.
static ssize_t
    xread(int fd, void* buf, size_t len)
{
	// Save a trip to EINVAL if len is large enough to make read() fail.
	if (len > MAX_IO_BUFSIZ) {
		len = MAX_IO_BUFSIZ;
	}

	while (1) {
		// Flawfinder: ignore
		ssize_t nr = read(fd, buf, len);
		if (nr < 0) {
			if (errno == EINTR) {
				continue;
			} else if (errno == EAGAIN) {
				struct pollfd pfd = { 0 };
				pfd.fd            = fd;
				pfd.events        = POLLIN;

				poll(&pfd, 1, -1);
				continue;
			}
		}
		return nr;
	}
}

#endif /* _ATOMICIO_H */
