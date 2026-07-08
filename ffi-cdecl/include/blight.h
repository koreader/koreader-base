/* 
 * Adapted from https://github.com/Eeems/oxide/blob/master/shared/libblight_protocol/libblight_protocol.h
 */
#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <linux/input.h>

struct sd_bus;
typedef struct sd_bus blight_bus;

struct blight_thread_t;

typedef enum BlightImageFormat {
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
} BlightImageFormat;

typedef enum BlightWaveformMode {
    UltraFast = 0,
    Fast = 1,
    Animate = 2,
    Content = 3,
    UI = 4,
    Full = 5,
} BlightWaveformMode;

typedef enum BlightContentType {
    Monochrome = 0,
    Color = 1,
} BlightContentType;

typedef enum BlightUpdateMode {
    PartialUpdate = 0x00,
    FullUpdate = 0x01,
    PenUpdate = 0x02,
    AnimationUpdate = 0x04,
    UIUpdate = 0x08,
} BlightUpdateMode;

typedef enum BlightMessageType {
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
} BlightMessageType;

typedef unsigned char* blight_data_t;
typedef unsigned short blight_surface_id_t;

typedef struct blight_buf_t {
    int fd;
    int x;
    int y;
    unsigned int width;
    unsigned int height;
    unsigned int stride;
    BlightImageFormat format;
    double scale;
    blight_data_t data;
} blight_buf_t;

typedef struct blight_input_buffer_t {
    unsigned short device;
    int fd;
    void* ringBuffer;
} blight_input_buffer_t;

typedef struct blight_header_t {
    BlightMessageType type;
    unsigned int ackid;
    uint32_t size;
} blight_header_t;

typedef struct blight_message_t {
    blight_header_t header;
    blight_data_t data;
} blight_message_t;

typedef struct blight_packet_repaint_t {
    int x;
    int y;
    unsigned int width;
    unsigned int height;
    BlightWaveformMode waveform;
    BlightContentType contenttype;
    BlightUpdateMode mode;
    unsigned int marker;
    blight_surface_id_t identifier;
} blight_packet_repaint_t;

typedef struct blight_packet_move_t {
    blight_surface_id_t identifier;
    int x;
    int y;
} blight_packet_move_t;

typedef struct blight_packet_surface_info_t {
    int x;
    int y;
    unsigned int width;
    unsigned int height;
    int stride;
    BlightImageFormat format;
    double scale;
} blight_packet_surface_info_t;

int blight_bus_connect_system(blight_bus** bus);
int blight_bus_connect_user(blight_bus** bus);
void blight_bus_deref(blight_bus* bus);
bool blight_service_available(blight_bus* bus);
int blight_service_open(blight_bus* bus);
blight_input_buffer_t* blight_service_input_open(blight_bus* bus, unsigned short device);
blight_header_t blight_header_from_data(blight_data_t data);
blight_message_t* blight_message_from_data(blight_data_t data);
int blight_message_from_socket(int fd, blight_message_t** message);
void blight_message_deref(blight_message_t* message);
int blight_send_message(
  int fd,
  BlightMessageType type,
  unsigned int ackid,
  uint32_t size,
  blight_data_t data,
  int timeout,
  blight_data_t* response
);
blight_buf_t* blight_create_buffer(
  int x,
  int y,
  unsigned int width,
  unsigned int height,
  unsigned int stride,
  BlightImageFormat format,
  double scale
);
void blight_buffer_deref(blight_buf_t* buf);
blight_surface_id_t blight_add_surface(blight_bus* bus, blight_buf_t* buf);
blight_packet_repaint_t* blight_cast_to_repaint_packet(blight_message_t* message);
blight_packet_move_t* blight_cast_to_move_packet(blight_message_t* message);
blight_packet_surface_info_t* blight_cast_to_surface_info_packet(blight_message_t* message);
int blight_event_from_buffer(
  blight_input_buffer_t* buf,
  struct input_event** event,
  bool blocking
);
void blight_event_free(struct input_event* event);
void blight_input_buffer_deref(blight_input_buffer_t* buf);
int blight_move_surface(
  int fd,
  blight_surface_id_t identifier,
  blight_buf_t* buf,
  int x,
  int y
);
struct blight_thread_t* blight_start_connection_thread(int fd);
int blight_join_connection_thread(struct blight_thread_t* thread);
int blight_detach_connection_thread(struct blight_thread_t* thread);
int blight_stop_connection_thread(struct blight_thread_t* thread);
int blight_connection_thread_deref(struct blight_thread_t* thread);
unsigned int blight_surface_repaint(
  int fd,
  blight_surface_id_t identifier,
  int x,
  int y,
  unsigned int width,
  unsigned int height,
  BlightWaveformMode waveform,
  BlightContentType contenttype,
  BlightUpdateMode mode
);
int blight_remove_surface(int fd, blight_surface_id_t identifier);
int blight_raise(int fd, blight_surface_id_t identifier);
int blight_lower(int fd, blight_surface_id_t identifier);
int blight_focus(int fd);
