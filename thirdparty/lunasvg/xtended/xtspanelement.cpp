#include "xtspanelement.h"
#include "layoutcontext.h"
#include "parser.h"

#include <cmath>
#include <functional>

namespace lunasvg {

// Extend LayoutShape just to have some added flags
class LayoutGlyphShape : public LayoutShape
{
public:
    LayoutGlyphShape() : LayoutShape() {}
    bool can_adjust_from_previous{true};
    bool is_decoration{false};
};


TSpanElement::TSpanElement(ElementID id)
    : GeometryElement(id)
{
}

void TSpanElement::layout(LayoutContext* context, LayoutContainer* current) const
{
    printf("UNEXPECTED call to TSpanElement::layout()\n");
}

void TSpanElement::addCurrentGroup(LayoutGroup* parent, text_state_t &text_state)
{
    if ( text_state.current_group == nullptr )
        return;
    if ( text_state.current_group->children.size() == 0 ) {
        // Don't reuse it: clean it so a new one is created with proper initial attributes
        text_state.current_group = nullptr;
        return;
    }
    double dx = text_state.current_end_x - text_state.current_start_x;
    double dy = text_state.current_end_y - text_state.current_start_y;
    if ( text_state.current_length_adjust != LengthAdjust::None ) {
        // dx is the current text length (we have laid text out horizontally,
        // any rotation will be handled by upper transforms)
        if ( dx > 0 ) {
            if ( text_state.current_length_adjust == LengthAdjust::SpacingAndGlyphs ) {
                // A single whole scale is what is expected
                double scale_x = text_state.current_adjust_text_length / dx;
                text_state.current_group->transform.scale(scale_x, 1);
            }
            else { // Spacing
                // We need to scale all advances, but not the glyphs
                double total_to_add = text_state.current_adjust_text_length - dx;
                int nb_adjustable = 0;
                bool is_first = true;
                for (auto& child : text_state.current_group->children) {
                    auto glyph = static_cast<const LayoutGlyphShape*>(child.get());
                    if ( glyph->is_decoration )
                        continue;
                    if ( !is_first && glyph->can_adjust_from_previous )
                        nb_adjustable++;
                    is_first = false;
                }
                if ( nb_adjustable > 0 ) {
                    double to_add = total_to_add / nb_adjustable;
                    double cumulative_added = 0;
                    bool is_first = true;
                    for (auto& child : text_state.current_group->children) {
                        auto glyph = static_cast<LayoutGlyphShape*>(child.get());
                        if ( glyph->is_decoration )
                            continue;
                        if ( !is_first && glyph->can_adjust_from_previous ) {
                            cumulative_added += to_add;
                        }
                        glyph->transform.translate(cumulative_added, 0);
                        is_first = false;
                    }
                }
            }
            dx = text_state.current_adjust_text_length;
        }
    }
    if ( text_state.current_text_anchor != TextAnchor::Start && text_state.current_started ) {
        // Ensure text-anchor=middle/end by just adding a translation transform to this group
        if ( text_state.current_text_anchor == TextAnchor::Middle ) {
            dx = dx / 2;
            dy = dy / 2;
        }
        text_state.current_start_x -= dx;
        text_state.current_start_y -= dy;
    }
    if ( text_state.is_vertical_rl ) {
        text_state.current_group->transform.postmultiply(Transform::rotated(90));
    }
    // We want this translation to happen after the scale above (.transtate() does premultiply)
    text_state.current_group->transform.postmultiply(Transform::translated(text_state.current_start_x, text_state.current_start_y));
    // current_group is a virtual container, that has no attribute in
    // the source - we need to set these though
    text_state.current_group->opacity = 1.0;
    text_state.current_group->masker = nullptr;
    text_state.current_group->clipper = nullptr;
    parent->addChild(std::move(text_state.current_group));
    text_state.current_group = nullptr;
    text_state.current_length_adjust = LengthAdjust::None;
}

void TSpanElement::layoutText(LayoutContext* context, LayoutGroup* parent, text_state_t &text_state) const
{
    if ( !context->hasExternalContext() || !context->getExternalContext()->text_to_paths_helper ) {
        // No external support to draw text
        return;
    }

    if (isDisplayNone())
        return;

    // Not supported / todo:
    // - list of x/y/dx/dy/rotate
    // - <textpath>: better support by walking the path
    // - Other CSS text properties: vertical-align, alignment-baseline, baseline-shift...

    LengthContext lengthContext(this);

    bool absolute_position_reset = false;
    if (has(PropertyID::X)) {
        // x= can be a list of x, see https://svgwg.org/svg2-draft/text.html#TextElementXAttribute
        // We handle only the first value (it feels it would be easy to handle others by just poping
        // after each glyph path got, but https://svgwg.org/svg2-draft/text.html#TSpanNotes shows
        // it might be more complicated).
        // This comment also applies to next properties
        LengthList xs = Parser::parseLengthList(get(PropertyID::X), AllowNegativeLengths);
        if (not xs.empty()) {
            text_state.cursor_x = lengthContext.valueForLength(xs[0], LengthMode::Width);
            absolute_position_reset = true;
        }
    }
    if (has(PropertyID::Y)) {
        LengthList ys = Parser::parseLengthList(get(PropertyID::Y), AllowNegativeLengths);
        if (not ys.empty()) {
            text_state.cursor_y = lengthContext.valueForLength(ys[0], LengthMode::Height);
            absolute_position_reset = true;
        }
    }
    if (has(PropertyID::Dx)) {
        LengthList dxs = Parser::parseLengthList(get(PropertyID::Dx), AllowNegativeLengths);
        if (not dxs.empty()) {
            if ( text_state.is_vertical_rl )
                text_state.cursor_y -= lengthContext.valueForLength(dxs[0], LengthMode::Height);
            else
                text_state.cursor_x += lengthContext.valueForLength(dxs[0], LengthMode::Width);
        }
    }
    if (has(PropertyID::Dy)) {
        LengthList dys = Parser::parseLengthList(get(PropertyID::Dy), AllowNegativeLengths);
        if (not dys.empty()) {
            if ( text_state.is_vertical_rl )
                text_state.cursor_x += lengthContext.valueForLength(dys[0], LengthMode::Width);
            else
                text_state.cursor_y += lengthContext.valueForLength(dys[0], LengthMode::Height);
        }
    }
    // Also handle any inherited single value rotate= attribute,
    // which only apply its rotation on each individual glyph
    auto rotate = Parser::parseAngle(find(PropertyID::Rotate));

    // Limited support for <textPath>: gather the path to use
    Path text_path;
    Transform text_path_transform;
    if ( id == ElementID::TextPath ) {
        if (has(PropertyID::Path)) {
             text_path = Parser::parsePath(get(PropertyID::Path));
        }
        else if (has(PropertyID::Href)) {
            auto href = Parser::parseHref(get(PropertyID::Href));
            auto ref = context->getElementById(href);
            if ( ref != nullptr && ref->isGeometry() ) {
                auto gref = (static_cast<const GeometryElement*>(ref));
                text_path = gref->path();
                text_path_transform = gref->transform();
            }
        }
        if ( text_path.points().size() < 2 ) {
            return;
        }
        absolute_position_reset = true;
    }

    auto prev_text_anchor = text_state.text_anchor;
    if (has(PropertyID::Text_Anchor)) {
        auto text_anchor = get(PropertyID::Text_Anchor);
        if (text_anchor.compare("end") == 0)
            text_state.text_anchor = TextAnchor::End;
        else if (text_anchor.compare("middle") == 0)
            text_state.text_anchor = TextAnchor::Middle;
        else if (text_anchor.compare("start") == 0)
            text_state.text_anchor = TextAnchor::Start;
    }

    // About x/y/text-anchor and when to apply text-anchor:
    // See the implementations screenshots in https://github.com/RazrFalcon/resvg/issues/237
    // We do like them and all browsers, not following the specs: if an element
    // has x/y and text-anchor middle/end, the specs say only this tspan middle/end
    // should be use to anchor it as middle/end. Most implementations use this
    // tspan AND all followup TSPAN not having x/y - which feels logical if
    // we need sub tspans for bold/italic.
    if ( absolute_position_reset ) {
        // If any of X or Y is set (but not if Dx or Dy only), the current_group
        // (containing the glyph shapes made up to now) should be positionned to
        // ensure its starting x/y and text-anchor.
        addCurrentGroup(parent, text_state);
        // (this will get us take the next 'if')
    }
    if ( text_state.current_group == nullptr ) {
        text_state.current_group = makeUnique<LayoutGroup>();
        text_state.current_started = false;
        text_state.current_text_anchor = text_state.text_anchor;
        // We don't reset text_state.current_length_adjust: it may be set on/by the upper <text>
    }

    if ( absolute_position_reset ) {
        // Onlyl handle textLength when a new position has been set
        if (has(PropertyID::TextLength)) {
            auto text_length = Parser::parseLength(get(PropertyID::TextLength), ForbidNegativeLengths, Length::Zero);
            text_state.current_adjust_text_length = lengthContext.valueForLength(text_length, LengthMode::Width);
            if ( text_state.current_adjust_text_length != 0 ) {
                auto length_adjust = get(PropertyID::LengthAdjust);
                if (length_adjust.compare("spacingAndGlyphs") == 0)
                    text_state.current_length_adjust = LengthAdjust::SpacingAndGlyphs;
                else
                    text_state.current_length_adjust = LengthAdjust::Spacing; // default
            }
        }
    }

    // Limited support for <textPath>
    if ( id == ElementID::TextPath ) {
        // We will not follow the full path. We will just draw its text along
        // a straight line in the direction of the first 2 points on the path.
        // (Rather show something even if truncated or ugly, than not showing
        // anything.)
        Point start = text_path_transform.map(text_path.points()[0]);
        text_state.cursor_x = start.x;
        text_state.cursor_y = start.y;
        Point next = text_path_transform.map(text_path.points()[1]);
        Point slope{next.x - start.x, next.y - start.y};
        auto angle = 180.0 * std::atan2(slope.y, slope.x) / 3.14159265358979323846;
        text_state.current_group->transform.rotate(angle);
        // No adjustment of any kind
        text_state.current_length_adjust = LengthAdjust::None;
        text_state.text_anchor = TextAnchor::Start;
    }

    auto prev_is_pre = text_state.is_pre;
    bool space_prop_found = false;
    if (has(PropertyID::White_Space)) {
        auto white_space = get(PropertyID::White_Space);
        if (white_space.compare("normal") == 0 || white_space.compare("nowrap") == 0 || white_space.compare("pre-line") == 0) {
            text_state.is_pre = false;
            space_prop_found = true;
        }
        else if (white_space.compare("pre") == 0 || white_space.compare("pre-wrap") == 0 || white_space.compare("break-spaces") == 0) {
            text_state.is_pre = true;
            space_prop_found = true;
        }
    }
    if ( !space_prop_found && has(PropertyID::XMLSpace) ) {
        // Legacy xml:space="preserve|default"
        auto xml_space = get(PropertyID::XMLSpace);
        if (xml_space.compare("default") == 0)
            text_state.is_pre = false;
        else if (xml_space.compare("preserve") == 0)
            text_state.is_pre = true;
    }

    // About white spaces:
    // See the implementations differences at https://commons.wikimedia.org/wiki/File:SVG_test_text_tspan_ws.svg
    // We don't strictly do as https://svgwg.org/svg2-draft/text.html#WhiteSpace
    // For example, Firefox doesn't remove newlines, but consider them as space,
    // which feels more logical.
    auto source_text = get(PropertyID::_Text_Internal);
    std::string text;
    if ( text_state.is_pre ) {
        for (char const &c: source_text) {
            if ( c == ' ' || c == '\t' ||  c == '\n' || c == '\r' ) {
                text += ' '; // replace any of the above with a space
                // (We should probably replace \r\n with a single space)
                // Looks like Firefox replaces \t with a single space
            }
            else {
                text += c;
            }
        }
    }
    else {
        bool last_was_space = text_state.last_was_space; // from previous <tspan>
        for (char const &c: source_text) {
            if ( c == ' ' || c == '\t' || c == '\n' || c == '\r' ) {
                if ( !last_was_space ) { // keep it
                    text += ' '; // replace any of the above with a space
                    last_was_space = true;
                }
                // Otherwise, consecutive space that should be ignored
            }
            else {
                text += c;
                last_was_space = false;
            }
        }
        // printf("source text: #%s#\n", source_text.c_str());
        // printf("fixed  text: #%s#\n", text.c_str());
        // We keep text_state.last_was_space untouched: only the glyphs fed will update it
    }

    double fontsize = font_size();

    if ( !text.empty() && fontsize > 0 ) {
        // (We don't 'return' if empty text or the font size is 0, as this tspan
        // may have sub-tspans with text and a non-0 font size)

        // Gather infos about the font to use to draw this text fragment
        external_font_spec_t font_spec;
        font_spec.size = fontsize;

        std::string font_family = find(PropertyID::Font_Family);
        font_spec.family = font_family.c_str();

        font_spec.italic = false;
        auto style = find(PropertyID::Font_Style);
        if (style == "italic" || style == "oblique") {
            font_spec.italic = true;
        }

        font_spec.weight = 400;
        auto weight = find(PropertyID::Font_Weight);
        if (weight == "normal") {
            font_spec.weight = 400;
        }
        else if (weight == "bold") {
            font_spec.weight = 700;
        }
        else if (weight == "lighter") {
            // Not really per CSS specs, but will do for now
            font_spec.weight = 100;
        }
        else if (weight == "bolder") {
            // Not really per CSS specs, but will do for now
            font_spec.weight = 900;
        }
        else if (!weight.empty()) {
            auto w = Parser::parseLength(weight, ForbidNegativeLengths, Length::Zero);
            if (w.isValid()) {
                int wt = w.value(100.0);
                if ( wt >= 100 && wt <= 900 )
                    font_spec.weight = wt;
            }
        }

        font_spec.features = 0; // crengine's lvfntman.h LFNT_OT_FEATURES_*
        auto variant = find(PropertyID::Font_Variant);
        if (variant == "small-caps") {
            font_spec.features = 0x00000100; // LFNT_OT_FEATURES_P_SMCP
        }

        std::string lang = find(PropertyID::Lang);
        if ( !lang.empty() ) {
            font_spec.lang = lang.c_str();
        }

        double letter_spacing = 0;
        auto letterspacing = Parser::parseLength(find(PropertyID::Letter_Spacing), AllowNegativeLengths, Length::Zero);
        if ( letterspacing.isValid() && !letterspacing.isZero() ) {
            letter_spacing = letterspacing.value(fontsize, fontsize);
        }

        auto draw_text_decoration = false;
        auto text_decoration_start_x = text_state.cursor_x;

        // This will be called for each glyph
        auto add_glyph_callback = tspan_path_callback_t([&](const char * path_d, double advance_x, double advance_y,
                                                            bool can_adjust_from_previous, unsigned int base_char) {
            auto path = Parser::parsePath(path_d);
            // printf("adding (%g %g) shape n=%d (%c %x) advance=%g\n", text_state.cursor_x, text_state.cursor_y,
            //                      path.points().size(), base_char, base_char, advance_x);
            if ( letter_spacing != 0 && text_state.current_started && can_adjust_from_previous ) {
                text_state.cursor_x += letter_spacing;
            }
            if ( base_char == ' ' && !text_state.is_pre ) {
                text_state.last_was_space = true;
            }
            else {
                text_state.last_was_space = false;
                draw_text_decoration = true;
                if ( !text_state.current_started ) {
                    text_state.current_started = true;
                    text_state.current_start_x = text_state.cursor_x;
                    text_state.current_start_y = text_state.cursor_y;
                    text_state.current_end_x = text_state.cursor_x;
                    text_state.current_end_y = text_state.cursor_y;
                }
                if ( path.points().size() > 0 ) {
                    auto shape = makeUnique<LayoutGlyphShape>();
                    shape->path = std::move(path);
                    shape->can_adjust_from_previous = can_adjust_from_previous;
                    // Firefox and Edge don't handle a transform= on a <tspan>, so we can just set ours
                    shape->transform = Transform::translated(text_state.cursor_x - text_state.current_start_x,
                                                             text_state.cursor_y - text_state.current_start_y);
                    if ( rotate.value() != 0 ) {
                        shape->transform.rotate(rotate.value());
                    }
                    // fill: sets the color of text, which works just fine with filling our shapes
                    shape->fillData = context->fillData(this);
                    // stroke: would add some boldness to the glyph, and it looks like Firefox do apply it
                    shape->strokeData = context->strokeData(this);
                    // Firefox does not ensure markers on text
                    shape->markerData = MarkerData{};
                    shape->visibility = visibility();
                    shape->clipRule = clip_rule();
                    shape->opacity = opacity();
                    shape->masker = context->getMasker(mask());
                    shape->clipper = context->getClipper(clip_path());
                    text_state.current_group->addChild(std::move(shape));
                }
            }
            text_state.cursor_x += advance_x;
            text_state.cursor_y += advance_y;
            if ( text_state.current_started && !text_state.last_was_space ) {
                // These will be used for text-anchor: middle/end. We will anchor the last non-space.
                text_state.current_end_x = text_state.cursor_x;
                text_state.current_end_y = text_state.cursor_y;
            }
        });
        // Call external text shaping service, which will call the above callbac for each glyph
        external_context_t * xcontext = context->getExternalContext();
        xcontext->text_to_paths_helper( xcontext, text.c_str(), &font_spec, add_glyph_callback );

        if ( draw_text_decoration ) {
            // This is not really per-specs (color, thickness should be picked from the
            // upper node carrying the text-decoration), but even Firefox does not really
            // do it per-specs. Anyway, better something that no underline at all.
            auto text_decoration = find(PropertyID::Text_Decoration);
            // These values should normally be asked to the font...
            // Do simpler, with hand picked values that should be fine with most fonts.
            double thickness = fontsize / 28;
            double dy;
            if ( text_decoration == "underline" ) {
                dy = fontsize * 1/10;
            }
            else if ( text_decoration == "overline" ) {
                dy = - fontsize * 7/8;
            }
            else if ( text_decoration == "line-through" ) {
                dy = - fontsize * 1/4;
            }
            else {
                draw_text_decoration = false;
            }
            if ( draw_text_decoration ) {
                auto shape = makeUnique<LayoutGlyphShape>();
                shape->is_decoration = true;
                double x_start = text_decoration_start_x - text_state.current_start_x;
                double w = text_state.cursor_x - text_decoration_start_x;
                double y = text_state.cursor_y - text_state.current_start_y + dy - thickness/2;
                Path path;
                path.rect( x_start, y, w, thickness, 0, 0 );
                shape->path = std::move(path);
                shape->fillData = context->fillData(this);
                shape->strokeData = context->strokeData(this);
                shape->markerData = MarkerData{};
                shape->visibility = visibility();
                shape->clipRule = clip_rule();
                shape->opacity = opacity();
                shape->masker = context->getMasker(mask());
                shape->clipper = context->getClipper(clip_path());
                text_state.current_group->addChild(std::move(shape));
                // This should be ok with LengthAdjust::None and LengthAdjust::SpacingAndGlyphs,
                // but it won't get the correct length with LengthAdjust::Spacing (this would
                // need some more complicated way to handle text-decoration that the simpler
                // way done above).
            }
        }
    }

    for(auto& child : children) {
        TSpanElement * tspan = dynamic_cast<TSpanElement*>(child.get());
        if ( tspan == nullptr ) {
            printf("UNEXPECTED non-tspan <tspan> child\n");
        }
        else {
            tspan->layoutText(context, parent, text_state);
        }
    }

    // Restore previous state
    text_state.text_anchor = prev_text_anchor;
    text_state.is_pre = prev_is_pre;
}

std::unique_ptr<Node> TSpanElement::clone() const
{
    // return cloneElement<TSpanElement>();
    auto clone = cloneElement<TSpanElement>();
    clone->id = id;
    return std::move(clone);
}

} // namespace lunasvg
