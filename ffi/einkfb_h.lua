-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
enum fx_type {
  fx_mask = 11,
  fx_buf_is_mask = 14,
  fx_none = -1,
  fx_flash = 20,
  fx_invert = 21,
  fx_update_partial = 0,
  fx_update_full = 1,
  fx_update_fast = 2,
  fx_update_slow = 3,
  fx_buffer_load = 99,
  fx_buffer_display_partial = 100,
  fx_buffer_display_full = 101,
};
typedef enum fx_type fx_type;
struct update_area_t {
  int x1, y1, x2, y2;
  fx_type which_fx;
  uint8_t *buffer;
};
enum orientation_t {
  orientation_portrait,
  orientation_portrait_upside_down,
  orientation_landscape,
  orientation_landscape_upside_down,
};
typedef enum orientation_t orientation_t;
enum einkfb_events_t {
  einkfb_event_update_display = 0,
  einkfb_event_update_display_area,
  einkfb_event_blank_display,
  einkfb_event_rotate_display,
  einkfb_event_null = -1,
};
typedef enum einkfb_events_t einkfb_events_t;
struct einkfb_event_t {
  einkfb_events_t event;
  fx_type update_mode;
  int x1, y1, x2, y2;
  orientation_t orientation;
};
static const unsigned FBIO_EINK_UPDATE_DISPLAY = 18139;
static const unsigned FBIO_EINK_UPDATE_DISPLAY_AREA = 18141;
static const unsigned FBIO_EINK_SET_DISPLAY_ORIENTATION = 18160;
static const unsigned FBIO_EINK_GET_DISPLAY_ORIENTATION = 18161;
]]
