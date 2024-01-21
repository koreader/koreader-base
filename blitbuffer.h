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
#ifndef _BLITBUFFER_H
#define _BLITBUFFER_H

#include <stddef.h>
#include <stdint.h>

// Symbol visibility
#define DLL_PUBLIC __attribute__((visibility("default")))
#define DLL_LOCAL  __attribute__((visibility("hidden")))

// In C++, restrict is a compiler extension. Choose the syntax supported by GCC, Clang & MSVC.
#ifdef __cplusplus
#	define restrict __restrict
#endif

// Helper macros
#define MASK_INVERSE 0x02
#define SHIFT_INVERSE 1
#define MASK_ROTATED 0x0C
#define SHIFT_ROTATED 2
#define MASK_TYPE 0xF0
#define SHIFT_TYPE 4
#define TYPE_BB4 0
#define TYPE_BB8 1
#define TYPE_BB8A 2
#define TYPE_BBRGB16 3
#define TYPE_BBRGB24 4
#define TYPE_BBRGB32 5

#define GET_BB_INVERSE(bb) ((MASK_INVERSE & bb->config) >> SHIFT_INVERSE)
#define GET_BB_ROTATION(bb) ((MASK_ROTATED & bb->config) >> SHIFT_ROTATED)
#define GET_BB_TYPE(bb) (((MASK_TYPE & bb->config) >> SHIFT_TYPE))

// Types
typedef struct Color8 {
    uint8_t a;
} Color8;

typedef struct Color8A {
    uint8_t a;
    uint8_t alpha;
} Color8A;

typedef struct ColorRGB16 {
    uint16_t v;
} ColorRGB16;

typedef struct ColorRGB24 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} ColorRGB24;

typedef struct ColorRGB32 {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t alpha;
} ColorRGB32;

typedef struct BlitBuffer {
    unsigned int w;
    unsigned int pixel_stride;  // nb of pixels from the start of a line to the start of next line
    unsigned int h;
    size_t stride;              // nb of bytes from the start of a line to the start of next line
    uint8_t * restrict data;
    uint8_t config;
} BlitBuffer;

typedef struct BlitBuffer8 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    Color8 * restrict data;
    uint8_t config;
} BlitBuffer8;

typedef struct BlitBuffer8A {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    Color8A * restrict data;
    uint8_t config;
} BlitBuffer8A;

typedef struct BlitBufferRGB16 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB16 * restrict data;
    uint8_t config;
} BlitBufferRGB16;

typedef struct BlitBufferRGB24 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB24 * restrict data;
    uint8_t config;
} BlitBufferRGB24;

typedef struct BlitBufferRGB32 {
    unsigned int w;
    unsigned int pixel_stride;
    unsigned int h;
    size_t stride;
    ColorRGB32 * restrict data;
    uint8_t config;
} BlitBufferRGB32;

DLL_PUBLIC void BB_fill(BlitBuffer * restrict bb, uint8_t v);
DLL_PUBLIC void BB_fill_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, uint8_t v);
DLL_PUBLIC void BB_fill_rect_RGB32(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
DLL_PUBLIC void BB_blend_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const Color8A * restrict color);
DLL_PUBLIC void BB_blend_RGB32_over_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
DLL_PUBLIC void BB_blend_RGB_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB24 * restrict color);
DLL_PUBLIC void BB_blend_RGB32_multiply_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
DLL_PUBLIC void BB_invert_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_hatch_rect(BlitBuffer * restrict bb, unsigned int x, unsigned int y, unsigned int w, unsigned int h, unsigned int stripe_width, const Color8 * restrict color, uint8_t alpha);
DLL_PUBLIC void BB_blit_to_BB8(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                    unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_dither_blit_to_BB8(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                    unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_blit_to_BB8A(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                     unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_blit_to_BB16(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                     unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_blit_to_BB24(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                     unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_blit_to_BB32(const BlitBuffer * restrict src, BlitBuffer * restrict dst,
                     unsigned int dest_x, unsigned int dest_y, unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_blit_to(const BlitBuffer * restrict source, BlitBuffer * restrict dest, unsigned int dest_x, unsigned int dest_y,
                unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_dither_blit_to(const BlitBuffer * restrict source, BlitBuffer * restrict dest, unsigned int dest_x, unsigned int dest_y,
                unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_add_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                      unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, uint8_t alpha);
DLL_PUBLIC void BB_alpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_dither_alpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_pmulalpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_dither_pmulalpha_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_invert_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                         unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h);
DLL_PUBLIC void BB_color_blit_from(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const Color8A * restrict color);
DLL_PUBLIC void BB_color_blit_from_RGB32(BlitBuffer * restrict dest, const BlitBuffer * restrict source, unsigned int dest_x, unsigned int dest_y,
                        unsigned int offs_x, unsigned int offs_y, unsigned int w, unsigned int h, const ColorRGB32 * restrict color);
DLL_PUBLIC void BB_paint_rounded_corner(BlitBuffer * restrict bb, unsigned int off_x, unsigned int off_y, unsigned int w, unsigned int h,
                        unsigned int bw, unsigned int r, uint8_t c, int anti_aliasing);
#endif
