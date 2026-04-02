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
#include <mupdf/fitz/html-imp.h>

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

typedef struct story_selector {
    fz_css **rules;
    int count;
} story_selector;
static fz_css *build_selector_rule(fz_context *ctx, const char *selector) {
    const char suffix[] = " { display: none; }";
    size_t selector_len;
    size_t rule_len;
    char *rule_source;
    fz_css *css;

    if (selector == NULL || selector[0] == '\0') {
        return NULL;
    }

    selector_len = strlen(selector);
    rule_len = selector_len + sizeof(suffix);
    rule_source = malloc(rule_len);
    if (rule_source == NULL) {
        return NULL;
    }

    memcpy(rule_source, selector, selector_len);
    memcpy(rule_source + selector_len, suffix, sizeof(suffix));

    css = fz_new_css(ctx);
    if (css == NULL) {
        free(rule_source);
        return NULL;
    }

    fz_try(ctx) {
        fz_parse_css(ctx, css, rule_source, "<koreader-selector>");
    }
    fz_always(ctx) {
        free(rule_source);
    }
    fz_catch(ctx) {
        fz_drop_css(ctx, css);
        fz_rethrow(ctx);
    }

    return css;
}

static int parse_story_selector(fz_context *ctx, const char **selectors, int selector_count, story_selector *parsed) {
    int index;

    memset(parsed, 0, sizeof(*parsed));
    if (selector_count <= 0) {
        return 1;
    }

    parsed->rules = calloc((size_t)selector_count, sizeof(*parsed->rules));
    if (parsed->rules == NULL) {
        return 0;
    }
    parsed->count = selector_count;

    for (index = 0; index < selector_count; index++) {
        parsed->rules[index] = build_selector_rule(ctx, selectors[index]);
        if (parsed->rules[index] == NULL) {
            return 0;
        }
    }

    return 1;
}

static void free_story_selector(fz_context *ctx, story_selector *selector) {
    int index;

    if (selector->rules != NULL) {
        for (index = 0; index < selector->count; index++) {
            if (selector->rules[index] != NULL) {
                fz_drop_css(ctx, selector->rules[index]);
            }
        }
        free(selector->rules);
    }
    selector->rules = NULL;
    selector->count = 0;
}

static int node_matches_selector(fz_context *ctx, fz_xml *node, fz_css *css) {
    fz_css_match match;
    int matched = 0;
    int use_document_css = fz_use_document_css(ctx);

    fz_try(ctx) {
        fz_set_use_document_css(ctx, 0);
        fz_match_css(ctx, &match, NULL, css, node);
        matched = fz_get_css_match_display(&match) == DIS_NONE;
    }
    fz_always(ctx) {
        fz_set_use_document_css(ctx, use_document_css);
    }
    fz_catch(ctx) {
        fz_rethrow(ctx);
    }

    return matched;
}

static int node_matches_any_selector(fz_context *ctx, fz_xml *node, const story_selector *selectors, int selector_count) {
    int index;

    for (index = 0; index < selector_count; index++) {
        if (selectors[index].count > 0 && node_matches_selector(ctx, node, selectors[index].rules[0])) {
            return 1;
        }
    }

    return 0;
}

static fz_xml *find_first_matching_node(fz_context *ctx, fz_xml *node, const story_selector *selector) {
    fz_xml *child;
    fz_xml *match;

    if (node == NULL) {
        return NULL;
    }

    if (selector->count > 0 && node_matches_selector(ctx, node, selector->rules[0])) {
        return node;
    }

    for (child = fz_dom_first_child(ctx, node); child != NULL; child = fz_dom_next(ctx, child)) {
        match = find_first_matching_node(ctx, child, selector);
        if (match != NULL) {
            return match;
        }
    }

    return NULL;
}

static fz_xml *select_story_root(fz_context *ctx, fz_xml *search_root, const story_selector *selectors, int selector_count) {
    int index;
    fz_xml *match;

    if (search_root == NULL || selector_count == 0) {
        return search_root;
    }

    for (index = 0; index < selector_count; index++) {
        match = find_first_matching_node(ctx, search_root, &selectors[index]);
        if (match != NULL) {
            return match;
        }
    }

    return search_root;
}

static void cleanup_story_subtree(fz_context *ctx, fz_xml *node, const story_selector *unwanted_selectors, int unwanted_count) {
    fz_xml *child;
    fz_xml *next;

    if (node == NULL) {
        return;
    }

    child = fz_dom_first_child(ctx, node);
    while (child != NULL) {
        next = fz_dom_next(ctx, child);
        if (node_matches_any_selector(ctx, child, unwanted_selectors, unwanted_count)) {
            fz_dom_remove(ctx, child);
        } else {
            cleanup_story_subtree(ctx, child, unwanted_selectors, unwanted_count);
        }
        child = next;
    }
}

