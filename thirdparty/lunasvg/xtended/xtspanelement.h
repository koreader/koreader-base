#ifndef TSPANELEMENT_H
#define TSPANELEMENT_H

#include "geometryelement.h"
#include "layoutcontext.h"

namespace lunasvg {

enum class TextAnchor
{
    Start,
    Middle,
    End,
};

enum class LengthAdjust
{
    None,
    Spacing,
    SpacingAndGlyphs,
};

// Text drawing state, passed from <text> to/by all sub-<tspans>
typedef struct {
    double cursor_x;
    double cursor_y;
    double current_start_x;
    double current_start_y;
    double current_end_x;
    double current_end_y;
    bool current_started;
    bool last_was_space;
    bool is_pre;
    bool is_vertical_rl;
    TextAnchor text_anchor;
    TextAnchor current_text_anchor;
    LengthAdjust current_length_adjust;
    double current_adjust_text_length;
    std::unique_ptr<LayoutGroup> current_group;
} text_state_t;

class TSpanElement : public GeometryElement
{
public:
    // Limited support for <textPath>, that we make just a special kind of <tspan> with TSpanElement(ElementID::TextPath)
    TSpanElement(ElementID id=ElementID::TSpan);

    static void addCurrentGroup(LayoutGroup* parent, text_state_t &text_state);

    void layoutText(LayoutContext* context, LayoutGroup* parent, text_state_t &text_state) const;

    void layout(LayoutContext* context, LayoutContainer* current) const override; // not used

    Path path() const override { return Path{}; } // not used

    std::unique_ptr<Node> clone() const override;
};

} // namespace lunasvg

#endif // TSPANELEMENT_H
