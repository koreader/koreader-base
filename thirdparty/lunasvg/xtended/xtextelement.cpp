#include "xtextelement.h"
#include "xtspanelement.h"
#include "layoutcontext.h"
#include "parser.h"

namespace lunasvg {

TextElement::TextElement()
    : GraphicsElement(ElementID::Text)
{
}

void TextElement::layout(LayoutContext* context, LayoutContainer* current) const
{
    if ( !context->hasExternalContext() || !context->getExternalContext()->text_to_paths_helper ) {
        // No external support to draw text
        return;
    }

    if (isDisplayNone())
        return;

    if ( has(PropertyID::_Text_Internal) ) {
        // <text> shouldn't have any text: we have put it into an added <tspan>
        printf("UNEXPECTED <text> text string: %s\n", get(PropertyID::_Text_Internal).c_str());
    }

    // This text drawing state will be passed to/by all sub-<tspans>
    text_state_t text_state;
    text_state.cursor_x = 0;
    text_state.cursor_y = 0;
    text_state.current_group = nullptr;
    text_state.current_started = false;
    text_state.current_length_adjust = LengthAdjust::None;
    text_state.last_was_space = true; // so that leading spaces will be stripped
    text_state.is_pre = false;
    text_state.is_vertical_rl = false;

    LengthContext lengthContext(this);
    if (has(PropertyID::X)) {
        // x= can be a list of x, see https://svgwg.org/svg2-draft/text.html#TextElementXAttribute
        // We handle only the first value
        LengthList xs = Parser::parseLengthList(get(PropertyID::X), AllowNegativeLengths);
        if (not xs.empty()) {
            text_state.cursor_x = lengthContext.valueForLength(xs[0], LengthMode::Width);
        }
    }
    if (has(PropertyID::Y)) {
        LengthList ys = Parser::parseLengthList(get(PropertyID::Y), AllowNegativeLengths);
        if (not ys.empty()) {
            text_state.cursor_y = lengthContext.valueForLength(ys[0], LengthMode::Height);
        }
    }

    auto text_anchor = find(PropertyID::Text_Anchor);
    if (text_anchor.compare("end") == 0)
        text_state.text_anchor = TextAnchor::End;
    else if (text_anchor.compare("middle") == 0)
        text_state.text_anchor = TextAnchor::Middle;
    else
        text_state.text_anchor = TextAnchor::Start;

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

    // Try to handle vertical text at minima just so we lay it out in the expected
    // area (CJK glyphs should not be rotated, but we will; also, the baseline,
    // which should be central, will be a bit off).
    auto writing_mode = find(PropertyID::Writing_Mode);
    if ( writing_mode.compare("tb") == 0 ||
         writing_mode.compare("tb-rl") == 0 ||
         writing_mode.compare("vertical-rl") == 0 ) {
	text_state.is_vertical_rl = true;
    }

    // We can't directly use find() to look at ancestors, because there are 2 possible
    // attributes, and we wouldn't know which was found the nearest.
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
        if (xml_space.compare("default") == 0) {
            text_state.is_pre = false;
            space_prop_found = true;
        }
        else if (xml_space.compare("preserve") == 0) {
            text_state.is_pre = true;
            space_prop_found = true;
        }
    }
    // If none found, use find() to get it from ancestors
    if ( !space_prop_found ) {
        auto white_space = find(PropertyID::White_Space);
        if (white_space.compare("normal") == 0 || white_space.compare("nowrap") == 0 || white_space.compare("pre-line") == 0) {
            text_state.is_pre = false;
            space_prop_found = true;
        }
        else if (white_space.compare("pre") == 0 || white_space.compare("pre-wrap") == 0 || white_space.compare("break-spaces") == 0) {
            text_state.is_pre = true;
            space_prop_found = true;
        }
    }
    if ( !space_prop_found ) {
        auto xml_space = find(PropertyID::XMLSpace);
        if (xml_space.compare("default") == 0) {
            text_state.is_pre = false;
        }
        else if (xml_space.compare("preserve") == 0) {
            text_state.is_pre = true;
        }
    }

    // This <text> element can be handled just like a <g>
    auto group = makeUnique<LayoutGroup>();
    group->transform = transform();
    group->opacity = opacity();
    group->masker = context->getMasker(mask());
    group->clipper = context->getClipper(clip_path());

    for(auto& child : children) {
        TSpanElement * tspan = dynamic_cast<TSpanElement*>(child.get());
        if ( tspan == nullptr ) {
            printf("UNEXPECTED non-tspan <text> child\n");
        }
        else {
            tspan->layoutText(context, group.get(), text_state);
        }
    }

    // Done with tspans: add the last group held in text_state
    TSpanElement::addCurrentGroup(group.get(), text_state);

    current->addChildIfNotEmpty(std::move(group));
}

std::unique_ptr<Node> TextElement::clone() const
{
    return cloneElement<TextElement>();
}

} // namespace lunasvg
