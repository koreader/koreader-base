/*
    KindlePDFViewer: MuPDF abstraction for Lua
    Copyright (C) 2011 Hans-Werner Hilse <hilse@web.de>

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
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include <string.h>
#include "wrap-mupdf.h"

static double LOG_TRESHOLD_PERC = 0.05; // 5%

enum {
    MAGIC = 0x3795d42b,
};

typedef struct header {
    int magic;
    size_t sz;
} header;

static size_t msize = 0U;
static size_t msize_prev;
static size_t msize_max;
static size_t msize_min;
static bool is_realloc = false;

#if 0
static size_t msize_iniz;

static void resetMsize() {
    msize_iniz = msize;
    msize_prev = 0;
    msize_max = 0;
    msize_min = (size_t) -1;
}

static void showMsize() {
    char buf[15], buf2[15], buf3[15], buf4[15];
    //printf("§§§ now: %s was: %s - min: %s - max: %s\n", readable_fs(msize, buf), readable_fs(msize_iniz, buf2), readable_fs(msize_min, buf3), readable_fs(msize_max, buf4));
    resetMsize();
}
#endif

static void log_size(char *funcName) {
    if (msize_max < msize) {
        msize_max = msize;
    }
    if (msize_min > msize) {
        msize_min = msize;
    }
    if (1==0 && abs(msize - msize_prev) > msize_prev * LOG_TRESHOLD_PERC) {
        //char buf[15], buf2[15];
        //printf("§§§ %s - total: %s (was %s)\n",funcName, readable_fs(msize,buf),readable_fs(msize_prev,buf2));
        msize_prev = msize;
    }
}

static void *
my_malloc_default(void *opaque, size_t size)
{
    struct header * h = malloc(size + sizeof(header));
    if (h == NULL) {
        return NULL;
    }

    h->magic = MAGIC;
    h->sz = size;
    msize += size + sizeof(struct header);
    if (!is_realloc) {
        log_size("alloc");
    }
    return (void *)(h + 1);
}

static void
my_free_default(void *opaque, void *ptr)
{
    fprintf(stderr, "free %p (%zu)\n", ptr, msize);
    if (ptr != NULL) {
        struct header * h = ((struct header *)ptr) - 1;
        if (h->magic != MAGIC) { /* Not allocated by us */
            fprintf(stderr, "attempt to free something that doesn't belong to us!\n");
        } else {
            msize -= h->sz + sizeof(struct header);
            free(h);
        }
    }
    if (!is_realloc) {
        log_size("free");
    }
}

static void *
my_realloc_default(void *opaque, void *old, size_t size)
{
    void * newp;
    if (old == NULL) { //practically, it's a malloc
        newp = my_malloc_default(opaque, size);
    } else {
        struct header * h = ((struct header *)old) - 1;
        if (h->magic != MAGIC) { // Not allocated by my_malloc_default
            //printf("§§§ warn: not allocated by my_malloc_default, new size: %zu\n", size);
            newp = realloc(old, size);
        } else { // malloc + free
            is_realloc = true;
            size_t oldsize = h->sz;
            //printf("realloc %zu -> %zu\n", oldsize, size);
            newp = my_malloc_default(opaque, size);
            if (NULL != newp) {
                memcpy(newp, old, oldsize < size ? oldsize : size);
                my_free_default(opaque, old);
            }
            log_size("realloc");
            is_realloc = false;
        }
    }

    return(newp);
}

fz_alloc_context my_alloc_default =
{
    NULL,
    my_malloc_default,
    my_realloc_default,
    my_free_default
};

fz_alloc_context* mupdf_get_my_alloc_context() {
    return &my_alloc_default;
}

int mupdf_get_cache_size() {
    return msize;
}

int mupdf_error_code(fz_context *ctx) {
    return ctx->error.errcode;
}
char* mupdf_error_message(fz_context *ctx) {
    return ctx->error.message;
}

fz_matrix *mupdf_fz_scale(fz_matrix *m, float sx, float sy) {
    *m = fz_scale(sx, sy);
    return m;
}

fz_matrix *mupdf_fz_translate(fz_matrix *m, float tx, float ty) {
    *m = fz_translate(tx, ty);
    return m;
}

fz_matrix *mupdf_fz_pre_rotate(fz_matrix *m, float theta) {
    *m = fz_pre_rotate(*m, theta);
    return m;
}

fz_matrix *mupdf_fz_pre_translate(fz_matrix *m, float tx, float ty) {
    *m = fz_pre_translate(*m, tx, ty);
    return m;
}

fz_rect *mupdf_fz_transform_rect(fz_rect *r, const fz_matrix *m) {
    *r = fz_transform_rect(*r, *m);
    return r;
}

fz_irect *mupdf_fz_round_rect(fz_irect *ir, const fz_rect *r) {
    *ir = fz_round_rect(*r);
    return ir;
}

fz_rect *mupdf_fz_union_rect(fz_rect *a, const fz_rect *b) {
    *a = fz_union_rect(*a, *b);
    return a;
}

fz_rect *mupdf_fz_rect_from_quad(fz_rect *r, const fz_quad *q) {
    *r = fz_rect_from_quad(*q);
    return r;
}

fz_rect *mupdf_fz_bound_page(fz_context *ctx, fz_page *page, fz_rect *r) {
    *r = fz_bound_page(ctx, page);
    return r;
}

/* wrappers for functions that throw exceptions mupdf-style (setjmp/longjmp) */

#define MUPDF_DO_WRAP
#include "wrap-mupdf.h"
