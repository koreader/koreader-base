// CPPFLAGS="$(pkg-config --cflags gtk+-3.0)" ./ffi-cdecl ...
// Make sure we don't blow up in glib-2.0/glib/gmacros.h ...
#define __GI_SCANNER__

#include <gtk/gtk.h>

#include "ffi-cdecl.h"

cdecl_type(gint)
cdecl_type(gchar)
cdecl_type(gboolean)

cdecl_type(GtkDialog)
cdecl_type(GtkWidget)
cdecl_type(GtkWindow)
cdecl_type(GtkFileChooser)

cdecl_type(GtkFileChooserAction)
cdecl_type(GtkResponseType)

cdecl_func(gtk_init)
cdecl_func(gtk_events_pending)
cdecl_func(gtk_main_iteration)
cdecl_func(gtk_file_chooser_dialog_new)
cdecl_func(gtk_dialog_run)
cdecl_func(gtk_widget_destroy)
cdecl_func(gtk_file_chooser_get_filename)
