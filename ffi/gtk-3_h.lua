local ffi = require "ffi"

ffi.cdef [[

typedef void GtkDialog;
typedef void GtkWidget;
typedef void GtkWindow;
typedef void GtkFileChooser;

typedef int gint;
typedef char gchar;
typedef bool gboolean;

typedef enum
{
  GTK_FILE_CHOOSER_ACTION_OPEN,
  GTK_FILE_CHOOSER_ACTION_SAVE,
  GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
  GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER
} GtkFileChooserAction;

typedef enum
{
  GTK_RESPONSE_NONE         = -1,
  GTK_RESPONSE_REJECT       = -2,
  GTK_RESPONSE_ACCEPT       = -3,
  GTK_RESPONSE_DELETE_EVENT = -4,
  GTK_RESPONSE_OK           = -5,
  GTK_RESPONSE_CANCEL       = -6,
  GTK_RESPONSE_CLOSE        = -7,
  GTK_RESPONSE_YES          = -8,
  GTK_RESPONSE_NO           = -9,
  GTK_RESPONSE_APPLY        = -10,
  GTK_RESPONSE_HELP         = -11
} GtkResponseType;

void gtk_init (
    int *argc,
    char ***argv
);

gboolean gtk_events_pending (
    void
);

gboolean gtk_main_iteration (
    void
);

GtkWidget * gtk_file_chooser_dialog_new (
    const gchar *title,
    GtkWindow *parent,
    GtkFileChooserAction action,
    const gchar *first_button_text,
    ...
);

gint gtk_dialog_run (
    GtkDialog *dialog
);

void gtk_widget_destroy (
    GtkWidget *widget
);

gchar * gtk_file_chooser_get_filename (
    GtkFileChooser *chooser
);

]]
