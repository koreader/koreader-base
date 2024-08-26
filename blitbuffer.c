/*
    KOReader: blitbuffer implementation for jit-disabled platforms
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>
                  2017 Huang Xin <chrox.huang@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "blitbuffer.h"

static const char*
    get_bbtype_name(int bbtype)
{
    switch (bbtype) {
        case TYPE_BB4:
            return "BB4";
        case TYPE_BB8:
            return "BB8";
        case TYPE_BB8A:
            return "BB8A";
        case TYPE_BBRGB16:
            return "BBRGB16";
        case TYPE_BBRGB24:
            return "BBRGB24";
        case TYPE_BBRGB32:
            return "BBRGB32";
        default:
            return "Unknown!";
    }
}

#define ColorRGB32_To_Color8(color) \
    (Color8){(4898U*color->r + 9618U*color->g + 1869U*color->b) >> 14U}
#define ColorRGB32_To_Color8A(color) \
    (Color8A){(4898U*color->r + 9618U*color->g + 1869U*color->b) >> 14U, color->alpha}
#define ColorRGB32_To_Color16(color) \
    (ColorRGB16){((color->r & 0xF8) << 8U) + ((color->g & 0xFC) << 3U) + ((color->b >> 3U))}
#define ColorRGB32_To_Color24(color) \
    (ColorRGB24){color->r, color->g, color->b}

#define Color8_To_Color8A(color) \
    (Color8A){color->a, 0xFF}
#define Color8A_To_Color8(color) \
    (Color8){color->a}
#define Color8A_To_Color24(color) \
    (ColorRGB24){color->a, color->a, color->a}
#define Color8A_To_Color16(color) \
    (ColorRGB16){((color->a & 0xF8) << 8U) + ((color->a & 0xFC) << 3U) + ((color->a >> 3U))}
#define Color8A_To_Color32(color) \
    (ColorRGB32){color->a, color->a, color->a, color->alpha}

#define ColorRGB16_GetR(v) (((v >> 11U) << 3U) + ((v >> 11U) >> 2U))
#define ColorRGB16_GetG(v) ((((v >> 5U) & 0x3F) << 2U) + (((v >> 5U) & 0x3F) >> 4U))
#define ColorRGB16_GetB(v) (((v & 0x001F) << 3U) + ((v & 0x001F) >> 2U))
#define ColorRGB16_To_A(v) \
    ((39919*ColorRGB16_GetR(v) + \
      39185*ColorRGB16_GetG(v) + \
      15220*ColorRGB16_GetB(v)) >> 14U)
#define RGB_To_RGB16(r, g, b) (((r & 0xF8) << 8U) + ((g & 0xFC) << 3U) + (b >> 3U))
// NOTE: `A` was a *terrible* variable name to settle on. It's actually luminance, e.g., grayscale, a.k.a., Y8.
#define RGB_To_A(r, g, b) ((4898U*r + 9618U*g + 1869U*b) >> 14U)

// Helpers to pack pixels manually, without going through the Color structs.
#define Y8_To_Y8A(v) (0xFFu << 8U | v)
#define RGB_To_RGB32(r, g, b) ((uint32_t) (0xFFu << 24U) | (uint32_t) (b << 16U) | (uint32_t) (g << 8U) | r)
#define Y8_To_RGB32(v) ((uint32_t) (0xFFu << 24U) | (uint32_t) (v << 16U) | (uint32_t) (v << 8U) | v)

// __auto_type was introduced in GCC 4.9 (and Clang ~3.8)...
// NOTE: Inspired from glibc's __GNUC_PREREQ && __glibc_clang_prereq macros (from <features.h>),
//       which we of course can't use because some of our TCs use a glibc version old enough not to have the clang one...
#if (defined(__clang__) && (__clang_major__ > 3 || (__clang_major__ == 3 && __clang_minor__ >= 8))) || \
    ((defined(__GNUC__) && !defined(__clang__)) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9)))
//#warning "Auto Type :)"

#define DIV_255(V)                                                                                   \
({                                                                                                   \
    __auto_type _v = (V) + 128;                                                                      \
    (((_v >> 8U) + _v) >> 8U);                                                                       \
})

#define ColorRGB32_To_PMUL(color) \
    (ColorRGB32){DIV_255(color->r * color->alpha), DIV_255(color->g * color->alpha), DIV_255(color->b * color->alpha), color->alpha}

// MIN/MAX with no side-effects,
// c.f., https://gcc.gnu.org/onlinedocs/cpp/Duplication-of-Side-Effects.html#Duplication-of-Side-Effects
//     & https://dustri.org/b/min-and-max-macro-considered-harmful.html
#define MIN(X, Y)                                                                                    \
({                                                                                                   \
    __auto_type x_ = (X);                                                                            \
    __auto_type y_ = (Y);                                                                            \
    (x_ < y_) ? x_ : y_;                                                                             \
})

#define MAX(X, Y)                                                                                    \
({                                                                                                   \
    __auto_type x__ = (X);                                                                           \
    __auto_type y__ = (Y);                                                                           \
    (x__ > y__) ? x__ : y__;                                                                         \
})

#else
#warning "TypeOf :("

#define DIV_255(V)                                                                                   \
({                                                                                                   \
    typeof (V) _v = (V) + 128;                                                                       \
    (((_v >> 8U) + _v) >> 8U);                                                                       \
})

#define MIN(X, Y)                                                                                    \
({                                                                                                   \
    typeof (X) x_ = (X);                                                                             \
    typeof (Y) y_ = (Y);                                                                             \
    (x_ < y_) ? x_ : y_;                                                                             \
})

#define MAX(X, Y)                                                                                    \
({                                                                                                   \
    typeof (X) x__ = (X);                                                                            \
    typeof (Y) y__ = (Y);                                                                            \
    (x__ > y__) ? x__ : y__;                                                                         \
})

#endif

// Likely/Unlikely branch tagging
#define likely(x)   __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)

// NOTE: See Pillow's transpose operations, or Qt5 qMemRotate stuff for cache-efficient ways of rotating an image data buffer,
//       instead of handling the rotation per-pixel, at plotting time.
//       I have no idea if it'd be an efficient method here, since it requires an extra buffer in which to do the rotation,
//       just so that new buffer can be used for the memcpy-based fast paths...

#define BB_GET_PIXEL(bb, rotation, COLOR, x, y, pptr) \
({ \
    if (rotation == 0) { \
        *pptr = (COLOR*)(bb->data + (y) * bb->stride) + (x); \
    } else if (rotation == 1) { \
        *pptr = (COLOR*)(bb->data + (x) * bb->stride) + bb->w - (y) - 1; \
    } else if (rotation == 2) { \
        *pptr = (COLOR*)(bb->data + (bb->h - (y) - 1) * bb->stride) + bb->w - (x) - 1; \
    } else if (rotation == 3) { \
        *pptr = (COLOR*)(bb->data + (bb->h - (x) - 1) * bb->stride) + (y); \
    } \
})

#define SET_ALPHA_FROM_A(bb, bb_type, bb_rotation, x, y, alpha) \
({ \
    if (bb_type == TYPE_BB8) { \
        const Color8 * restrict srcptr; \
        BB_GET_PIXEL(bb, bb_rotation, Color8, x, y, &srcptr); \
        *alpha = srcptr->a; \
    } else if (bb_type == TYPE_BB8A) { \
        const Color8A * restrict srcptr; \
        BB_GET_PIXEL(bb, bb_rotation, Color8A, x, y, &srcptr); \
        *alpha = srcptr->a; \
    } else if (bb_type == TYPE_BBRGB16) { \
        const ColorRGB16 * restrict srcptr; \
        BB_GET_PIXEL(bb, bb_rotation, ColorRGB16, x, y, &srcptr); \
        *alpha = (uint8_t) ColorRGB16_To_A(srcptr->v); \
    } else if (bb_type == TYPE_BBRGB24) { \
        const ColorRGB24 * restrict srcptr; \
        BB_GET_PIXEL(bb, bb_rotation, ColorRGB24, x, y, &srcptr); \
        *alpha = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b); \
    } else if (bb_type == TYPE_BBRGB32) { \
        const ColorRGB32 * restrict srcptr; \
        BB_GET_PIXEL(bb, bb_rotation, ColorRGB32, x, y, &srcptr); \
        *alpha = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b); \
    } \
})

static inline void BB8_SET_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const Color8 * restrict color) {
    if (likely(x < width && y < height)) {
        Color8 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, Color8, x, y, &pixel);
        *pixel = *color;
    }
}

static inline void BB8A_SET_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const Color8A * restrict color) {
    if (likely(x < width && y < height)) {
        Color8A * restrict pixel;
        BB_GET_PIXEL(bb, rotation, Color8A, x, y, &pixel);
        *pixel = *color;
    }
}

static inline void BBRGB16_SET_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const ColorRGB16 * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB16 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB16, x, y, &pixel);
        *pixel = *color;
    }
}

static inline void BBRGB24_SET_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const ColorRGB24 * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB24 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB24, x, y, &pixel);
        *pixel = *color;
    }
}

static inline void BBRGB32_SET_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const ColorRGB32 * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB32 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB32, x, y, &pixel);
        *pixel = *color;
    }
}

static inline void BB8_BLEND_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const Color8A * restrict color) {
    if (likely(x < width && y < height)) {
        Color8 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, Color8, x, y, &pixel);

        const uint8_t alpha = color->alpha;
        const uint8_t ainv = alpha ^ 0xff;

        pixel->a = (uint8_t) DIV_255(alpha * color->a + ainv * pixel->a);
    }
}
static inline void BB8A_BLEND_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const Color8A * restrict color) {
    if (likely(x < width && y < height)) {
        Color8A * restrict pixel;
        BB_GET_PIXEL(bb, rotation, Color8A, x, y, &pixel);

        const uint8_t alpha = color->alpha;
        const uint8_t ainv = alpha ^ 0xff;

        pixel->a = (uint8_t) DIV_255(alpha * color->a + ainv * pixel->a);
        pixel->alpha = 0xff;
    }
}
static inline void BBRGB16_BLEND_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const Color8A * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB16 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB16, x, y, &pixel);

        const uint8_t alpha = color->alpha;
        const uint8_t ainv = alpha ^ 0xff;

        const uint8_t r = (uint8_t) DIV_255(alpha * color->a + ainv * ColorRGB16_GetR(pixel->v));
        const uint8_t g = (uint8_t) DIV_255(alpha * color->a + ainv * ColorRGB16_GetG(pixel->v));
        const uint8_t b = (uint8_t) DIV_255(alpha * color->a + ainv * ColorRGB16_GetB(pixel->v));
        pixel->v = (uint16_t) RGB_To_RGB16(r, g, b);
    }
}

static inline void BBRGB24_BLEND_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const ColorRGB32 * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB24 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB24, x, y, &pixel);

        const uint8_t alpha = color->alpha;
        const uint8_t ainv = alpha ^ 0xff;

        pixel->r = (uint8_t) DIV_255(alpha * color->r + ainv * pixel->r);
        pixel->g = (uint8_t) DIV_255(alpha * color->g + ainv * pixel->g);
        pixel->b = (uint8_t) DIV_255(alpha * color->b + ainv * pixel->b);
    }
}

static inline void BBRGB32_BLEND_PIXEL_CLAMPED(BlitBuffer * restrict bb, int rotation, unsigned int x, unsigned int y, unsigned int width, unsigned int height, const ColorRGB32 * restrict color) {
    if (likely(x < width && y < height)) {
        ColorRGB32 * restrict pixel;
        BB_GET_PIXEL(bb, rotation, ColorRGB32, x, y, &pixel);

        const uint8_t alpha = color->alpha;
        const uint8_t ainv = alpha ^ 0xff;

        pixel->r = (uint8_t) DIV_255(alpha * color->r + ainv * pixel->r);
        pixel->g = (uint8_t) DIV_255(alpha * color->g + ainv * pixel->g);
        pixel->b = (uint8_t) DIV_255(alpha * color->b + ainv * pixel->b);
        pixel->alpha = (uint8_t) 0xff;
    }
}

static inline unsigned int BB_GET_WIDTH(BlitBuffer * restrict bb) {
    if ((GET_BB_ROTATION(bb) & 1U) == 0U) {
        return bb->w;
    } else {
        return bb->h;
    }
}

static inline unsigned int BB_GET_HEIGHT(BlitBuffer * restrict bb) {
    if ((GET_BB_ROTATION(bb) & 1U) == 0U) {
        return bb->h;
    } else {
        return bb->w;
    }
}

void BB_fill(BlitBuffer * restrict bb, uint8_t v) {
    // Handle any target pitch properly
    const int bb_type = GET_BB_TYPE(bb);
    if (bb_type == TYPE_BB8) {
            //fprintf(stdout, "%s: BB8 fill\n", __FUNCTION__);
            uint8_t * restrict p = bb->data;
            memset(p, v, bb->stride*bb->h);
    } else if (bb_type == TYPE_BB8A) {
            // We do NOT want to stomp on the alpha byte here...
            const uint16_t src = (uint16_t) Y8_To_Y8A(v);
            //fprintf(stdout, "%s: BB8A fill\n", __FUNCTION__);
            uint16_t * restrict p = (uint16_t *) bb->data;
            size_t px_count = bb->pixel_stride*bb->h;
            while (px_count--) {
                *p++ = src;
            }
    } else if (bb_type == TYPE_BBRGB16) {
            // Again, RGB565 means we can't use a straight memset
            const uint16_t src = (uint16_t) RGB_To_RGB16(v, v, v);
            //fprintf(stdout, "%s: BBRGB16 fill\n", __FUNCTION__);
            uint16_t * restrict p = (uint16_t *) bb->data;
            size_t px_count = bb->pixel_stride*bb->h;
            while (px_count--) {
                *p++ = src;
            }
    } else if (bb_type == TYPE_BBRGB24) {
            //fprintf(stdout, "%s: BBRGB24 fill\n", __FUNCTION__);
            uint8_t * restrict p = bb->data;
            memset(p, v, bb->stride*bb->h);
    } else if (bb_type == TYPE_BBRGB32) {
            // And here either, as we want to preserve the alpha byte
            const uint32_t src = (uint32_t) Y8_To_RGB32(v);
            //fprintf(stdout, "%s: BBRGB32 fill\n", __FUNCTION__);
            uint32_t * restrict p = (uint32_t *) bb->data;
            size_t px_count = bb->pixel_stride*bb->h;
            while (px_count--) {
                *p++ = src;
            }
    }
}

void BB_fill_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, uint8_t v) {
    const int rotation = GET_BB_ROTATION(bb);
    unsigned int rx, ry, rw, rh;
    // Compute rotated rectangle coordinates & size
    switch (rotation) {
        case 0:
                rx = x;
                ry = y;
                rw = w;
                rh = h;
                break;
        case 1:
                rx = bb->w - (y + h);
                ry = x;
                rw = h;
                rh = w;
                break;
        case 2:
                rx = bb->w - (x + w);
                ry = bb->h - (y + h);
                rw = w;
                rh = h;
                break;
        case 3:
                rx = y;
                ry = bb->h - (x + w);
                rw = h;
                rh = w;
                break;
    }

    // Handle any target pitch properly
    const int bb_type = GET_BB_TYPE(bb);
    switch (bb_type) {
        case TYPE_BB8:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines (e.g., BB_fill())
                //fprintf(stdout, "%s: Full BB8 paintRect\n", __FUNCTION__);
                uint8_t * restrict p = bb->data + bb->stride*ry;
                memset(p, v, bb->stride*rh);
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BB8 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint8_t * restrict p = bb->data + bb->stride*j + rx;
                    memset(p, v, rw);
                }
            }
            break;
        case TYPE_BB8A:
            // We do NOT want to stomp on the alpha byte here...
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                const uint16_t src = (uint16_t) Y8_To_Y8A(v);
                //fprintf(stdout, "%s: Full BB8A paintRect\n", __FUNCTION__);
                uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = src;
                }
            } else {
                // Scanline per scanline
                const uint16_t src = (uint16_t) Y8_To_Y8A(v);
                //fprintf(stdout, "%s: Scanline BB8A paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = src;
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            // Again, RGB565 means we can't use a straight memset
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                const uint16_t src = (uint16_t) RGB_To_RGB16(v, v, v);
                //fprintf(stdout, "%s: Full BBRGB16 paintRect\n", __FUNCTION__);
                uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = src;
                }
            } else {
                // Scanline per scanline
                const uint16_t src = (uint16_t) RGB_To_RGB16(v, v, v);
                //fprintf(stdout, "%s: Sanline BBRGB16 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = src;
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BBRGB24 paintRect\n", __FUNCTION__);
                uint8_t * restrict p = bb->data + bb->stride*ry;
                memset(p, v, bb->stride*rh);
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BBRGB24 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint8_t * restrict p = bb->data + bb->stride*j + (rx * 3U);
                    memset(p, v, (rw * 3U));
                }
            }
            break;
        case TYPE_BBRGB32:
            // And here either, as we want to preserve the alpha byte
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                const uint32_t src = (uint32_t) Y8_To_RGB32(v);
                //fprintf(stdout, "%s: Full BBRGB32 paintRect\n", __FUNCTION__);
                uint32_t * restrict p = (uint32_t *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = src;
                }
            } else {
                // Scanline per scanline
                const uint32_t src = (uint32_t) Y8_To_RGB32(v);
                //fprintf(stdout, "%s: Pixel BBRGB32 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint32_t * restrict p = (uint32_t *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = src;
                    }
                }
            }
            break;
    }
}

void BB_fill_rect_RGB32(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color) {
    const int rotation = GET_BB_ROTATION(bb);
    unsigned int rx, ry, rw, rh;
    // Compute rotated rectangle coordinates & size
    switch (rotation) {
        case 0:
                rx = x;
                ry = y;
                rw = w;
                rh = h;
                break;
        case 1:
                rx = bb->w - (y + h);
                ry = x;
                rw = h;
                rh = w;
                break;
        case 2:
                rx = bb->w - (x + w);
                ry = bb->h - (y + h);
                rw = w;
                rh = h;
                break;
        case 3:
                rx = y;
                ry = bb->h - (x + w);
                rw = h;
                rh = w;
                break;
    }

    // Handle any target pitch properly
    const int bb_type = GET_BB_TYPE(bb);
    switch (bb_type) {
        case TYPE_BB8:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines (e.g., BB_fill())
                //fprintf(stdout, "%s: Full BB8 paintRect\n", __FUNCTION__);
                uint8_t * restrict p = bb->data + bb->stride*ry;
                memset(p, RGB_To_A(color->r, color->g, color->b), bb->stride*rh);
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BB8 paintRect\n", __FUNCTION__);
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint8_t * restrict p = bb->data + bb->stride*j + rx;
                    memset(p, source_y8, rw);
                }
            }
            break;
        case TYPE_BB8A:
            // We do NOT want to stomp on the alpha byte here...
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                const uint16_t src = (uint16_t) Y8_To_Y8A(RGB_To_A(color->r, color->g, color->b));
                //fprintf(stdout, "%s: Full BB8A paintRect\n", __FUNCTION__);
                uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = src;
                }
            } else {
                // Scanline per scanline
                const uint16_t src = (uint16_t) Y8_To_Y8A(RGB_To_A(color->r, color->g, color->b));
                //fprintf(stdout, "%s: Scanline BB8A paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint16_t * restrict p = (uint16_t *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = src;
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            // Again, RGB565 means we can't use a straight memset
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                const ColorRGB16 src = ColorRGB32_To_Color16(color);
                //fprintf(stdout, "%s: Full BBRGB16 paintRect\n", __FUNCTION__);
                ColorRGB16 * restrict p = (ColorRGB16 *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = src;
                }
            } else {
                // Scanline per scanline
                const ColorRGB16 src = ColorRGB32_To_Color16(color);
                //fprintf(stdout, "%s: Sanline BBRGB16 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    ColorRGB16 * restrict p = (ColorRGB16 *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = src;
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            {
                // Pixel per pixel
                const ColorRGB24 src = ColorRGB32_To_Color24(color);
                //fprintf(stdout, "%s: Pixel BBRGB24 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    for (unsigned int k = rx; k < rx+rw; k++) {
                        uint8_t * restrict p = bb->data + bb->stride*j + (k * 3U);
                        memcpy(p, &src, 3);
                    }
                }
            }
            break;
        case TYPE_BBRGB32:
            // And here either, as we want to preserve the alpha byte
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BBRGB32 paintRect\n", __FUNCTION__);
                ColorRGB32 * restrict p = (ColorRGB32 *) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ = *color;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Pixel BBRGB32 paintRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    ColorRGB32 * restrict p = (ColorRGB32 *) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ = *color;
                    }
                }
            }
            break;
    }
}

void BB_blend_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const Color8A * restrict color) {
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const uint8_t alpha = color->alpha;
    const uint8_t ainv = alpha ^ 0xFF;
    switch (bb_type) {
        case TYPE_BB8:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, Color8, i, j, &dstptr);
                    dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, Color8A, i, j, &dstptr);
                    dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB16, i, j, &dstptr);
                    const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->a * alpha);
                    const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->a * alpha);
                    const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->a * alpha);
                    dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB24, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB32, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                }
            }
            break;
    }
}

void BB_blend_RGB32_over_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color) {
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const uint8_t alpha = color->alpha;
    const uint8_t ainv = alpha ^ 0xFF;
    switch (bb_type) {
        case TYPE_BB8:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + source_y8 * alpha);
                    }
                }
            }
            break;
        case TYPE_BB8A:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8A * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8A, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + source_y8 * alpha);
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB16, i, j, &dstptr);
                    const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->r * alpha);
                    const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->g * alpha);
                    const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->b * alpha);
                    dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB24, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->r * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->g * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->b * alpha);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB32, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->r * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->g * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->b * alpha);
                }
            }
            break;
    }
}

// Dumb multiply blending mode (used for painting book highlights)
void BB_blend_RGB_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB24 * restrict color) {
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    switch (bb_type) {
        case TYPE_BB8:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * source_y8);
                    }
                }
            }
            break;
        case TYPE_BB8A:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8A * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8A, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * source_y8);
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB16, i, j, &dstptr);
                    const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * color->r);
                    const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * color->g);
                    const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * color->b);
                    dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB24, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * color->r);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * color->g);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * color->b);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB32, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * color->r);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * color->g);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * color->b);
                }
            }
            break;
    }
}

// Fancier variant if we ever want to honor color's alpha...
// Function name is a slight misnommer, as we're essentially doing (color MUL rect) OVER rect
void BB_blend_RGB32_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color) {
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const uint8_t alpha = color->alpha;
    const uint8_t ainv = alpha ^ 0xFF;
    switch (bb_type) {
        case TYPE_BB8:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + DIV_255(dstptr->a * source_y8) * alpha);
                    }
                }
            }
            break;
        case TYPE_BB8A:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int j = y; j < y + h; j++) {
                    for (unsigned int i = x; i < x + w; i++) {
                        Color8A * restrict dstptr;
                        BB_GET_PIXEL(bb, bb_rotation, Color8A, i, j, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + DIV_255(dstptr->a * source_y8) * alpha);
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB16, i, j, &dstptr);
                    const uint8_t dr = ColorRGB16_GetR(dstptr->v);
                    const uint8_t dg = ColorRGB16_GetR(dstptr->v);
                    const uint8_t db = ColorRGB16_GetR(dstptr->v);
                    const uint8_t r = (uint8_t) DIV_255(dr * ainv + DIV_255(dr * color->r) * alpha);
                    const uint8_t g = (uint8_t) DIV_255(dg * ainv + DIV_255(dg * color->g) * alpha);
                    const uint8_t b = (uint8_t) DIV_255(db * ainv + DIV_255(db * color->b) * alpha);
                    dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB24, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + DIV_255(dstptr->r * color->r) * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + DIV_255(dstptr->g * color->g) * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + DIV_255(dstptr->b * color->b) * alpha);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int j = y; j < y + h; j++) {
                for (unsigned int i = x; i < x + w; i++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(bb, bb_rotation, ColorRGB32, i, j, &dstptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + DIV_255(dstptr->r * color->r) * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + DIV_255(dstptr->g * color->g) * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + DIV_255(dstptr->b * color->b) * alpha);
                }
            }
            break;
    }
}

void BB_invert_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h) {
    const int rotation = GET_BB_ROTATION(bb);
    unsigned int rx, ry, rw, rh;
    // Compute rotated rectangle coordinates & size
    switch (rotation) {
        case 0:
                rx = x;
                ry = y;
                rw = w;
                rh = h;
                break;
        case 1:
                rx = bb->w - (y + h);
                ry = x;
                rw = h;
                rh = w;
                break;
        case 2:
                rx = bb->w - (x + w);
                ry = bb->h - (y + h);
                rw = w;
                rh = h;
                break;
        case 3:
                rx = y;
                ry = bb->h - (x + w);
                rw = h;
                rh = w;
                break;
    }
    // Handle any target pitch properly
    const int bb_type = GET_BB_TYPE(bb);
    switch (bb_type) {
        case TYPE_BB8:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BB8 invertRect\n", __FUNCTION__);
                uint8_t * restrict p = bb->data + bb->stride*ry;
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ ^= 0xFF;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BB8 invertRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint8_t * restrict p = bb->data + bb->stride*j + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ ^= 0xFF;
                    }
                }
            }
            break;
        case TYPE_BB8A:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BB8A invertRect\n", __FUNCTION__);
                uint16_t * restrict p = (uint16_t*) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ ^= 0x00FF;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BB8A invertRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint16_t * restrict p = (uint16_t*) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ ^= 0x00FF;
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            // NOTE: Not actually accurate, but RGB565 is the worst.
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BBRGB16 invertRect\n", __FUNCTION__);
                uint16_t * restrict p = (uint16_t*) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ ^= 0xFFFF;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BBRGB16 invertRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint16_t * restrict p = (uint16_t*) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ ^= 0xFFFF;
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BBRGB24 invertRect\n", __FUNCTION__);
                uint8_t * restrict p = bb->data + bb->stride*ry;
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ ^= 0xFF;
                    *p++ ^= 0xFF;
                    *p++ ^= 0xFF;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BBRGB24 invertRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint8_t * restrict p = bb->data + bb->stride*j + (rx * 3U);
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ ^= 0xFF;
                        *p++ ^= 0xFF;
                        *p++ ^= 0xFF;
                    }
                }
            }
            break;
        case TYPE_BBRGB32:
            if (rx == 0 && rw == bb->w) {
                // Single step for contiguous scanlines
                //fprintf(stdout, "%s: Full BBRGB32 invertRect\n", __FUNCTION__);
                uint32_t * restrict p = (uint32_t*) (bb->data + bb->stride*ry);
                size_t px_count = bb->pixel_stride*rh;
                while (px_count--) {
                    *p++ ^= 0x00FFFFFF;
                }
            } else {
                // Scanline per scanline
                //fprintf(stdout, "%s: Scanline BBRGB32 invertRect\n", __FUNCTION__);
                for (unsigned int j = ry; j < ry+rh; j++) {
                    uint32_t * restrict p = (uint32_t*) (bb->data + bb->stride*j) + rx;
                    size_t px_count = rw;
                    while (px_count--) {
                        *p++ ^= 0x00FFFFFF;
                    }
                }
            }
            break;
    }
}

void BB_hatch_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, unsigned int stripe_width, const Color8 * restrict color, uint8_t alpha) {
    if (alpha == 0) { // NOP
        return;
    }
    const uint8_t ainv = alpha ^ 0xFF;
    const int bb_type = GET_BB_TYPE(bb);
    const int rotation = GET_BB_ROTATION(bb);
    const int sw2 = stripe_width * 2;
    switch (bb_type) {
        case TYPE_BB8:
            if (alpha == 0xFF) {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, Color8, x+d_x, y+d_y, &dstptr);
                            *dstptr = *color;
                        }
                    }
                }
            } else {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, Color8, x+d_x, y+d_y, &dstptr);
                            dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                        }
                    }
                }
            }
            break;
        case TYPE_BB8A:
            if (alpha == 0xFF) {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            Color8A * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, Color8A, x+d_x, y+d_y, &dstptr);
                            dstptr->a = color->a;
                        }
                    }
                }
            } else {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            Color8A * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, Color8A, x+d_x, y+d_y, &dstptr);
                            dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                        }
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            if (alpha == 0xFF) {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB16, x + d_x, y + d_y, &dstptr);
                            dstptr->v = (uint16_t) RGB_To_RGB16(color->a, color->a, color->a);
                        }
                    }
                }
            } else {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB16, x + d_x, y + d_y, &dstptr);
                            const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->a * alpha);
                            const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->a * alpha);
                            const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->a * alpha);
                            dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                        }
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            if (alpha == 0xFF) {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB24 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB24, x + d_x, y + d_y, &dstptr);
                            dstptr->r = color->a;
                            dstptr->g = color->a;
                            dstptr->b = color->a;
                        }
                    }
                }
            } else {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB24 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB24, x + d_x, y + d_y, &dstptr);
                            dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                            dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                            dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                        }
                    }
                }
            }
            break;
        case TYPE_BBRGB32:
            if (alpha == 0xFF) {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB32, x + d_x, y + d_y, &dstptr);
                            dstptr->r = (uint8_t) color->a;
                            dstptr->g = (uint8_t) color->a;
                            dstptr->b = (uint8_t) color->a;
                            // dstptr->alpha = 0xFF;
                        }
                    }
                }
            } else {
                for (unsigned int d_y = 0; d_y < h; d_y++) {
                    for (unsigned int d_x = 0; d_x < w; d_x++) {
                        if ((d_x + d_y) % sw2 < stripe_width) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(bb, rotation, ColorRGB32, x + d_x, y + d_y, &dstptr);
                            dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                            dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                            dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                            // dstptr->alpha = 0xFF;
                        }
                    }
                }
            }
            break;
    }
}

void BB_blit_to_BB8(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            // We can only do a fast copy for simple same-to-same blitting without any extra processing.
            // (i.e., setPixel, no rota, no invert).
            // The cbb codepath ensures setPixel & no invert, so we only check for rotation.
            if (sbb_rotation == 0 && dbb_rotation == 0) {
                if (offs_x == 0 && dest_x == 0 && w == src->w && w == dst->w && src->stride == dst->stride) {
                    // Single step for contiguous scanlines (on both sides)
                    //fprintf(stdout, "%s: full copy blit from BB8 to BB8\n", __FUNCTION__);
                    // BB8 is 1 byte per pixel
                    const uint8_t * restrict srcp = src->data + src->stride*offs_y;
                    uint8_t * restrict dstp = dst->data + dst->stride*dest_y;
                    memcpy(dstp, srcp, w*h);
                } else {
                    // Scanline per scanline copy
                    //fprintf(stdout, "%s: scanline copy blit from BB8 to BB8\n", __FUNCTION__);
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y+h; d_y++, o_y++) {
                        // BB8 is 1 byte per pixel
                        const uint8_t * restrict srcp = src->data + src->stride*o_y + offs_x;
                        uint8_t * restrict dstp = dst->data + dst->stride*d_y + dest_x;
                        memcpy(dstp, srcp, w);
                    }
                }
            } else {
                for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                    for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                        const Color8 * restrict srcptr;
                        BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                        *dstptr = *srcptr;
                    }
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->a = srcptr->a;
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) ColorRGB16_To_A(srcptr->v);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
    }
}

// Quantize an 8-bit color value down to a palette of 16 evenly spaced colors, using an ordered 8x8 dithering pattern.
// With a grayscale input, this happens to match the eInk palette perfectly ;).
// If the input is not grayscale, and the output fb is not grayscale either,
// this usually still happens to match the eInk palette after the EPDC's own quantization pass.
// c.f., https://en.wikipedia.org/wiki/Ordered_dithering
// & https://github.com/ImageMagick/ImageMagick/blob/ecfeac404e75f304004f0566557848c53030bad6/MagickCore/threshold.c#L1627
// NOTE: As the references imply, this is straight from ImageMagick,
//       with only minor simplifications to enforce Q8 & avoid fp maths.
static uint8_t
    dither_o8x8(unsigned int x, unsigned int y, uint8_t v)
{
    // c.f., https://github.com/ImageMagick/ImageMagick/blob/ecfeac404e75f304004f0566557848c53030bad6/config/thresholds.xml#L107
    static const uint8_t threshold_map_o8x8[] = { 1,  49, 13, 61, 4,  52, 16, 64, 33, 17, 45, 29, 36, 20, 48, 32,
                            9,  57, 5,  53, 12, 60, 8,  56, 41, 25, 37, 21, 44, 28, 40, 24,
                            3,  51, 15, 63, 2,  50, 14, 62, 35, 19, 47, 31, 34, 18, 46, 30,
                            11, 59, 7,  55, 10, 58, 6,  54, 43, 27, 39, 23, 42, 26, 38, 22 };

    // Constants:
    // Quantum = 8; Levels = 16; map Divisor = 65
    // QuantumRange = 0xFF
    // QuantumScale = 1.0 / QuantumRange
    //
    // threshold = QuantumScale * v * ((L-1) * (D-1) + 1)
    // NOTE: The initial computation of t (specifically, what we pass to DIV255) would overflow an uint8_t.
    //       With a Q8 input value, we're at no risk of ever underflowing, so, keep to unsigned maths.
    //       Technically, an uint16_t would be wide enough, but it gains us nothing,
    //       and requires a few explicit casts to make GCC happy ;).
    uint32_t t = DIV_255(v * ((15U << 6U) + 1U));
    // level = t / (D-1);
    const uint32_t l = (t >> 6U);
    // t -= l * (D-1);
    t = (t - (l << 6U));

    // map width & height = 8
    // c = ClampToQuantum((l+(t >= map[(x % mw) + mw * (y % mh)])) * QuantumRange / (L-1));
    const uint32_t q = ((l + (t >= threshold_map_o8x8[(x & 7U) + 8U * (y & 7U)])) * 17U);
    // NOTE: We're doing unsigned maths, so, clamping is basically MIN(q, UINT8_MAX) ;).
    //       The only overflow we should ever catch should be for a few white (v = 0xFF) input pixels
    //       that get shifted to the next step (i.e., q = 272 (0xFF + 17)).
    return (q > UINT8_MAX ? UINT8_MAX : (uint8_t) q);
}

void BB_dither_blit_to_BB8(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) ColorRGB16_To_A(srcptr->v));
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                }
            }
            break;
    }
}

void BB_blit_to_BB8A(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->a = srcptr->a;
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    *dstptr = *srcptr;
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) ColorRGB16_To_A(srcptr->v);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
    }
}

void BB_blit_to_BB16(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    const uint8_t v = srcptr->a;
                    const uint8_t v5bit = v >> 3U;
                    dstptr->v = (uint16_t) ((v5bit << 11U) + ((v & 0xFC) << 3U) + v5bit);
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    const uint8_t v = srcptr->a;
                    const uint8_t v5bit = v >> 3U;
                    dstptr->v = (uint16_t) ((v5bit << 11U) + ((v & 0xFC) << 3U) + v5bit);
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    *dstptr = *srcptr;
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                }
            }
            break;
    }
}

void BB_blit_to_BB24(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->a;
                    dstptr->g = srcptr->a;
                    dstptr->b = srcptr->a;
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->a;
                    dstptr->g = srcptr->a;
                    dstptr->b = srcptr->a;
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->r = (uint8_t) ColorRGB16_GetR(srcptr->v);
                    dstptr->g = (uint8_t) ColorRGB16_GetG(srcptr->v);
                    dstptr->b = (uint8_t) ColorRGB16_GetB(srcptr->v);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    *dstptr = *srcptr;
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->r;
                    dstptr->g = srcptr->g;
                    dstptr->b = srcptr->b;
                }
            }
            break;
    }
}

void BB_blit_to_BB32(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (sbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->a;
                    dstptr->g = srcptr->a;
                    dstptr->b = srcptr->a;
                    dstptr->alpha = 0xFF;
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->a;
                    dstptr->g = srcptr->a;
                    dstptr->b = srcptr->a;
                    dstptr->alpha = srcptr->alpha; // if bad result, try: srcptr->alpha ^ 0xFF
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->r = (uint8_t) ColorRGB16_GetR(srcptr->v);
                    dstptr->g = (uint8_t) ColorRGB16_GetG(srcptr->v);
                    dstptr->b = (uint8_t) ColorRGB16_GetB(srcptr->v);
                    dstptr->alpha = 0xFF;
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->r;
                    dstptr->g = srcptr->g;
                    dstptr->b = srcptr->b;
                    dstptr->alpha = 0xFF;
                }
            }
            break;
        case TYPE_BBRGB32:
            // We can only do a fast copy for simple same-to-same blitting without any extra processing.
            // (i.e., setPixel, no rota, no invert).
            // The cbb codepath ensures setPixel & no invert, so we only check for rotation.
            if (sbb_rotation == 0 && dbb_rotation == 0) {
                if (offs_x == 0 && dest_x == 0 && w == src->w && w == dst->w && src->stride == dst->stride) {
                    // Single step for contiguous scanlines (on both sides)
                    //fprintf(stdout, "%s: full copy blit from BBRGB32 to BBRGB32\n", __FUNCTION__);
                    // BBRGB32 is 4 bytes per pixel
                    const uint8_t * restrict srcp = src->data + src->stride*offs_y;
                    uint8_t * restrict dstp = dst->data + dst->stride*dest_y;
                    memcpy(dstp, srcp, (w << 2U)*h);
                } else {
                    // Scanline per scanline copy
                    //fprintf(stdout, "%s: scanline copy blit from BBRGB32 to BBRGB32\n", __FUNCTION__);
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y+h; d_y++, o_y++) {
                        // BBRGB32 is 4 bytes per pixel
                        const uint8_t * restrict srcp = src->data + src->stride*o_y + (offs_x << 2);
                        uint8_t * restrict dstp = dst->data + dst->stride*d_y + (dest_x << 2);
                        memcpy(dstp, srcp, w << 2U);
                    }
                }
            } else {
                for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                    for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                        ColorRGB32 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                        const ColorRGB32 * restrict srcptr;
                        BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                        *dstptr = *srcptr;
                    }
                }
            }
            break;
    }
}

void BB_blit_to(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    //fprintf(stdout, "%s: blit from type: %s to: %s\n", __FUNCTION__, get_bbtype_name(GET_BB_TYPE(src)), get_bbtype_name(GET_BB_TYPE(dst)));
    switch (dbb_type) {
        case TYPE_BB8:
            return BB_blit_to_BB8(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BB8A:
            return BB_blit_to_BB8A(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB16:
            return BB_blit_to_BB16(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB24:
            return BB_blit_to_BB24(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB32:
            return BB_blit_to_BB32(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    }
}

// Only actually honors dithering when blitting to BB8 ;).
void BB_dither_blit_to(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    //fprintf(stdout, "%s: dither blit from type: %s to: %s\n", __FUNCTION__, get_bbtype_name(GET_BB_TYPE(src)), get_bbtype_name(GET_BB_TYPE(dst)));
    switch (dbb_type) {
        case TYPE_BB8:
            return BB_dither_blit_to_BB8(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BB8A:
            return BB_blit_to_BB8A(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB16:
            return BB_blit_to_BB16(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB24:
            return BB_blit_to_BB24(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
        case TYPE_BBRGB32:
            return BB_blit_to_BB32(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    }
}

void BB_add_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h,
        uint8_t alpha) {
    // fast paths
    if (alpha == 0) {
        // NOP
        return;
    } else if (alpha == 0xFF) {
        return BB_blit_to(src, dst, dest_x, dest_y, offs_x, offs_x, w, h);
    }

    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    if (dbb_type != sbb_type) {
        fprintf(stderr, "%s: incompatible bb (dst: %s, src: %s) in file %s, line %d!\n",
                __FUNCTION__, get_bbtype_name(dbb_type), get_bbtype_name(sbb_type), __FILE__, __LINE__);
        exit(1);
    }
    const uint8_t ainv = alpha ^ 0xFF;
    switch (dbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const Color8A * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + ColorRGB16_GetR(srcptr->v) * alpha);
                    const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + ColorRGB16_GetG(srcptr->v) * alpha);
                    const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + ColorRGB16_GetB(srcptr->v) * alpha);
                    dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                    dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                    dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                }
            }
            break;
    }
}

void BB_alpha_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = srcptr->a;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->a = (uint8_t) ColorRGB16_To_A(srcptr->v);
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                const uint8_t srca = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srca * alpha);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BB8A:
            switch (sbb_type) {
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8A * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                                *dstptr = *srcptr;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8A * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8A, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB16:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->a, srcptr->a, srcptr->a);
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->a, srcptr->a, srcptr->a);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                const uint8_t dsta = (uint8_t) ColorRGB16_To_A(dstptr->v);
                                const uint8_t bdsta = (uint8_t) DIV_255(dsta * ainv + srcptr->a * alpha);
                                dstptr->v = (uint16_t) RGB_To_RGB16(bdsta, bdsta, bdsta);
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + srcptr->r * alpha);
                                const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + srcptr->g * alpha);
                                const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + srcptr->b * alpha);
                                dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB16, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB24:
            switch (sbb_type) {
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB24 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB24, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB32:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->r = srcptr->a;
                            dstptr->g = srcptr->a;
                            dstptr->b = srcptr->a;
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                dstptr->r = srcptr->a;
                                dstptr->g = srcptr->a;
                                dstptr->b = srcptr->a;
                                //dstptr->alpha = srcptr->alpha;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                const uint8_t dsta = (uint8_t) RGB_To_A(dstptr->r, dstptr->g, dstptr->b);
                                const uint8_t bdsta = (uint8_t) DIV_255(dsta * ainv + srcptr->a * alpha);
                                dstptr->r = bdsta;
                                dstptr->g = bdsta;
                                dstptr->b = bdsta;
                                //dstptr->alpha = dstptr->alpha;
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->r = (uint8_t) ColorRGB16_GetR(srcptr->v);
                            dstptr->g = (uint8_t) ColorRGB16_GetG(srcptr->v);
                            dstptr->b = (uint8_t) ColorRGB16_GetB(srcptr->v);
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->r = srcptr->r;
                            dstptr->g = srcptr->g;
                            dstptr->b = srcptr->b;
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                *dstptr = *srcptr;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                                dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                                dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                                //dstptr->alpha = dstptr->alpha;
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB32, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        default:
            fprintf(stderr, "%s: incompatible bb (dst: %s, src: %s) in file %s, line %d!\n",
                    __FUNCTION__, get_bbtype_name(dbb_type), get_bbtype_name(sbb_type), __FILE__, __LINE__);
            exit(1);
            break;
    }
}

// NOTE: Keep in sync w/ BB_alpha_blit_from!
//       Dithering is only honored for BB8 dbb ;).
void BB_dither_alpha_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * alpha));
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) ColorRGB16_To_A(srcptr->v));
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                const uint8_t srca = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) DIV_255(dstptr->a * ainv + srca * alpha));
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        default:
            return BB_alpha_blit_from(dst, src, dest_x, dest_y, offs_x, offs_y, w, h);
    }
}

// NOTE: Keep in sync w/ BB_alpha_blit_from!
//       The only functional change being that, when actually alpha-blending, src * alpha becomes src * 0xFF
//       Duplicating 350 LOC for that feels awesome! But saves a deeply nested branch in a pixel loop, which would be bad.
void BB_pmulalpha_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = srcptr->a;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * 0xFF);
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->a = (uint8_t) ColorRGB16_To_A(srcptr->v);
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                const uint8_t srca = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srca * 0xFF);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BB8A:
            switch (sbb_type) {
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8A * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                                *dstptr = *srcptr;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8A * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                                dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * 0xFF);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8A, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB16:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->a, srcptr->a, srcptr->a);
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->a, srcptr->a, srcptr->a);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                const uint8_t dsta = (uint8_t) ColorRGB16_To_A(dstptr->v);
                                const uint8_t bdsta = (uint8_t) DIV_255(dsta * ainv + srcptr->a * 0xFF);
                                dstptr->v = (uint16_t) RGB_To_RGB16(bdsta, bdsta, bdsta);
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB16 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                dstptr->v = (uint16_t) RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB16 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                                const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + srcptr->r * 0xFF);
                                const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + srcptr->g * 0xFF);
                                const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + srcptr->b * 0xFF);
                                dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB16, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB24:
            switch (sbb_type) {
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB24 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            *dstptr = *srcptr;
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB24, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        case TYPE_BBRGB32:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->r = srcptr->a;
                            dstptr->g = srcptr->a;
                            dstptr->b = srcptr->a;
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                dstptr->r = srcptr->a;
                                dstptr->g = srcptr->a;
                                dstptr->b = srcptr->a;
                                //dstptr->alpha = srcptr->alpha;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                const uint8_t dsta = (uint8_t) RGB_To_A(dstptr->r, dstptr->g, dstptr->b);
                                const uint8_t bdsta = (uint8_t) DIV_255(dsta * ainv + srcptr->a * 0xFF);
                                dstptr->r = bdsta;
                                dstptr->g = bdsta;
                                dstptr->b = bdsta;
                                //dstptr->alpha = dstptr->alpha;
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->r = (uint8_t) ColorRGB16_GetR(srcptr->v);
                            dstptr->g = (uint8_t) ColorRGB16_GetG(srcptr->v);
                            dstptr->b = (uint8_t) ColorRGB16_GetB(srcptr->v);
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            ColorRGB32 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->r = srcptr->r;
                            dstptr->g = srcptr->g;
                            dstptr->b = srcptr->b;
                            //dstptr->alpha = dstptr->alpha;
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                *dstptr = *srcptr;
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                ColorRGB32 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                                dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + srcptr->r * 0xFF);
                                dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + srcptr->g * 0xFF);
                                dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + srcptr->b * 0xFF);
                                //dstptr->alpha = dstptr->alpha;
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BBRGB32, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        default:
            fprintf(stderr, "%s: incompatible bb (dst: %s, src: %s) in file %s, line %d!\n",
                    __FUNCTION__, get_bbtype_name(dbb_type), get_bbtype_name(sbb_type), __FILE__, __LINE__);
            exit(1);
            break;
    }
}

// NOTE: Keep in sync w/ BB_pmulalpha_blit_from!
//       Dithering is only honored for BB8 dbb ;).
void BB_dither_pmulalpha_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            switch (sbb_type) {
                case TYPE_BB8:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const Color8 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                        }
                    }
                    break;
                case TYPE_BB8A:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const Color8A * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, srcptr->a);
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) DIV_255(dstptr->a * ainv + srcptr->a * 0xFF));
                            }
                        }
                    }
                    break;
                case TYPE_BBRGB16:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB16 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) ColorRGB16_To_A(srcptr->v));
                        }
                    }
                    break;
                case TYPE_BBRGB24:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            const ColorRGB24 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                            dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                        }
                    }
                    break;
                case TYPE_BBRGB32:
                    for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                        for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                            const ColorRGB32 * restrict srcptr;
                            BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                            const uint8_t alpha = srcptr->alpha;
                            if (alpha == 0) {
                                // NOP
                            } else if (alpha == 0xFF) {
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b));
                            } else {
                                const uint8_t ainv = alpha ^ 0xFF;
                                const uint8_t srca = (uint8_t) RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                                Color8 * restrict dstptr;
                                BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                                dstptr->a = dither_o8x8(o_x, o_y, (uint8_t) DIV_255(dstptr->a * ainv + srca * 0xFF));
                            }
                        }
                    }
                    break;
                default:
                    fprintf(stderr, "%s: incompatible bb (dst: BB8, src: %s) in file %s, line %d!\n",
                            __FUNCTION__, get_bbtype_name(sbb_type), __FILE__, __LINE__);
                    exit(1);
                    break;
            }
            break;
        default:
            return BB_pmulalpha_blit_from(dst, src, dest_x, dest_y, offs_x, offs_y, w, h);
    }
}

void BB_invert_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    if (dbb_type != sbb_type) {
        fprintf(stderr, "%s: incompatible bb (dst: %s, src: %s) in file %s, line %d!\n",
                __FUNCTION__, get_bbtype_name(dbb_type), get_bbtype_name(sbb_type), __FILE__, __LINE__);
        exit(1);
    }
    switch (dbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                    const Color8 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8, o_x, o_y, &srcptr);
                    dstptr->a = srcptr->a ^ 0xFF;
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    Color8A * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                    const Color8A *srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, Color8A, o_x, o_y, &srcptr);
                    dstptr->a = srcptr->a ^ 0xFF;
                }
            }
            break;
        case TYPE_BBRGB16:
            // NOTE: Much like BB_invert_rect, innacurate
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB16 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                    const ColorRGB16 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB16, o_x, o_y, &srcptr);
                    dstptr->v = srcptr->v ^ 0xFFFF;
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB24 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                    const ColorRGB24 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB24, o_x, o_y, &srcptr);
                    dstptr->r = srcptr->r ^ 0xFF;
                    dstptr->g = srcptr->g ^ 0xFF;
                    dstptr->b = srcptr->b ^ 0xFF;
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    ColorRGB32 * restrict dstptr;
                    BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                    const ColorRGB32 * restrict srcptr;
                    BB_GET_PIXEL(src, sbb_rotation, ColorRGB32, o_x, o_y, &srcptr);
                    *(uint32_t*) dstptr = *(uint32_t*) srcptr ^ 0x00FFFFFF;
                }
            }
            break;
    }
}

void BB_color_blit_from(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const Color8A * restrict color) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                        dstptr->a = color->a;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        Color8 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                    }
                }
            }
            break;
        case TYPE_BB8A:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        Color8A * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                        dstptr->a = color->a;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        Color8A * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                        dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + color->a * alpha);
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB16 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                        dstptr->v = (uint16_t) RGB_To_RGB16(color->a, color->a, color->a);
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB16 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                        const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->a * alpha);
                        const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->a * alpha);
                        const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->a * alpha);
                        dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB24 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                        dstptr->r = color->a;
                        dstptr->g = color->a;
                        dstptr->b = color->a;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB24 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                        dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                        dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                        dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                    }
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    // NOTE: GCC *may* throw a -Wmaybe-uninitialized about alpha here,
                    //       because of the lack of default case in the SET_ALPHA_FROM_A switch.
                    //       Not a cause for alarm here :).
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB32 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                        dstptr->r = color->a;
                        dstptr->g = color->a;
                        dstptr->b = color->a;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB32 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                        dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->a * alpha);
                        dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->a * alpha);
                        dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->a * alpha);
                    }
                }
            }
            break;
    }
}

void BB_color_blit_from_RGB32(BlitBuffer * restrict dst, const BlitBuffer * restrict src,
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color) {
    const int dbb_type = GET_BB_TYPE(dst);
    const int sbb_type = GET_BB_TYPE(src);
    const int sbb_rotation = GET_BB_ROTATION(src);
    const int dbb_rotation = GET_BB_ROTATION(dst);
    switch (dbb_type) {
        case TYPE_BB8:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                    for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                        uint8_t alpha;
                        SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                        if (alpha == 0) {
                            // NOP
                        } else if (alpha == 0xFF) {
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            dstptr->a = source_y8;
                        } else {
                            const uint8_t ainv = alpha ^ 0xFF;
                            Color8 * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8, d_x, d_y, &dstptr);
                            dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + source_y8 * alpha);
                        }
                    }
                }
            }
            break;
        case TYPE_BB8A:
            {
                const uint8_t source_y8 = RGB_To_A(color->r, color->g, color->b);
                for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                    for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                        uint8_t alpha;
                        SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                        if (alpha == 0) {
                            // NOP
                        } else if (alpha == 0xFF) {
                            Color8A * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                            dstptr->a = source_y8;
                        } else {
                            const uint8_t ainv = alpha ^ 0xFF;
                            Color8A * restrict dstptr;
                            BB_GET_PIXEL(dst, dbb_rotation, Color8A, d_x, d_y, &dstptr);
                            dstptr->a = (uint8_t) DIV_255(dstptr->a * ainv + source_y8 * alpha);
                        }
                    }
                }
            }
            break;
        case TYPE_BBRGB16:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB16 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                        dstptr->v = (uint16_t) RGB_To_RGB16(color->r, color->g, color->b);
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB16 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB16, d_x, d_y, &dstptr);
                        const uint8_t r = (uint8_t) DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->r * alpha);
                        const uint8_t g = (uint8_t) DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->g * alpha);
                        const uint8_t b = (uint8_t) DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->b * alpha);
                        dstptr->v = (uint16_t) RGB_To_RGB16(r, g, b);
                    }
                }
            }
            break;
        case TYPE_BBRGB24:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB24 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                        dstptr->r = color->r;
                        dstptr->g = color->g;
                        dstptr->b = color->b;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB24 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB24, d_x, d_y, &dstptr);
                        dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->r * alpha);
                        dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->g * alpha);
                        dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->b * alpha);
                    }
                }
            }
            break;
        case TYPE_BBRGB32:
            for (unsigned int d_y = dest_y, o_y = offs_y; d_y < dest_y + h; d_y++, o_y++) {
                for (unsigned int d_x = dest_x, o_x = offs_x; d_x < dest_x + w; d_x++, o_x++) {
                    // NOTE: GCC *may* throw a -Wmaybe-uninitialized about alpha here,
                    //       because of the lack of default case in the SET_ALPHA_FROM_A switch.
                    //       Not a cause for alarm here :).
                    uint8_t alpha;
                    SET_ALPHA_FROM_A(src, sbb_type, sbb_rotation, o_x, o_y, &alpha);
                    if (alpha == 0) {
                        // NOP
                    } else if (alpha == 0xFF) {
                        ColorRGB32 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                        dstptr->r = color->r;
                        dstptr->g = color->g;
                        dstptr->b = color->b;
                    } else {
                        const uint8_t ainv = alpha ^ 0xFF;
                        ColorRGB32 * restrict dstptr;
                        BB_GET_PIXEL(dst, dbb_rotation, ColorRGB32, d_x, d_y, &dstptr);
                        dstptr->r = (uint8_t) DIV_255(dstptr->r * ainv + color->r * alpha);
                        dstptr->g = (uint8_t) DIV_255(dstptr->g * ainv + color->g * alpha);
                        dstptr->b = (uint8_t) DIV_255(dstptr->b * ainv + color->b * alpha);
                    }
                }
            }
            break;
    }
}

// Information about those three algorithms can be found on http://members.chello.at/~easyfilter/ (Zingl Alois)
void BB_paint_rounded_corner_noAA(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int bw, int r, uint8_t c);
void BB_paint_rounded_corner_AA(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int bw, int r, uint8_t c);
void BB_paint_rounded_corner_AA_1px(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int r, uint8_t c);

void BB_paint_rounded_corner(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, unsigned int bw, unsigned int r, uint8_t c, int anti_aliasing) {
    /*
    if (2*r > h || 2*r > w || r == 0) {
        // NOP
        return;
    }
    */

    r = MIN(r, MIN(h, w));
    if (bw > r) {
        bw = r;
    }

    if (!anti_aliasing) {
        BB_paint_rounded_corner_noAA(bb, off_x, off_y, w, h, bw, r, c);
    } else {
        if (bw == 1) {
            BB_paint_rounded_corner_AA_1px(bb, off_x, off_y, w, h, r, c);
        } else {
            BB_paint_rounded_corner_AA(bb, off_x, off_y, w, h, bw, r, c);
        }
    }
}

