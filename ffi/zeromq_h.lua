local ffi = require("ffi")
ffi.cdef[[
typedef struct _zmsg_t zmsg_t;
typedef struct _zhash_t zhash_t;
typedef struct _zframe_t zframe_t;

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
zmsg_t * zyre_recv_nowait (zyre_t *self);
int zyre_whisper (zyre_t *self, const char *peer, zmsg_t **msg_p);
int zyre_shout (zyre_t *self, const char *group, zmsg_t **msg_p);
int zyre_whispers (zyre_t *self, const char *peer, const char *format, ...);
int zyre_shouts (zyre_t *self, const char *group, const char *format, ...);
void zyre_dump (zyre_t *self);
zyre_event_t * zyre_event_new (zyre_t *self);
void zyre_event_destroy (zyre_event_t **self_p);
zyre_event_type_t zyre_event_type (zyre_event_t *self);
char * zyre_event_sender (zyre_event_t *self);
char * zyre_event_name (zyre_event_t *self);
char * zyre_event_address (zyre_event_t *self);
char * zyre_event_header (zyre_event_t *self, char *name);
char * zyre_event_group (zyre_event_t *self);

size_t zmsg_size (zmsg_t *self);
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

typedef struct _fmq_server_t fmq_server_t;
typedef struct _fmq_client_t fmq_client_t;

fmq_server_t * fmq_server_new ();
void fmq_server_destroy (fmq_server_t **self_p);
void fmq_server_configure (fmq_server_t *self, const char *config_file);
void fmq_server_setoption (fmq_server_t *self, const char *path, const char *value);
int fmq_server_bind (fmq_server_t *self, const char *endpoint);
zmsg_t * fmq_server_recv (fmq_server_t *self);
zmsg_t * fmq_server_recv_nowait (fmq_server_t *self);
void fmq_server_publish (fmq_server_t *self, const char *location, const char *alias);
void fmq_server_set_anonymous (fmq_server_t *self, long enabled);

fmq_client_t * fmq_client_new ();
void fmq_client_destroy (fmq_client_t **self_p);
void fmq_client_configure (fmq_client_t *self, const char *config_file);
void fmq_client_setoption (fmq_client_t *self, const char *path, const char *value);
void fmq_client_connect (fmq_client_t *self, const char *endpoint);
zmsg_t * fmq_client_recv (fmq_client_t *self);
zmsg_t * fmq_client_recv_nowait (fmq_client_t *self);
void * fmq_client_handle (fmq_client_t *self);
void fmq_client_subscribe (fmq_client_t *self, const char *path);
void fmq_client_set_inbox (fmq_client_t *self, const char *path);
void fmq_client_set_resync (fmq_client_t *self, long enabled);
]]
