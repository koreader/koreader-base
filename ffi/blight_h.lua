-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef struct sd_bus blight_bus;
typedef unsigned char *blight_data_t;
typedef unsigned short blight_surface_id_t;
typedef enum BlightImageFormat BlightImageFormat;
typedef enum BlightWaveformMode BlightWaveformMode;
typedef enum BlightContentType BlightContentType;
typedef enum BlightUpdateMode BlightUpdateMode;
typedef enum BlightMessageType BlightMessageType;
enum BlightImageFormat {
  Format_Invalid,
  Format_Mono,
  Format_MonoLSB,
  Format_Indexed8,
  Format_RGB32,
  Format_ARGB32,
  Format_ARGB32_Premultiplied,
  Format_RGB16,
  Format_ARGB8565_Premultiplied,
  Format_RGB666,
  Format_ARGB6666_Premultiplied,
  Format_RGB555,
  Format_ARGB8555_Premultiplied,
  Format_RGB888,
  Format_RGB444,
  Format_ARGB4444_Premultiplied,
  Format_RGBX8888,
  Format_RGBA8888,
  Format_RGBA8888_Premultiplied,
  Format_BGR30,
  Format_A2BGR30_Premultiplied,
  Format_RGB30,
  Format_A2RGB30_Premultiplied,
  Format_Alpha8,
  Format_Grayscale8,
  Format_RGBX64,
  Format_RGBA64,
  Format_RGBA64_Premultiplied,
  Format_Grayscale16,
  Format_BGR888,
};
enum BlightWaveformMode {
  UltraFast = 0,
  Fast = 1,
  Animate = 2,
  Content = 3,
  UI = 4,
  Full = 5,
};
enum BlightContentType {
  Monochrome = 0,
  Color = 1,
};
enum BlightUpdateMode {
  PartialUpdate = 0x00,
  FullUpdate = 0x01,
  PenUpdate = 0x02,
  AnimationUpdate = 0x04,
  UIUpdate = 0x08,
};
enum BlightMessageType {
  Invalid,
  Ack,
  Ping,
  Repaint,
  Move,
  Info,
  Delete,
  List,
  Raise,
  Lower,
  Wait,
  Focus,
};
typedef struct blight_buf_t blight_buf_t;
typedef struct blight_input_buffer_t blight_input_buffer_t;
typedef struct blight_header_t blight_header_t;
typedef struct blight_message_t blight_message_t;
typedef struct blight_packet_repaint_t blight_packet_repaint_t;
typedef struct blight_packet_move_t blight_packet_move_t;
typedef struct blight_packet_surface_info_t blight_packet_surface_info_t;
struct blight_buf_t {
  int fd;
  int x;
  int y;
  unsigned width;
  unsigned height;
  unsigned stride;
  BlightImageFormat format;
  double scale;
  blight_data_t data;
};
struct blight_input_buffer_t {
  unsigned short device;
  int fd;
  void *ringBuffer;
};
struct blight_header_t {
  BlightMessageType type;
  unsigned ackid;
  uint32_t size;
};
struct blight_message_t {
  blight_header_t header;
  blight_data_t data;
};
struct blight_packet_repaint_t {
  int x;
  int y;
  unsigned width;
  unsigned height;
  BlightWaveformMode waveform;
  BlightContentType contenttype;
  BlightUpdateMode mode;
  unsigned marker;
  blight_surface_id_t identifier;
};
struct blight_packet_move_t {
  blight_surface_id_t identifier;
  int x;
  int y;
};
struct blight_packet_surface_info_t {
  int x;
  int y;
  unsigned width;
  unsigned height;
  int stride;
  BlightImageFormat format;
  double scale;
};
int blight_bus_connect_system(blight_bus **);
int blight_bus_connect_user(blight_bus **);
void blight_bus_deref(blight_bus *);
bool blight_service_available(blight_bus *);
int blight_service_open(blight_bus *);
blight_input_buffer_t *blight_service_input_open(blight_bus *, unsigned short);
int blight_event_from_buffer(blight_input_buffer_t *, struct input_event **, bool);
void blight_event_free(struct input_event *);
void blight_input_buffer_deref(blight_input_buffer_t *);
blight_buf_t *blight_create_buffer(int, int, unsigned, unsigned, unsigned, BlightImageFormat, double);
void blight_buffer_deref(blight_buf_t *);
blight_surface_id_t blight_add_surface(blight_bus *, blight_buf_t *);
unsigned blight_surface_repaint(int, blight_surface_id_t, int, int, unsigned, unsigned, BlightWaveformMode, BlightContentType, BlightUpdateMode);
int blight_remove_surface(int, blight_surface_id_t);
struct blight_thread_t *blight_start_connection_thread(int);
int blight_connection_thread_deref(struct blight_thread_t *);
int blight_move_surface(int, blight_surface_id_t, blight_buf_t *, int, int);
int blight_raise(int, blight_surface_id_t);
int blight_lower(int, blight_surface_id_t);
int blight_focus(int);
]]