void BB_paint_rounded_corner_noAA(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int bw, int r, uint8_t c) {

    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const unsigned int bb_width = BB_GET_WIDTH(bb);
    const unsigned int bb_height = BB_GET_HEIGHT(bb);

    /* The used algorithm is described in
     * https://de.wikipedia.org/wiki/Bresenham-Algorithmus#Kreisvariante_des_Algorithmus
     */

    // r ... radius of outer circle
    int x = 0;
    int y = r;
    int f = 1 - r;
    int ddF_x = 0;
    int ddF_y = -2 * r;

    // r2 ... radius of inner circle; might be zero
    const unsigned int r2 = r - bw;

    int x2 = 0;
    int y2 = r2;

    int f2 = 1 - r2;
    int ddF2_x = 0;
    int ddF2_y = -2 * r2;

    while(x < y)
    {
        if (f >= 0) {
            --y;
            ddF_y += 2;
            f += ddF_y;
        }
        ++x;
        ddF_x += 2;
        f += ddF_x + 1;

        if (r2 != 0 ) {
            if (f2 >= 0)
            {
                --y2;
                ddF2_y += 2;
                f2 += ddF2_y;
            }
            ++x2;
            ddF2_x += 2;
            f2 += ddF2_x + 1;
        }

        // Fill between inner and outer circle.
        for (int tmp_y = y; tmp_y > y2; tmp_y--) {
            if (bb_type == TYPE_BB8) {
                const Color8 color = { .a = c };

                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, bb_width, bb_height, &color);

                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (r)+off_y-x, bb_width, bb_height, &color);
                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (r)+off_y-tmp_y, bb_width, bb_height, &color);

                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (r)+off_y-tmp_y, bb_width, bb_height, &color);
                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (r)+off_y-x, bb_width, bb_height, &color);

                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (h-r)+off_y+x-1, bb_width, bb_height, &color);
                BB8_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
            } else if (bb_type == TYPE_BB8A) {
                const Color8A color = { .a = c, .alpha = 0xFF };

                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, bb_width, bb_height, &color);

                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (r)+off_y-x, bb_width, bb_height, &color);
                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (r)+off_y-tmp_y, bb_width, bb_height, &color);

                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (r)+off_y-tmp_y, bb_width, bb_height, &color);
                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (r)+off_y-x, bb_width, bb_height, &color);

                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (h-r)+off_y+x-1, bb_width, bb_height, &color);
                BB8A_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
            } else if (bb_type == TYPE_BBRGB16) {
                const ColorRGB16 color = { .v = RGB_To_RGB16(c, c, c) };

                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, bb_width, bb_height, &color);

                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (r)+off_y-x, bb_width, bb_height, &color);
                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (r)+off_y-tmp_y, bb_width, bb_height, &color);

                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (r)+off_y-tmp_y, bb_width, bb_height, &color);
                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (r)+off_y-x, bb_width, bb_height, &color);

                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (h-r)+off_y+x-1, bb_width, bb_height, &color);
                BBRGB16_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
            } else if (bb_type == TYPE_BBRGB24) {
                const ColorRGB24 color = { .r = c, .g = c, .b = c };

                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, bb_width, bb_height, &color);

                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (r)+off_y-x, bb_width, bb_height, &color);
                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (r)+off_y-tmp_y, bb_width, bb_height, &color);

                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (r)+off_y-tmp_y, bb_width, bb_height, &color);
                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (r)+off_y-x, bb_width, bb_height, &color);

                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (h-r)+off_y+x-1, bb_width, bb_height, &color);
                BBRGB24_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);
            } else if (bb_type == TYPE_BBRGB32) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 0xFF };

                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color);  // 7. octant
                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (h-r)+off_y+x-1, bb_width, bb_height, &color);  // 8. octant

                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+tmp_y-1, (r)+off_y-x, bb_width, bb_height, &color); // 1. octant
                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (w-r)+off_x+x-1, (r)+off_y-tmp_y, bb_width, bb_height, &color); // 2. octant

                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (r)+off_y-tmp_y, bb_width, bb_height, &color);  // 3. octant
                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (r)+off_y-x, bb_width, bb_height, &color);  // 4. octant

                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-tmp_y, (h-r)+off_y+x-1, bb_width, bb_height, &color); // 5. octant
                BBRGB32_SET_PIXEL_CLAMPED(bb, bb_rotation, (r)+off_x-x, (h-r)+off_y+tmp_y-1, bb_width, bb_height, &color); // 6. octant
            }
        }
    }
}

