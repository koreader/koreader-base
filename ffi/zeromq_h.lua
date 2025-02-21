-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
typedef struct _zmsg_t zmsg_t;
typedef struct _zhash_t zhash_t;
typedef struct _zsock_t zsock_t;
typedef struct _zframe_t zframe_t;
typedef struct _zpoller_t zpoller_t;
static const int ZFRAME_MORE = 1;
static const int ZFRAME_REUSE = 2;
static const int ZMQ_IDENTITY = 5;
static const int ZMQ_STREAM = 11;
int zmq_getsockopt(void *, int, void *, size_t *);
int zmq_send(void *, const void *, size_t, int);
int zsock_bind(zsock_t *, const char *, ...);
int zsock_connect(zsock_t *, const char *, ...);
void zsock_destroy(zsock_t **);
zsock_t *zsock_new(int);
void *zsock_resolve(void *);
unsigned char *zframe_data(zframe_t *);
void zframe_destroy(zframe_t **);
zframe_t *zframe_recv(void *);
int zframe_send(zframe_t **, void *, int);
size_t zframe_size(zframe_t *);
int zmsg_addmem(zmsg_t *, const void *, size_t);
void zmsg_destroy(zmsg_t **);
zmsg_t *zmsg_new(void);
zframe_t *zmsg_pop(zmsg_t *);
char *zmsg_popstr(zmsg_t *);
int zmsg_send(zmsg_t **, void *);
size_t zmsg_size(zmsg_t *);
void zstr_free(char **);
int zstr_send(void *, const char *);
const char *zhash_cursor(zhash_t *);
void zhash_destroy(zhash_t **);
zhash_t *zhash_unpack(zframe_t *);
void zpoller_destroy(zpoller_t **);
zpoller_t *zpoller_new(void *, ...);
void *zpoller_wait(zpoller_t *, int);
]]
