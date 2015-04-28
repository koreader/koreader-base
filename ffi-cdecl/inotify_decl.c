#include <sys/inotify.h>

#include "ffi-cdecl.h"

cdecl_const(IN_ACCESS)
cdecl_const(IN_ATTRIB)
cdecl_const(IN_CLOSE_WRITE)
cdecl_const(IN_CLOSE_NOWRITE)
cdecl_const(IN_CREATE)
cdecl_const(IN_DELETE)
cdecl_const(IN_DELETE_SELF)
cdecl_const(IN_MODIFY)
cdecl_const(IN_MOVE_SELF)
cdecl_const(IN_MOVED_FROM)
cdecl_const(IN_MOVED_TO)
cdecl_const(IN_OPEN)

/* convenience macros */
cdecl_const(IN_ALL_EVENTS)
cdecl_const(IN_MOVE)
cdecl_const(IN_CLOSE)

/* bits for mask of inotify_add_watch() */
cdecl_const(IN_DONT_FOLLOW) /* from 2.6.15 */
cdecl_const(IN_EXCL_UNLINK) /* from 2.6.36 */
cdecl_const(IN_MASK_ADD)
cdecl_const(IN_ONESHOT)
cdecl_const(IN_ONLYDIR)     /* from 2.6.15 */

/* may be set for events read() */
cdecl_const(IN_IGNORED)
cdecl_const(IN_ISDIR)
cdecl_const(IN_Q_OVERFLOW)
cdecl_const(IN_UNMOUNT)

/* flags for inotify_init1() */
cdecl_const(IN_NONBLOCK)
cdecl_const(IN_CLOEXEC)

cdecl_func(inotify_init)
cdecl_func(inotify_init1)   /* from 2.6.27 */
cdecl_func(inotify_add_watch)
cdecl_func(inotify_rm_watch)

cdecl_struct(inotify_event)
