#ifndef XLUNASVG_H
#define XLUNASVG_H

#include <functional>

namespace lunasvg {

typedef struct external_context_t external_context_t;

// Font specification, given to external text to glyph SVG paths converter
typedef struct external_font_spec_t {
    const char * family = nullptr;
    double size = 16;
    short weight = 400;
    bool italic = false;
    unsigned int features = 0;
    const char * lang = nullptr;
} external_font_spec_t;

// Prototype of callback (defined in xtspanelement.cpp) to receive SVG paths for each glyph
typedef std::function<void(const char * path_d, double advance_x, double advance_y, bool can_adjust_from_previous, unsigned int base_char)> tspan_path_callback_t;

// Prototype of external helper function called to convert text to glyph SVG paths
typedef void (*external_text_to_paths_func_t)( external_context_t * xcontext, const char * text,
                                external_font_spec_t * font_spec, tspan_path_callback_t callback );

// Prototype of external helper function called to decode an image (url, "data:image...") and draw it onto the provided bitmap
typedef bool (*external_draw_image_func_t)( external_context_t * xcontext, const char * url,
                                const unsigned char * bitmap, int width, int height, double & original_aspect_ratio) ;

// External context struct that can be provided to loadFromData() to get text and image support,
// and give additional context about the SVG image and its target document/page/canvas.
struct external_context_t {
    // Pointer to any external object, so helper funcs can find and use it if needed
    void * external_object = nullptr;

    // Helper function to convert text to glyph SVG paths
    external_text_to_paths_func_t text_to_paths_helper = nullptr;

    // Helper function to decode an image (url, "data:image...") and draw it onto the provided bitmap
    external_draw_image_func_t draw_image_helper = nullptr;

    // Allow overridding SVG original size, so external engine does not need to rescale it and can get the best quality
    int target_width = -1;
    int target_height = -1;

};

} //namespace lunasvg

#endif // XLUNASVG_H
