#include "ximageelement.h"
#include "layoutcontext.h"
#include "parser.h"

#include <cmath>

namespace lunasvg {

ImageElement::ImageElement()
    : GraphicsElement(ElementID::Image)
{
}

void ImageElement::layout(LayoutContext* context, LayoutContainer* current) const
{
    if ( !context->hasExternalContext() || !context->getExternalContext()->draw_image_helper ) {
        // No external support to decode and draw images
        return;
    }

    if (isDisplayNone())
        return;

    auto x = Parser::parseLength(get(PropertyID::X), AllowNegativeLengths, Length::Zero);
    auto y = Parser::parseLength(get(PropertyID::Y), AllowNegativeLengths, Length::Zero);
    auto width = Parser::parseLength(get(PropertyID::Width), ForbidNegativeLengths, Length::Zero);
    auto height = Parser::parseLength(get(PropertyID::Height), ForbidNegativeLengths, Length::Zero);
    auto preserveAspectRatio = Parser::parsePreserveAspectRatio(get(PropertyID::PreserveAspectRatio));

    if(width.isZero() || height.isZero())
        return;

    // No need to parse "url(...)", a href is directly a url (Firefox and Edge
    // don't expect it and fail handling it)
    auto& href = get(PropertyID::Href);
    if ( href.empty() )
        return;

    LengthContext lengthContext(this);

    auto image = makeUnique<LayoutImage>();
    image->external_context = context->getExternalContext();
    image->href = href;
    image->x = lengthContext.valueForLength(x, LengthMode::Width);
    image->y = lengthContext.valueForLength(y, LengthMode::Height);
    image->width = lengthContext.valueForLength(width, LengthMode::Width);
    image->height = lengthContext.valueForLength(height, LengthMode::Height);
    image->preserveAspectRatio = preserveAspectRatio;
    image->transform = transform();
    image->fillData = context->fillData(this);
    image->strokeData = context->strokeData(this);
    image->visibility = visibility();
    image->clipRule = clip_rule();
    image->opacity = opacity();
    image->masker = context->getMasker(mask());
    image->clipper = context->getClipper(clip_path());
    current->addChild(std::move(image));
}

std::unique_ptr<Node> ImageElement::clone() const
{
    return cloneElement<ImageElement>();
}


// (Similar objects of that kind are all defined in layoutcontext.cpp)
LayoutImage::LayoutImage()
    : LayoutObject(LayoutId::Image)
{
}

void LayoutImage::render(RenderState& state) const
{
    if(visibility == Visibility::Hidden)
        return;

    BlendInfo info{clipper, masker, opacity, Rect::Invalid};
    RenderState newState(this, state.mode());
    newState.transform = transform * state.transform;

    // Guess the final size of the image, so we can request it scaled at this size by the
    // external helper (crengine with its smoothscale code), and avoid/limit LunaSVG's own
    // scaling in setTexture() and fill() - for better quality (except when some rotation
    // is involved...)
    // https://math.stackexchange.com/questions/13150/extracting-rotation-scale-values-from-2d-transformation-matrix
    double scale_x = std::sqrt(newState.transform.m00*newState.transform.m00 + newState.transform.m10*newState.transform.m10);
    double scale_y = std::sqrt(newState.transform.m01*newState.transform.m01 + newState.transform.m11*newState.transform.m11);

    auto image = Canvas::create(0, 0, width*scale_x, height*scale_y);
    double original_aspect_ratio;
    bool drawn = external_context->draw_image_helper(external_context, href.c_str(),
                    image->data(), image->width(), image->height(), original_aspect_ratio);
    if (!drawn) // href not found or image invalid
        return;

    Path path;
    path.rect(x, y, width, height, 0, 0); // path to be filled by the texture
    Transform transform(1/scale_x, 0, 0, 1/scale_y, x, y); // transform to be applied to the texture

    // Start of attempt at handling preserveAspectRatio
    // (If it ends up bad, just comment out all this to get as preserveAspectRatio="none".)
    //
    // Not super sure of all that, but with a bit of random shuffling and luck, this seems to work.
    // It should not mess with the good scaling when preserveAspectRatio is "none" or has "slice";
    // but when it has "meet" and the width=/height= attributes do not follow the original image
    // aspect ratio, some downscaling by LunaSVG will happen, with possible scaling artifacts.
    double w = width;
    double h = height;
    if ( w / h > original_aspect_ratio ) {
        double new_h = w / original_aspect_ratio;
        scale_y *= h / new_h;
        h = new_h;
    }
    else {
        double new_w = original_aspect_ratio * h;
        scale_x *= w / new_w;
        w = new_w;
    }
    auto viewTransform = preserveAspectRatio.getMatrix(width, height, Rect{0, 0, w, h});
    transform = Transform(1/scale_x, 0, 0, 1/scale_y, 0, 0);
    transform = transform * viewTransform;
    transform = transform * transform.translated(x, y);
    // printf("sizes: : %g %g %g %g (orig a/r %g\n", width, height, w, h, width/height, original_aspect_ratio);
    // printf("viewTransform %g %g %g %g %g %g\n", viewTransform.m00, viewTransform.m10,
    //             viewTransform.m01, viewTransform.m11, viewTransform.m02, viewTransform.m12);
    //
    // Note: if preserveAspectRatio has "slice" and we would have "overflow: visible", we might
    // only need to extend the 'path' below to the overflow region. But Firefox does seem to
    // always enforce the default of "overflow: hidden", so let's not bother.
    //
    // End of attempt at handling preserveAspectRatio

    newState.beginGroup(state, info); // this ensures upper transforms and clipping
    newState.canvas->setTexture(image.get(), TextureType::Plain, transform);
    newState.canvas->fill(path, newState.transform, WindRule::NonZero, BlendMode::Src_Over, 1.0);
    newState.endGroup(state, info);
}

Rect LayoutImage::map(const Rect& rect) const
{
    return transform.map(rect);
}

const Rect& LayoutImage::fillBoundingBox() const
{
    if(m_fillBoundingBox.valid())
        return m_fillBoundingBox;

    m_fillBoundingBox = Rect{x, y, width, height};
    return m_fillBoundingBox;
}

const Rect& LayoutImage::strokeBoundingBox() const
{
    if(m_strokeBoundingBox.valid())
        return m_strokeBoundingBox;

    m_strokeBoundingBox = Rect{x, y, width, height};
    return m_strokeBoundingBox;
}

} // namespace lunasvg
