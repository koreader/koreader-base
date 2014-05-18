local ffi = require("ffi")
-- the header definitions
require("ffi/gettext_h")

-- extern var for change_lang
ffi.cdef[[
int _nl_msg_cat_cntr;
]]

local libintl = ffi.load("libs/libgnuintl.so.8.1.2")

local GTX = {}

function GTX.init(locale_dir, package)
	ffi.C.setlocale(ffi.C.LC_ALL, "")

	re = libintl.bindtextdomain(package, locale_dir)
	if re == nil then return false end

	re = libintl.textdomain(package)
	if re == nil then return false end

	return true
end

function GTX.translate(s)
	return ffi.string(libintl.gettext(s))
end

function GTX.change_lang(lang)
	ffi.C.setenv("LANGUAGE", lang, 1)
	libintl._nl_msg_cat_cntr = libintl._nl_msg_cat_cntr + 1
end

return GTX
