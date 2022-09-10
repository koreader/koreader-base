#ifndef TEXTELEMENT_H
#define TEXTELEMENT_H

#include "graphicselement.h"

namespace lunasvg {

class TextElement : public GraphicsElement
{
public:
    TextElement();

    void layout(LayoutContext* context, LayoutContainer* current) const override;

    std::unique_ptr<Node> clone() const override;
};

} // namespace lunasvg

#endif // TEXTELEMENT_H
