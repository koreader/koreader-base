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
#include "blitbuffer.h"

#define MASK_TYPE 0xF0
#define SHIFT_TYPE 4
#define TYPE_BB4 0
#define TYPE_BB8 1
#define TYPE_BB8A 2
#define TYPE_BBRGB16 3
#define TYPE_BBRGB24 4
#define TYPE_BBRGB32 5

#define ColorRGB32_To_Color8(color) \
    (Color8){(4897*color->r + 9617*color->g + 1868*color->b) >> 14}
#define ColorRGB32_To_Color8A(color) \
    (Color8A){(4897*color->r + 9617*color->g + 1868*color->b) >> 14, color->alpha}
#define ColorRGB32_To_Color16(color) \
    (ColorRGB16){((color->r & 0xF8) << 8) + ((color->g & 0xFC) << 3) + ((color->b >> 3))}
#define ColorRGB32_To_Color24(color) \
    (ColorRGB24){color->r, color->g, color->b}

#define ColorRGB16_GetR(v) (((v >> 11) << 3) + ((v >> 11) >> 2))
#define ColorRGB16_GetG(v) (((v >> 5 & 0x3F) << 2) + ((v >> 5 & 0x3F) >> 4))
#define ColorRGB16_GetB(v) (((v & 0x001F) << 3) + ((v & 0x001F) >> 2))
#define ColorRGB16_To_A(v) \
    ((39190*ColorRGB16_GetR(v) + \
      38469*ColorRGB16_GetG(v) + \
      14942*ColorRGB16_GetB(v)) >> 14)
#define RGB_To_RGB16(r, g, b) (((r & 0xF8) << 8) + ((g & 0xFC) << 3) + (b >> 3))
#define RGB_To_A(r, g, b) ((4897*r + 9617*g + 1868*b) >> 14)
#define DIV_255(x) (((x) + 0x01 + (((x) + 0x01) >> 8)) >> 8)
#define GET_BB_TYPE(bb) (((MASK_TYPE & bb->config) >> SHIFT_TYPE))
#define SET_ALPHA_FROM_A(sbb_type, src) \
    if (sbb_type == TYPE_BB8) { \
        Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x; \
        alpha = srcptr->a; \
    } else if (sbb_type == TYPE_BB8A) { \
        Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x; \
        alpha = srcptr->a; \
    } else if (sbb_type == TYPE_BBRGB16) { \
        ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x; \
        alpha = ColorRGB16_To_A(srcptr->v); \
    } else if (sbb_type == TYPE_BBRGB24) { \
        ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x; \
        alpha = RGB_To_A(srcptr->r, srcptr->g, srcptr->b); \
    } else if (sbb_type == TYPE_BBRGB32) { \
        ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x; \
        alpha = RGB_To_A(srcptr->r, srcptr->g, srcptr->b); \
    }
#define FILL_COLOR(COLOR, c) \
    for (i = x; i < x + w; i++) { \
        for (j = y; j < y + h; j++) { \
            COLOR *dstptr = (COLOR*)(bb->data) + (j * bb->w) + i; \
            *dstptr = c; \
        } \
    }


void BB_fill_rect(BlitBuffer *bb, int x, int y, int w, int h, ColorRGB32 *color) {
    int bb_type = GET_BB_TYPE(bb);
    int i, j;
    if (bb_type == TYPE_BB8) {
        FILL_COLOR(Color8, ColorRGB32_To_Color8(color));
    } else if (bb_type == TYPE_BB8A) {
        FILL_COLOR(Color8A, ColorRGB32_To_Color8A(color));
    } else if (bb_type == TYPE_BBRGB16) {
        FILL_COLOR(ColorRGB16, ColorRGB32_To_Color16(color));
    } else if (bb_type == TYPE_BBRGB24) {
        FILL_COLOR(ColorRGB24, ColorRGB32_To_Color24(color));
    } else if (bb_type == TYPE_BBRGB32) {
        FILL_COLOR(ColorRGB32, *color);
    }
}

void BB_blend_rect(BlitBuffer *bb, int x, int y, int w, int h, ColorRGB32 *color) {
    int i, j;
    uint8_t r, g, b;
    int bb_type = GET_BB_TYPE(bb);
    uint8_t alpha = color->alpha;
    uint8_t ainv = 0xFF - alpha;
    if (bb_type == TYPE_BB8) {
        for (i = x; i < x + w; i++) {
            for (j = y; j < y + h; j++) {
                Color8 *dstptr = (Color8*)(bb->data) + (j * bb->w) + i;
                dstptr->a = DIV_255(dstptr->a * ainv + color->r * alpha);
            }
        }
    } else if (bb_type == TYPE_BB8A) {
        for (i = x; i < x + w; i++) {
            for (j = y; j < y + h; j++) {
                Color8A *dstptr = (Color8A*)(bb->data) + (j * bb->w) + i;
                dstptr->a = DIV_255(dstptr->a * ainv + color->r * alpha);
            }
        }
    } else if (bb_type == TYPE_BBRGB16) {
        for (i = x; i < x + w; i++) {
            for (j = y; j < y + h; j++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(bb->data) + (j * bb->w) + i;
                r = DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->r * alpha);
                g = DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->g * alpha);
                b = DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->b * alpha);
                dstptr->v = RGB_To_RGB16(r, g, b);
            }
        }
    } else if (bb_type == TYPE_BBRGB24) {
        for (i = x; i < x + w; i++) {
            for (j = y; j < y + h; j++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(bb->data) + (j * bb->w) + i;
                dstptr->r = DIV_255(dstptr->r * ainv + color->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + color->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + color->b * alpha);
            }
        }
    } else if (bb_type == TYPE_BBRGB32) {
        for (i = x; i < x + w; i++) {
            for (j = y; j < y + h; j++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(bb->data) + (j * bb->w) + i;
                dstptr->r = DIV_255(dstptr->r * ainv + color->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + color->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + color->b * alpha);
            }
        }
    }
}