#define setPixelAA_BB8(x, y)     BB8_BLEND_PIXEL_CLAMPED(bb, bb_rotation, x, y, bb_width, bb_height, &color);
#define setPixelAA_BB8A(x, y)    BB8A_BLEND_PIXEL_CLAMPED(bb, bb_rotation, x, y, bb_width, bb_height, &color);
#define setPixelAA_BBRGB16(x, y) BBRGB16_BLEND_PIXEL_CLAMPED(bb, bb_rotation, x, y, bb_width, bb_height, &color);
#define setPixelAA_BBRGB24(x, y) BBRGB24_BLEND_PIXEL_CLAMPED(bb, bb_rotation, x, y, bb_width, bb_height, &color);
#define setPixelAA_BBRGB32(x, y) BBRGB32_BLEND_PIXEL_CLAMPED(bb, bb_rotation, x, y, bb_width, bb_height, &color);

#define BB8_SET_ALL_QUADRANTS(x0, y0, x1, y1)      \
    setPixelAA_BB8(off_x+w-r-1+x1,off_y+r+y1);     \
    setPixelAA_BB8(off_x+r+x0,    off_y+r+y1);     \
    setPixelAA_BB8(off_x+r+x0,    off_y+h-r-1+y0); \
    setPixelAA_BB8(off_x+w-r-1+x1,off_y+h-r-1+y0);

