-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
static const unsigned WEBP_DEMUX_ABI_VERSION = 263;
enum WEBP_CSP_MODE {
  MODE_RGB = 0,
  MODE_RGBA = 1,
  MODE_BGR = 2,
  MODE_BGRA = 3,
  MODE_ARGB = 4,
  MODE_RGBA_4444 = 5,
  MODE_RGB_565 = 6,
  MODE_rgbA = 7,
  MODE_bgrA = 8,
  MODE_Argb = 9,
  MODE_rgbA_4444 = 10,
  MODE_YUV = 11,
  MODE_YUVA = 12,
  MODE_LAST = 13,
};
typedef enum WEBP_CSP_MODE WEBP_CSP_MODE;
struct WebPData {
  const uint8_t *bytes;
  size_t size;
};
typedef struct WebPData WebPData;
struct WebPAnimInfo {
  uint32_t canvas_width;
  uint32_t canvas_height;
  uint32_t loop_count;
  uint32_t bgcolor;
  uint32_t frame_count;
  uint32_t pad[4];
};
typedef struct WebPAnimInfo WebPAnimInfo;
struct WebPAnimDecoderOptions {
  WEBP_CSP_MODE color_mode;
  int use_threads;
  uint32_t padding[7];
};
typedef struct WebPAnimDecoderOptions WebPAnimDecoderOptions;
int WebPAnimDecoderOptionsInitInternal(WebPAnimDecoderOptions *, int);
typedef struct WebPAnimDecoder WebPAnimDecoder;
WebPAnimDecoder *WebPAnimDecoderNewInternal(const WebPData *, const WebPAnimDecoderOptions *, int);
int WebPAnimDecoderGetInfo(const WebPAnimDecoder *dec, WebPAnimInfo *info);
int WebPAnimDecoderGetNext(WebPAnimDecoder *dec, uint8_t **buf, int *timestamp);
void WebPAnimDecoderReset(WebPAnimDecoder *dec);
void WebPAnimDecoderDelete(WebPAnimDecoder *dec);
]]