void BB_blit_to_BB8(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int d_x, d_y, o_x, o_y;
    int sbb_type = GET_BB_TYPE(src);
    if (sbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = ColorRGB16_To_A(srcptr->v);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_blit_to_BB8A(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int d_x, d_y, o_x, o_y;
    int sbb_type = GET_BB_TYPE(src);
    if (sbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = ColorRGB16_To_A(srcptr->v);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = RGB_To_A(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_blit_to_BB16(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int d_x, d_y, o_x, o_y;
    uint8_t v, v5bit;
    int sbb_type = GET_BB_TYPE(src);
    if (sbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                v = srcptr->a;
                v5bit = v >> 3;
                dstptr->v = (v5bit << 11) + ((v & 0xFC) << 3) + v5bit;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                v = srcptr->a;
                v5bit = v >> 3;
                dstptr->v = (v5bit << 11) + ((v & 0xFC) << 3) + v5bit;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x;
                dstptr->v = RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->v = RGB_To_RGB16(srcptr->r, srcptr->g, srcptr->b);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_blit_to_BB24(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int d_x, d_y, o_x, o_y;
    uint8_t v, v5bit;
    int sbb_type = GET_BB_TYPE(src);
    if (sbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->a;
                dstptr->g = srcptr->a;
                dstptr->b = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->a;
                dstptr->g = srcptr->a;
                dstptr->b = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = ColorRGB16_GetR(srcptr->v);
                dstptr->g = ColorRGB16_GetG(srcptr->v);
                dstptr->b = ColorRGB16_GetB(srcptr->v);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->r;
                dstptr->g = srcptr->g;
                dstptr->b = srcptr->b;
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_blit_to_BB32(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int d_x, d_y, o_x, o_y;
    uint8_t v, v5bit;
    int sbb_type = GET_BB_TYPE(src);
    if (sbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->a;
                dstptr->g = srcptr->a;
                dstptr->b = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->a;
                dstptr->g = srcptr->a;
                dstptr->b = srcptr->a;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = ColorRGB16_GetR(srcptr->v);
                dstptr->g = ColorRGB16_GetG(srcptr->v);
                dstptr->b = ColorRGB16_GetB(srcptr->v);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB24 *srcptr = (ColorRGB24*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->r;
                dstptr->g = srcptr->g;
                dstptr->b = srcptr->b;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (sbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_blit_to(BlitBuffer *src, BlitBuffer *dst,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int dbb_type = GET_BB_TYPE(dst);
    // fprintf(stdout, "blit from type: %d to: %d\n", GET_BB_TYPE(src), GET_BB_TYPE(dst));
    if (dbb_type == TYPE_BB8) {
        BB_blit_to_BB8(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    } else if (dbb_type == TYPE_BB8A) {
        BB_blit_to_BB8A(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    } else if (dbb_type == TYPE_BBRGB16) {
        BB_blit_to_BB16(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    } else if (dbb_type == TYPE_BBRGB24) {
        BB_blit_to_BB24(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    } else if (dbb_type == TYPE_BBRGB32) {
        BB_blit_to_BB32(src, dst, dest_x, dest_y, offs_x, offs_y, w, h);
    }
}

void BB_add_blit_from(BlitBuffer *dst, BlitBuffer *src,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h,
        uint8_t alpha) {
    int dbb_type = GET_BB_TYPE(dst);
    int sbb_type = GET_BB_TYPE(src);
    if (dbb_type != sbb_type) {
        fprintf(stderr, "incompatible bb in file %s, line %d!\r\n",
                __FILE__, __LINE__); exit(1);
    }
    uint8_t r, g, b;
    uint8_t ainv = 0xFF - alpha;
    int d_x, d_y, o_x, o_y;
    if (dbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = DIV_255(dstptr->a * ainv + srcptr->a * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                r = DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + ColorRGB16_GetR(srcptr->v) * alpha);
                g = DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + ColorRGB16_GetG(srcptr->v) * alpha);
                b = DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + ColorRGB16_GetB(srcptr->v) * alpha);
                dstptr->v = RGB_To_RGB16(r, g, b);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_alpha_blit_from(BlitBuffer *dst, BlitBuffer *src,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int dbb_type = GET_BB_TYPE(dst);
    int sbb_type = GET_BB_TYPE(src);
    if (dbb_type != sbb_type) {
        fprintf(stderr, "incompatible bb in file %s, line %d!\r\n",
                __FILE__, __LINE__); exit(1);
    }
    uint8_t r, g, b, ainv, alpha;
    int d_x, d_y, o_x, o_y;
    if (dbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                alpha = srcptr->alpha;
                ainv = 0xFF - alpha;
                dstptr->a = dstptr->a * ainv + srcptr->a * alpha;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                *dstptr = *srcptr;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                alpha = srcptr->alpha;
                ainv = 0xFF - alpha;
                dstptr->r = DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                alpha = srcptr->alpha;
                ainv = 0xFF - alpha;
                dstptr->r = DIV_255(dstptr->r * ainv + srcptr->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + srcptr->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + srcptr->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_invert_blit_from(BlitBuffer *dst, BlitBuffer *src,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h) {
    int dbb_type = GET_BB_TYPE(dst);
    int sbb_type = GET_BB_TYPE(src);
    if (dbb_type != sbb_type) {
        fprintf(stderr, "incompatible bb in file %s, line %d!\r\n",
                __FILE__, __LINE__); exit(1);
    }
    int d_x, d_y, o_x, o_y;
    if (dbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                Color8 *srcptr = (Color8*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = srcptr->a ^ 0xFF;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                Color8A *dstptr = (Color8A*)(dst->data) + (d_y * dst->w) + d_x;
                Color8A *srcptr = (Color8A*)(src->data) + (o_y * src->w) + o_x;
                dstptr->a = srcptr->a ^ 0xFF;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB16 *srcptr = (ColorRGB16*)(src->data) + (o_y * src->w) + o_x;
                dstptr->v = srcptr->v ^ 0xFFFF;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->r ^ 0xFF;
                dstptr->g = srcptr->g ^ 0xFF;
                dstptr->b = srcptr->b ^ 0xFF;
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ColorRGB32 *srcptr = (ColorRGB32*)(src->data) + (o_y * src->w) + o_x;
                dstptr->r = srcptr->r ^ 0xFF;
                dstptr->g = srcptr->g ^ 0xFF;
                dstptr->b = srcptr->b ^ 0xFF;
                o_y += 1;
            }
            o_x += 1;
        }
    }
}

void BB_color_blit_from(BlitBuffer *dst, BlitBuffer *src,
        int dest_x, int dest_y, int offs_x, int offs_y, int w, int h, ColorRGB32 *color) {
    uint8_t r, g, b, ainv, alpha;
    int d_x, d_y, o_x, o_y;

    if (src->w == 0 || src->h == 0) return;
    int dbb_type = GET_BB_TYPE(dst);
    int sbb_type = GET_BB_TYPE(src);
    if (dbb_type == TYPE_BB8) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                SET_ALPHA_FROM_A(sbb_type, src)
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                ainv = 0xFF - alpha;
                dstptr->a = DIV_255(dstptr->a * ainv + color->r * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BB8A) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                SET_ALPHA_FROM_A(sbb_type, src)
                Color8 *dstptr = (Color8*)(dst->data) + (d_y * dst->w) + d_x;
                ainv = 0xFF - alpha;
                dstptr->a = DIV_255(dstptr->a * ainv + color->r * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB16) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                SET_ALPHA_FROM_A(sbb_type, src)
                ColorRGB16 *dstptr = (ColorRGB16*)(dst->data) + (d_y * dst->w) + d_x;
                ainv = 0xFF - alpha;
                r = DIV_255(ColorRGB16_GetR(dstptr->v) * ainv + color->r * alpha);
                g = DIV_255(ColorRGB16_GetG(dstptr->v) * ainv + color->g * alpha);
                b = DIV_255(ColorRGB16_GetB(dstptr->v) * ainv + color->b * alpha);
                dstptr->v = RGB_To_RGB16(r, g, b);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB24) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                SET_ALPHA_FROM_A(sbb_type, src)
                ColorRGB24 *dstptr = (ColorRGB24*)(dst->data) + (d_y * dst->w) + d_x;
                ainv = 0xFF - alpha;
                dstptr->r = DIV_255(dstptr->r * ainv + color->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + color->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + color->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    } else if (dbb_type == TYPE_BBRGB32) {
        o_x = offs_x;
        for (d_x = dest_x; d_x < dest_x + w; d_x++) {
            o_y = offs_y;
            for (d_y = dest_y; d_y < dest_y + h; d_y++) {
                SET_ALPHA_FROM_A(sbb_type, src)
                ColorRGB32 *dstptr = (ColorRGB32*)(dst->data) + (d_y * dst->w) + d_x;
                ainv = 0xFF - alpha;
                dstptr->r = DIV_255(dstptr->r * ainv + color->r * alpha);
                dstptr->g = DIV_255(dstptr->g * ainv + color->g * alpha);
                dstptr->b = DIV_255(dstptr->b * ainv + color->b * alpha);
                o_y += 1;
            }
            o_x += 1;
        }
    }
}