#define BB8A_SET_ALL_QUADRANTS(x0, y0, x1, y1)      \
    setPixelAA_BB8A(off_x+w-r-1+x1,off_y+r+y1);     \
    setPixelAA_BB8A(off_x+r+x0,    off_y+r+y1);     \
    setPixelAA_BB8A(off_x+r+x0,    off_y+h-r-1+y0); \
    setPixelAA_BB8A(off_x+w-r-1+x1,off_y+h-r-1+y0);

#define BBRGB16_SET_ALL_QUADRANTS(x0, y0, x1, y1)      \
    setPixelAA_BBRGB16(off_x+w-r-1+x1,off_y+r+y1);     \
    setPixelAA_BBRGB16(off_x+r+x0,    off_y+r+y1);     \
    setPixelAA_BBRGB16(off_x+r+x0,    off_y+h-r-1+y0); \
    setPixelAA_BBRGB16(off_x+w-r-1+x1,off_y+h-r-1+y0);

#define BBRGB24_SET_ALL_QUADRANTS(x0, y0, x1, y1)      \
    setPixelAA_BBRGB24(off_x+w-r-1+x1,off_y+r+y1);     \
    setPixelAA_BBRGB24(off_x+r+x0,    off_y+r+y1);     \
    setPixelAA_BBRGB24(off_x+r+x0,    off_y+h-r-1+y0); \
    setPixelAA_BBRGB24(off_x+w-r-1+x1,off_y+h-r-1+y0);

