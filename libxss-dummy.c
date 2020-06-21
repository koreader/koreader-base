// Dummy symbol resolver for AppImage
// See https://github.com/koreader/koreader/issues/4627
// Thanks to https://github.com/AppImage/pkg2appimage/issues/127#issuecomment-278397037
#include <X11/Xlib.h>
typedef unsigned long ulong;
typedef unsigned int uint;
typedef struct { Window window; int state; int kind; ulong til_or_since; ulong idle; ulong eventMask; } XScreenSaverInfo;
Bool XScreenSaverQueryExtension(Display *dpy, int *event_base_return, int *error_base_return){}
Status XScreenSaverQueryVersion(Display *dpy, int *major_version_return, int *minor_version_return){}
XScreenSaverInfo *XScreenSaverAllocInfo(void){}
Status XScreenSaverQueryInfo(Display *dpy, Drawable drawable, XScreenSaverInfo *saver_info){}
void XScreenSaverSelectInput(register Display *dpy, Drawable drawable,  ulong mask){}
void XScreenSaverSetAttributes(Display *dpy, Drawable drawable, int x, int y, uint width, uint height,
  uint border_width, int depth, uint class, Visual *visual, ulong valuemask, XSetWindowAttributes *attributes){}
void XScreenSaverUnsetAttributes(register Display *dpy, Drawable drawable){}
Status XScreenSaverRegister(Display *dpy, int screen, XID xid, Atom type){}
Status XScreenSaverUnregister(Display *dpy, int screen){}
Status XScreenSaverGetRegistered(Display *dpy, int screen, XID *xid, Atom *type){}
void XScreenSaverSuspend(Display *dpy, Bool suspend){}
