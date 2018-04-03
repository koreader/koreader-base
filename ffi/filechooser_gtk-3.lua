local ffi = require "ffi"

local dummy = require("ffi/gtk-3_h")

local ok, gtk = pcall(ffi.load, "gtk-3")
if not ok then
    ok, gtk = pcall(ffi.load, "gtk-3.so.0")
end
if not ok then return end

local FileChooser = {
    type = "gtk-3",
}

--[[
Mostly taken from https://love2d.org/forums/viewtopic.php?f=4&t=82442

Proof of concept, https://github.com/Alloyed/nativefiledialog might be better.
--]]

function FileChooser:show(action, button, title)
    gtk.gtk_init(nil, nil)

    local d = gtk.gtk_file_chooser_dialog_new(
        title,
        nil,
        action,
        "_Cancel", ffi.cast("const gchar *", gtk.GTK_RESPONSE_CANCEL),
        button, ffi.cast("const gchar *", gtk.GTK_RESPONSE_OK),
        nil)

    local response = gtk.gtk_dialog_run(d)
    local filename = gtk.gtk_file_chooser_get_filename(d)

    gtk.gtk_widget_destroy(d)

    while gtk.gtk_events_pending() do
        gtk.gtk_main_iteration()
    end

    if response == gtk.GTK_RESPONSE_OK then
        return filename ~= nil and ffi.string(filename) or nil
    end
end

function FileChooser:save(title)
    return self:show(gtk.GTK_FILE_CHOOSER_ACTION_SAVE,
        "_Save", title or "Save As")
end

function FileChooser:open(title)
    return self:show(gtk.GTK_FILE_CHOOSER_ACTION_OPEN,
        "_Open", title or "Open")
end

return FileChooser