#define BBRGB32_SET_ALL_QUADRANTS(x0, y0, x1, y1)      \
    setPixelAA_BBRGB32(off_x+w-r-1+x1,off_y+r+y1);     \
    setPixelAA_BBRGB32(off_x+r+x0,    off_y+r+y1);     \
    setPixelAA_BBRGB32(off_x+r+x0,    off_y+h-r-1+y0); \
    setPixelAA_BBRGB32(off_x+w-r-1+x1,off_y+h-r-1+y0);

void BB_paint_rounded_corner_AA_1px(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int r, uint8_t c) { // draw a black anti-aliased circle with thickness 1
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const unsigned int bb_width = BB_GET_WIDTH(bb);
    const unsigned int bb_height = BB_GET_HEIGHT(bb);

    int x = -r, y = 0;
    int i, err = 2-2*r;                             // error of 1.step
    int x2, e2;
    r = 1-err;
    do {
        i = 255*abs(err-2*(x+y)-2)/r;               // get blend value of pixel

        if (bb_type == TYPE_BB8) {
            const Color8A color = { .a = c, .alpha = 255-i };
            BB8_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
        } else if (bb_type == TYPE_BB8A) {
            const Color8A color = { .a = c, .alpha = 255-i };
            BB8A_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
        } else if (bb_type == TYPE_BBRGB16) {
            const Color8A color = { .a = c, .alpha = 255-i };
            BBRGB16_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
        } else if (bb_type == TYPE_BBRGB24) {
            const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
            BBRGB24_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
        } else if (bb_type == TYPE_BBRGB32) {
            const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
            BBRGB32_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
        }
        e2 = err;
        x2 = x; // remember values
        if (err+y > 0) {
            i = 255*(err-2*x-1)/r; // outward pixel
            if (i < 256) {
                if (bb_type == TYPE_BB8) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BB8_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+1+y, (r/2)-x, -(r/2)-1-y);
                } else if (bb_type == TYPE_BB8A) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BB8A_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+1+y, (r/2)-x, -(r/2)-1-y);
                } else if (bb_type == TYPE_BBRGB16) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BBRGB16_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+1+y, (r/2)-x, -(r/2)-1-y);
                } else if (bb_type == TYPE_BBRGB24) {
                    const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                    BBRGB24_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+1+y, (r/2)-x, -(r/2)-1-y);
                } else if (bb_type == TYPE_BBRGB32) {
                    const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                    BBRGB32_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+1+y, (r/2)-x, -(r/2)-1-y);
                }
            }
            ++x;
            err += x*2+1;
        }
        if (e2+x2 <= 0) { // y step
            i = 255*(2*y+3-e2)/r; // inward pixel
            if (i < 256) {
                if (bb_type == TYPE_BB8) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BB8_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
                } else if (bb_type == TYPE_BB8A) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BB8A_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
                } else if (bb_type == TYPE_BBRGB16) {
                    const Color8A color = { .a = c, .alpha = 255-i };
                    BBRGB16_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
                } else if (bb_type == TYPE_BBRGB24) {
                    const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                    BBRGB24_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
                } else if (bb_type == TYPE_BBRGB32) {
                    const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                    BBRGB32_SET_ALL_QUADRANTS(-(r/2)+x, (r/2)+y, (r/2)-x, -(r/2)-y);
                }
            }
            ++y;
            err += y*2+1;
        }
    } while (x < 0);
}

