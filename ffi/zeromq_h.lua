-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef unsigned char byte;
typedef struct _zmsg_t zmsg_t;
typedef struct _zhash_t zhash_t;
typedef struct _zsock_t zsock_t;
typedef struct _zframe_t zframe_t;
typedef struct _zpoller_t zpoller_t;
static const unsigned ZFRAME_MORE = 1;
static const unsigned ZFRAME_REUSE = 2;
static const unsigned ZMQ_IDENTITY = 5;
static const unsigned ZMQ_STREAM = 11;
int zmq_getsockopt(void *s_, int option_, void *optval_, size_t *optvallen_);
int zmq_send(void *s_, const void *buf_, size_t len_, int flags_);
int zsock_bind(zsock_t *self, const char *format, ...);
int zsock_connect(zsock_t *self, const char *format, ...);
void zsock_destroy(zsock_t **self_p);
zsock_t *zsock_new(int type);
void *zsock_resolve(void *self);
byte *zframe_data(zframe_t *self);
void zframe_destroy(zframe_t **self_p);
zframe_t *zframe_recv(void *source);
int zframe_send(zframe_t **self_p, void *dest, int flags);
size_t zframe_size(zframe_t *self);
int zmsg_addmem(zmsg_t *self, const void *data, size_t size);
void zmsg_destroy(zmsg_t **self_p);
zmsg_t *zmsg_new(void);
zframe_t *zmsg_pop(zmsg_t *self);
char *zmsg_popstr(zmsg_t *self);
int zmsg_send(zmsg_t **self_p, void *dest);
size_t zmsg_size(zmsg_t *self);
void zstr_free(char **string_p);
int zstr_send(void *dest, const char *string);
const char *zhash_cursor(zhash_t *self);
void zhash_destroy(zhash_t **self_p);
zhash_t *zhash_unpack(zframe_t *frame);
void zpoller_destroy(zpoller_t **self_p);
zpoller_t *zpoller_new(void *reader, ...);
void *zpoller_wait(zpoller_t *self, int timeout);
]]
