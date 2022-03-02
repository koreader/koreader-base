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
#define RGB_To_A(r, g, b) ((4898U*r + 9618U*g + 1869U*b) >> 14U)

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
#else
#warning "TypeOf :("
#define DIV_255(V)                                                                                   \
({                                                                                                   \
    typeof (V) _v = (V) + 128;                                                                       \
    (((_v >> 8U) + _v) >> 8U);                                                                       \
})
#endif

// NOTE: See Pillow's transpose operations, or Qt5 qMemRotate stuff for cache-efficient ways of rotating an image data buffer,
//       instead of handling the rotation per-pixel, at plotting time.
//       I have no idea if it'd be an efficient method here, since it requires an extra buffer in which to do the rotation,
//       just so that new buffer can be used for the memcpy-based fast paths...

#define BB_GET_PIXEL(bb, rotation, COLOR, x, y, pptr) \
({ \
    if (rotation == 0) { \
        *pptr = (COLOR*)(bb->data + y * bb->stride) + x; \
    } else if (rotation == 1) { \
        *pptr = (COLOR*)(bb->data + x * bb->stride) + bb->w - y - 1; \
    } else if (rotation == 2) { \
        *pptr = (COLOR*)(bb->data + (bb->h - y - 1) * bb->stride) + bb->w - x - 1; \
    } else if (rotation == 3) { \
        *pptr = (COLOR*)(bb->data + (bb->h - x - 1) * bb->stride) + y; \
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
    // Handle any target pitch properly (i.e., fetch the amount of bytes taken per pixel)...
    const int bb_type = GET_BB_TYPE(bb);
    uint8_t bpp;
    switch (bb_type) {
        case TYPE_BB8:
            bpp = 1U;
            break;
        case TYPE_BB8A:
            bpp = 2U;
            break;
        case TYPE_BBRGB16:
            bpp = 2U;
            break;
        case TYPE_BBRGB24:
            bpp = 3U;
            break;
        case TYPE_BBRGB32:
            bpp = 4U;
            break;
    }
    if (rx == 0 && rw == bb->w) {
        // Single step for contiguous scanlines
        //fprintf(stdout, "%s: Single fill paintRect\n", __FUNCTION__);
        uint8_t * restrict p = bb->data + bb->stride*ry;
        memset(p, v, bb->stride*rh);
    } else {
        // Scanline per scanline fill
        //fprintf(stdout, "%s: Scanline fill paintRect\n", __FUNCTION__);
        for (unsigned int j = ry; j < ry+rh; j++) {
            uint8_t * restrict p = bb->data + bb->stride*j + bpp*rx;
            memset(p, v, bpp*rw);
        }
    }
}

void BB_blend_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, Color8A * restrict color) {
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
                // Pixel per pixel
                //fprintf(stdout, "%s: Pixel BB8 invertRect\n", __FUNCTION__);
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
                // Pixel per pixel
                //fprintf(stdout, "%s: Pixel BB8A invertRect\n", __FUNCTION__);
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
                // Pixel per pixel
                //fprintf(stdout, "%s: Pixel BBRGB16 invertRect\n", __FUNCTION__);
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
                // Pixel per pixel
                //fprintf(stdout, "%s: Pixel BBRGB24 invertRect\n", __FUNCTION__);
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
                // Pixel per pixel
                //fprintf(stdout, "%s: Pixel BBRGB32 invertRect\n", __FUNCTION__);
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
        unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, Color8A * restrict color) {
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