void BB_paint_rounded_corner_AA(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h, int bw, int r, uint8_t c )
{        // draw a black anti-aliased circle with width bw
    const int bb_type = GET_BB_TYPE(bb);
    const int bb_rotation = GET_BB_ROTATION(bb);
    const unsigned int bb_width = BB_GET_WIDTH(bb);
    const unsigned int bb_height = BB_GET_HEIGHT(bb);

    int x0 = -r;
    int y0 = -r;
    int x1 = r;
    int y1 = r;

    int o_diam = 2*r; // outer diameter
    int odd_diam = o_diam&1; // odd diameter
    int a2 = 2*r-2*bw;
    int dx = 4*(o_diam-1)*o_diam*o_diam;
    int dy = 4*(odd_diam-1)*o_diam*o_diam;                // error increment
    int i = o_diam+a2;
    int err = odd_diam*o_diam*o_diam;
    int dx2, dy2, e2, ed;

    if ((bw-1)*(2*o_diam-bw) > o_diam*o_diam) {
        a2 = 0;
        bw = o_diam/2;
    }

    if (x0 > x1) {
        x0 = x1;
        x1 += o_diam;
    }        // if called with swapped points
    if (y0 > y1)
        y0 = y1;                                  // .. exchange them
    if (a2 <= 0)
        bw = o_diam;                                     // filled ellipse
    e2 = bw;
    bw = x0+bw-e2;
    dx2 = 4*(a2+2*e2-1)*a2*a2;
    dy2 = 4*(odd_diam-1)*a2*a2;
    e2 = dx2*e2;
    y0 += (o_diam+1)>>1;
    y1 = y0-odd_diam;                              // starting pixel
    int a1;
    a1 = 8*o_diam*o_diam;
    a2 = 8*a2*a2;

    do {
        for (;;) {
            if (err < 0 || x0 > x1) {
                i = x0;
                break;
            }
            i = MIN(dx,dy);
            ed = MAX(dx,dy);

            ed += 2*ed*i*i/(4*ed*ed+i*i+1)+1;// approx ed=sqrt(dx*dx+dy*dy)

            i = 255*err/ed;                             // outside anti-aliasing
            if (bb_type == TYPE_BB8) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BB8A) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8A_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB16) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BBRGB16_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB24) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB24_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB32) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB32_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            }

            if (err+dy+a1 < dx) {
                i = x0+1;
                break;
            }
            x0++;
            x1--;
            err -= dx;
            dx -= a1;  // x error increment
        }
        for (; i < bw && 2*i <= x0+x1; i++) {  // fill line pixel
            if (bb_type == TYPE_BB8) {
                const Color8A color = { .a = c, .alpha = 255 };
                BB8_SET_ALL_QUADRANTS(i, y0, x0+x1-i, y1);
            } else if (bb_type == TYPE_BB8A) {
                const Color8A color = { .a = c, .alpha = 255 };
                BB8A_SET_ALL_QUADRANTS(i, y0, x0+x1-i, y1);
            } else if (bb_type == TYPE_BBRGB16) {
                const Color8A color = { .a = c, .alpha = 255 };
                BBRGB16_SET_ALL_QUADRANTS(i, y0, x0+x1-i, y1);
            } else if (bb_type == TYPE_BBRGB24) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255};
                BBRGB24_SET_ALL_QUADRANTS(i, y0, x0+x1-i, y1);
            } else if (bb_type == TYPE_BBRGB32) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255};
                BBRGB32_SET_ALL_QUADRANTS(i, y0, x0+x1-i, y1);
            }
        }
        while (e2 > 0 && x0+x1 >= 2*bw) {               // inside anti-aliasing
            i = MIN(dx2,dy2);
            ed = MAX(dx2,dy2);

            ed += 2*ed*i*i/(4*ed*ed+i*i);                 // approximation

            i = 255-255*e2/ed;             // get intensity value by pixel error
            if (bb_type == TYPE_BB8) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8_SET_ALL_QUADRANTS(bw, y0, x0+x1-bw, y1);
            } else if (bb_type == TYPE_BB8A) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8A_SET_ALL_QUADRANTS(bw, y0, x0+x1-bw, y1);
            } else if (bb_type == TYPE_BBRGB16) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BBRGB16_SET_ALL_QUADRANTS(bw, y0, x0+x1-bw, y1);
            } else if (bb_type == TYPE_BBRGB24) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB24_SET_ALL_QUADRANTS(bw, y0, x0+x1-bw, y1);
            } else if (bb_type == TYPE_BBRGB32) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB32_SET_ALL_QUADRANTS(bw, y0, x0+x1-bw, y1);
            }
            if (e2+dy2+a2 < dx2)
                break;
            bw++;
            e2 -= dx2;
            dx2 -= a2; // x error increment
        }
        dy2 += a2;
        e2 += dy2;
        dy += a1;    // y step
        err += dy;
        y0++;
        y1--;
    } while (x0 < x1);

    if (y0-y1 <= o_diam)
    {
        if (err > dy+a1) {
            y0--;
            y1++;
            dy -= a1;
            err -= dy;
        }
        for (; y0-y1 <= o_diam; err += dy += a1) { // too early stop of flat ellipses
            i = 255*4*err/a1;  // -> finish tip of ellipse
            if (bb_type == TYPE_BB8) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BB8A) {
                const Color8A color = { .a = c, .alpha = 255-i };
                BB8A_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB16) {
            const Color8A color = { .a = c, .alpha = 255-i };
                BBRGB16_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB24) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB24_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            } else if (bb_type == TYPE_BBRGB32) {
                const ColorRGB32 color = { .r = c, .g = c, .b = c, .alpha = 255-i };
                BBRGB32_SET_ALL_QUADRANTS(x0, y0, x1, y1);
            }
            ++y0;
            --y1;
        }
    }
}