fz_buffer* mupdf_new_buffer_from_story_text(fz_context *ctx, const unsigned char *data, size_t len, const char *user_css, float em) {
    fz_buffer *input = NULL;
    fz_buffer *output = NULL;
    fz_output *out = NULL;
    fz_story *story = NULL;
    fz_xml *doc = NULL;

    fz_try(ctx) {
        input = fz_new_buffer(ctx, len);
        fz_append_data(ctx, input, data, len);
        story = fz_new_story(ctx, input, user_css, em, NULL);
        doc = fz_story_document(ctx, story);
        if (doc == NULL) {
            fz_throw(ctx, FZ_ERROR_GENERIC, "MuPDF story did not produce an XML document");
        }

        output = fz_new_buffer(ctx, len + 256);
        out = fz_new_output_with_buffer(ctx, output);
        fz_write_xml(ctx, doc, out, 0);
        fz_close_output(ctx, out);
        fz_drop_output(ctx, out);
        out = NULL;
    }
    fz_always(ctx) {
        if (out != NULL) {
            fz_drop_output(ctx, out);
        }
        if (story != NULL) {
            fz_drop_story(ctx, story);
        }
        if (input != NULL) {
            fz_drop_buffer(ctx, input);
        }
    }
    fz_catch(ctx) {
        if (output != NULL) {
            fz_drop_buffer(ctx, output);
            output = NULL;
        }
    }

    return output;
}

fz_buffer* mupdf_new_buffer_from_filtered_story_text(fz_context *ctx, const unsigned char *data, size_t len, const char **wanted_selectors, int wanted_count, const char **unwanted_selectors, int unwanted_count, const char *user_css, float em) {
    fz_buffer *input = NULL;
    fz_buffer *output = NULL;
    fz_output *out = NULL;
    fz_story *story = NULL;
    fz_xml *doc = NULL;
    fz_xml *body = NULL;
    fz_xml *selected = NULL;
    fz_xml *selected_clone = NULL;
    story_selector *parsed_wanted = NULL;
    story_selector *parsed_unwanted = NULL;
    int index;

    fz_try(ctx) {
        if (wanted_count > 0) {
            parsed_wanted = calloc((size_t)wanted_count, sizeof(*parsed_wanted));
            if (parsed_wanted == NULL) {
                fz_throw(ctx, FZ_ERROR_SYSTEM, "Failed to allocate wanted selector storage");
            }
            for (index = 0; index < wanted_count; index++) {
                if (!parse_story_selector(ctx, &wanted_selectors[index], 1, &parsed_wanted[index])) {
                    fz_throw(ctx, FZ_ERROR_GENERIC, "Unsupported wanted selector: %s", wanted_selectors[index]);
                }
            }
        }

        if (unwanted_count > 0) {
            parsed_unwanted = calloc((size_t)unwanted_count, sizeof(*parsed_unwanted));
            if (parsed_unwanted == NULL) {
                fz_throw(ctx, FZ_ERROR_SYSTEM, "Failed to allocate unwanted selector storage");
            }
            for (index = 0; index < unwanted_count; index++) {
                if (!parse_story_selector(ctx, &unwanted_selectors[index], 1, &parsed_unwanted[index])) {
                    fz_throw(ctx, FZ_ERROR_GENERIC, "Unsupported unwanted selector: %s", unwanted_selectors[index]);
                }
            }
        }

        input = fz_new_buffer(ctx, len);
        fz_append_data(ctx, input, data, len);
        story = fz_new_story(ctx, input, user_css, em, NULL);
        doc = fz_story_document(ctx, story);
        if (doc == NULL) {
            fz_throw(ctx, FZ_ERROR_GENERIC, "MuPDF story did not produce an XML document");
        }

        body = fz_dom_body(ctx, doc);
        if (body == NULL) {
            body = fz_dom_document_element(ctx, doc);
        }
        if (body == NULL) {
            body = doc;
        }

        selected = select_story_root(ctx, body, parsed_wanted, wanted_count);
        cleanup_story_subtree(ctx, selected, parsed_unwanted, unwanted_count);

        output = fz_new_buffer(ctx, len + 256);
        out = fz_new_output_with_buffer(ctx, output);
        selected_clone = fz_dom_clone(ctx, selected);
        if (selected_clone == NULL) {
            fz_throw(ctx, FZ_ERROR_GENERIC, "MuPDF story did not clone selected XML node");
        }
        fz_write_xml(ctx, selected_clone, out, 0);
        fz_close_output(ctx, out);
        fz_drop_output(ctx, out);
        out = NULL;
    }
    fz_always(ctx) {
        if (parsed_wanted != NULL) {
            for (index = 0; index < wanted_count; index++) {
                free_story_selector(ctx, &parsed_wanted[index]);
            }
            free(parsed_wanted);
        }
        if (parsed_unwanted != NULL) {
            for (index = 0; index < unwanted_count; index++) {
                free_story_selector(ctx, &parsed_unwanted[index]);
            }
            free(parsed_unwanted);
        }
        if (out != NULL) {
            fz_drop_output(ctx, out);
        }
        if (story != NULL) {
            fz_drop_story(ctx, story);
        }
        if (input != NULL) {
            fz_drop_buffer(ctx, input);
        }
    }
    fz_catch(ctx) {
        if (output != NULL) {
            fz_drop_buffer(ctx, output);
            output = NULL;
        }
    }

    return output;
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
