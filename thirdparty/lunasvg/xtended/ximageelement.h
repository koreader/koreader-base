#ifndef IMAGEELEMENT_H
#define IMAGEELEMENT_H

#include "graphicselement.h"
#include "layoutcontext.h"

namespace lunasvg {

class ImageElement : public GraphicsElement
{
public:
    ImageElement();

    void layout(LayoutContext* context, LayoutContainer* current) const override;

    std::unique_ptr<Node> clone() const override;
};

class LayoutImage : public LayoutObject
{
public:
    LayoutImage();

    void render(RenderState& state) const;
    Rect map(const Rect& rect) const;
    const Rect& fillBoundingBox() const;
    const Rect& strokeBoundingBox() const;

public:
    external_context_t * external_context;
    std::string href;
    double x;
    double y;
    double width;
    double height;
    PreserveAspectRatio preserveAspectRatio;
    Transform transform;
    FillData fillData;
    StrokeData strokeData;
    Visibility visibility;
    WindRule clipRule;
    double opacity;
    const LayoutMask* masker;
    const LayoutClipPath* clipper;

private:
    mutable Rect m_fillBoundingBox{Rect::Invalid};
    mutable Rect m_strokeBoundingBox{Rect::Invalid};
};

} // namespace lunasvg

#endif // IMAGEELEMENT_H
