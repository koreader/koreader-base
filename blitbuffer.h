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

#include <stdint.h>

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
    int w;
    int pixel_stride;   // nb of pixels from the start of a line to the start of next line
    int h;
    int stride;         // nb of bytes from the start of a line to the start of next line
    uint8_t *data;
    uint8_t config;
} BlitBuffer;

typedef struct BlitBuffer8 {
    int w;
    int pixel_stride;
    int h;
    int stride;
    Color8 *data;
    uint8_t config;
} BlitBuffer8;

typedef struct BlitBuffer8A {
    int w;
    int pixel_stride;
    int h;
    int stride;
    Color8A *data;
    uint8_t config;
} BlitBuffer8A;

typedef struct BlitBufferRGB16 {
    int w;
    int pixel_stride;
    int h;
    int stride;
    ColorRGB16 *data;
    uint8_t config;
} BlitBufferRGB16;

typedef struct BlitBufferRGB24 {
    int w;
    int pixel_stride;
    int h;
    int stride;
    ColorRGB24 *data;
    uint8_t config;
} BlitBufferRGB24;

typedef struct BlitBufferRGB32 {
    int w;
    int pixel_stride;
    int h;
    int stride;
    ColorRGB32 *data;
    uint8_t config;
} BlitBufferRGB32;

void BB_fill_rect(BlitBuffer *bb, int x, int y, int w, int h, uint8_t v);
void BB_blend_rect(BlitBuffer *bb, int x, int y, int w, int h, Color8A *color);
void BB_invert_rect(BlitBuffer *bb, int x, int y, int w, int h);
void BB_blit_to_BB8(BlitBuffer *src, BlitBuffer *dst,
                    int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_dither_blit_to_BB8(BlitBuffer *src, BlitBuffer *dst,
                    int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_blit_to_BB8A(BlitBuffer *src, BlitBuffer *dst,
                     int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_blit_to_BB16(BlitBuffer *src, BlitBuffer *dst,
                     int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_blit_to_BB24(BlitBuffer *src, BlitBuffer *dst,
                     int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_blit_to_BB32(BlitBuffer *src, BlitBuffer *dst,
                     int dest_x, int dest_y, int offs_x, int offs_y, int w, int h);
void BB_blit_to(BlitBuffer *source, BlitBuffer *dest, int dest_x, int dest_y,
                int offs_x, int offs_y, int w, int h);
void BB_dither_blit_to(BlitBuffer *source, BlitBuffer *dest, int dest_x, int dest_y,
                int offs_x, int offs_y, int w, int h);
void BB_add_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                      int offs_x, int offs_y, int w, int h, uint8_t alpha);
void BB_alpha_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                        int offs_x, int offs_y, int w, int h);
void BB_pmulalpha_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                        int offs_x, int offs_y, int w, int h);
void BB_dither_pmulalpha_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                        int offs_x, int offs_y, int w, int h);
void BB_invert_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                         int offs_x, int offs_y, int w, int h);
void BB_color_blit_from(BlitBuffer *dest, BlitBuffer *source, int dest_x, int dest_y,
                        int offs_x, int offs_y, int w, int h, Color8A *color);
#endif
