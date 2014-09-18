local ffi = require("ffi")
ffi.cdef[[
typedef struct _zctx_t zctx_t;
typedef struct _zmsg_t zmsg_t;
typedef struct _zhash_t zhash_t;
typedef struct _zsock_t zsock_t;
typedef struct _zframe_t zframe_t;
typedef struct _zpoller_t zpoller_t;
typedef struct _zsocket_t zsocket_t;

typedef struct _zyre_t zyre_t;
typedef struct _zre_msg_t zre_msg_t;
typedef struct _zyre_event_t zyre_event_t;

typedef enum {
    ZYRE_EVENT_ENTER = 1,
    ZYRE_EVENT_JOIN = 2,
    ZYRE_EVENT_LEAVE = 3,
    ZYRE_EVENT_EXIT = 4,
    ZYRE_EVENT_WHISPER = 5,
    ZYRE_EVENT_SHOUT = 6
} zyre_event_type_t;

typedef enum {
    ZMQ_PAIR = 0,
    ZMQ_PUB = 1,
    ZMQ_SUB = 2,
    ZMQ_REQ = 3,
    ZMQ_REP = 4,
    ZMQ_DEALER = 5,
    ZMQ_ROUTER = 6,
    ZMQ_PULL = 7,
    ZMQ_PUSH = 8,
    ZMQ_XPUB = 9,
    ZMQ_XSUB = 10,
    ZMQ_STREAM = 11,
} zmq_socket_type_t;

typedef enum {
    ZMQ_AFFINITY = 4,
    ZMQ_IDENTITY = 5,
    ZMQ_SUBSCRIBE = 6,
    ZMQ_UNSUBSCRIBE = 7,
} zmq_socket_option_t;

zyre_t * zyre_new ();
void zyre_destroy (zyre_t **self_p);
const char * zyre_uuid (zyre_t *self);
const char * zyre_name (zyre_t *self);
void zyre_set_name (zyre_t *self, const char *name);
void zyre_set_header (zyre_t *self, const char *name, const char *format, ...);
void zyre_set_verbose (zyre_t *self);
void zyre_set_port (zyre_t *self, int port_nbr);
void zyre_set_interval (zyre_t *self, size_t interval);
void zyre_set_interface (zyre_t *self, const char *value);
int zyre_start (zyre_t *self);
void zyre_stop (zyre_t *self);
int zyre_join (zyre_t *self, const char *group);
int zyre_leave (zyre_t *self, const char *group);
zmsg_t * zyre_recv (zyre_t *self);
int zyre_whisper (zyre_t *self, const char *peer, zmsg_t **msg_p);
int zyre_shout (zyre_t *self, const char *group, zmsg_t **msg_p);
int zyre_whispers (zyre_t *self, const char *peer, const char *format, ...);
int zyre_shouts (zyre_t *self, const char *group, const char *format, ...);
zsock_t * zyre_socket (zyre_t *self);
void zyre_dump (zyre_t *self);
zyre_event_t * zyre_event_new (zyre_t *self);
void zyre_event_destroy (zyre_event_t **self_p);
zyre_event_type_t zyre_event_type (zyre_event_t *self);
char * zyre_event_sender (zyre_event_t *self);
char * zyre_event_name (zyre_event_t *self);
char * zyre_event_address (zyre_event_t *self);
char * zyre_event_header (zyre_event_t *self, char *name);
char * zyre_event_group (zyre_event_t *self);

int zmq_getsockopt (void *socket, int option_name, void *option_value, size_t *option_len);

zctx_t * zctx_new ();
void zctx_destroy (zctx_t **self_p);
void * zsocket_new (zctx_t *self, int type);
int zsocket_connect (void *self, const char *format, ...);
void zsocket_set_identity (void *zocket, const char * identity);
char * zsocket_identity (void *zocket);
void zsocket_destroy (zctx_t *ctx, void *self);
zframe_t * zframe_recv (void *source);
size_t zframe_size (zframe_t *self);
unsigned char * zframe_data (zframe_t *self);

zmsg_t * zmsg_new (void);
size_t zmsg_size (zmsg_t *self);
int zmsg_addmem (zmsg_t *self, const void *src, size_t size);
int zmsg_send (zmsg_t **self_p, void *dest);
char * zmsg_popstr (zmsg_t *self);
void zstr_free (char **string_p);
zframe_t * zmsg_pop (zmsg_t *self);
zhash_t * zhash_unpack (zframe_t *frame);
void * zhash_first (zhash_t *self);
void * zhash_next (zhash_t *self);
char * zhash_cursor (zhash_t *self);
void * zhash_lookup (zhash_t *self, const char *key);
void zmsg_destroy (zmsg_t **self_p);
void zhash_destroy (zhash_t **self_p);
void zframe_destroy (zframe_t **self_p);

zpoller_t * zpoller_new (void *reader, ...);
void zpoller_destroy (zpoller_t **self_p);
int zpoller_add (zpoller_t *self, void *reader);
void * zpoller_wait (zpoller_t *self, int timeout);
bool zpoller_expired (zpoller_t *self);
bool zpoller_terminated (zpoller_t *self);

typedef struct _fmq_server_t fmq_server_t;
typedef struct _fmq_client_t fmq_client_t;

fmq_server_t * fmq_server_new ();
void fmq_server_destroy (fmq_server_t **self_p);
void fmq_server_configure (fmq_server_t *self, const char *config_file);
void fmq_server_setoption (fmq_server_t *self, const char *path, const char *value);
int fmq_server_bind (fmq_server_t *self, const char *endpoint);
zmsg_t * fmq_server_recv (fmq_server_t *self);
void fmq_server_publish (fmq_server_t *self, const char *location, const char *alias);
void fmq_server_set_anonymous (fmq_server_t *self, long enabled);

fmq_client_t * fmq_client_new ();
void fmq_client_destroy (fmq_client_t **self_p);
void fmq_client_configure (fmq_client_t *self, const char *config_file);
void fmq_client_setoption (fmq_client_t *self, const char *path, const char *value);
void fmq_client_connect (fmq_client_t *self, const char *endpoint);
zmsg_t * fmq_client_recv (fmq_client_t *self);
void * fmq_client_handle (fmq_client_t *self);
void fmq_client_subscribe (fmq_client_t *self, const char *path);
void fmq_client_set_inbox (fmq_client_t *self, const char *path);
void fmq_client_set_resync (fmq_client_t *self, long enabled);
]]
