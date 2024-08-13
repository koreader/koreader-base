// CPPFLAGS="-I/var/tmp/niluje/libzmq/include -I/var/tmp/niluje/czmq/include"
#include <zmq.h>
#include <czmq.h>

#include "ffi-cdecl.h"

cdecl_type(zmsg_t)
cdecl_type(zhash_t)
cdecl_type(zsock_t)
cdecl_type(zframe_t)
cdecl_type(zpoller_t)

cdecl_const(ZFRAME_MORE)
cdecl_const(ZFRAME_REUSE)
cdecl_const(ZMQ_IDENTITY)
cdecl_const(ZMQ_STREAM)

cdecl_func(zmq_getsockopt)
cdecl_func(zmq_send)

cdecl_func(zsock_bind)
cdecl_func(zsock_connect)
cdecl_func(zsock_destroy)
cdecl_func(zsock_new)
cdecl_func(zsock_resolve)

cdecl_func(zframe_data)
cdecl_func(zframe_destroy)
cdecl_func(zframe_recv)
cdecl_func(zframe_send)
cdecl_func(zframe_size)

cdecl_func(zmsg_addmem)
cdecl_func(zmsg_destroy)
cdecl_func(zmsg_new)
cdecl_func(zmsg_pop)
cdecl_func(zmsg_popstr)
cdecl_func(zmsg_send)
cdecl_func(zmsg_size)

cdecl_func(zstr_free)
cdecl_func(zstr_send)

cdecl_func(zhash_cursor)
cdecl_func(zhash_destroy)
cdecl_func(zhash_unpack)

cdecl_func(zpoller_destroy)
cdecl_func(zpoller_new)
cdecl_func(zpoller_wait)
