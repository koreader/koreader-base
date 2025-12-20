// Dummy symbol resolver for AppImage
// See https://github.com/koreader/koreader/issues/4627
// Thanks to https://github.com/AppImage/pkg2appimage/issues/127#issuecomment-278397037
#include <X11/Xlib.h>
typedef unsigned long ulong;
typedef unsigned int uint;
typedef struct XScreenSaverInfo XScreenSaverInfo;
Bool XScreenSaverQueryExtension(Display *dpy, int *event_base_return, int *error_base_return) { return False; }
Status XScreenSaverQueryVersion(Display *dpy, int *major_version_return, int *minor_version_return) { return False; }
XScreenSaverInfo *XScreenSaverAllocInfo(void) { return NULL; }
Status XScreenSaverQueryInfo(Display *dpy, Drawable drawable, XScreenSaverInfo *saver_info) { return 0; }
void XScreenSaverSelectInput(register Display *dpy, Drawable drawable,  ulong mask) {}
void XScreenSaverSetAttributes(Display *dpy, Drawable drawable, int x, int y, uint width, uint height,
  uint border_width, int depth, uint class, Visual *visual, ulong valuemask, XSetWindowAttributes *attributes) {}
void XScreenSaverUnsetAttributes(register Display *dpy, Drawable drawable) {}
Status XScreenSaverRegister(Display *dpy, int screen, XID xid, Atom type) { return 0; }
Status XScreenSaverUnregister(Display *dpy, int screen) { return 0; }
Status XScreenSaverGetRegistered(Display *dpy, int screen, XID *xid, Atom *type) { return 0; }
void XScreenSaverSuspend(Display *dpy, Bool suspend) {}
