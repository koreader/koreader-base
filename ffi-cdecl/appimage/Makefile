KODEBUG ?=
KOR_BASE ?= ../..

TARGET = linux
VERSION = 2.0.0

include $(KOR_BASE)/Makefile.defs

APPDIR = $(OUTPUT_DIR)/AppDir

NINJA_GOALS = luajit\ tree-sitter\ tree-sitter-c

all: appimage

clean: base-clean

re: clean
	$(MAKE) all

define APPIMAGE_FILES
luajit
libs/libtree-sitter.so.*[0-9]
libs/libtree-sitter-c.so.*[0-9]
ffi/loadlib.lua
ffi/posix_h.lua
ffi/posix_types_*_h.lua
ffi/tree_sitter_h.lua
endef

appdir: $(NINJA_GOALS)
	rm -rf $(APPDIR)
	$(call appimage_install,,AppRun ffi-cdecl.desktop ffi-cdecl.png,.)
	$(call appimage_install,ffi-cdecl,$(APPIMAGE_FILES))
	$(call appimage_install,ffi-cdecl,ffi-cdecl.h ffi-cdecl.lua,..)

appimage: appdir $(MKAPPIMAGE)
	ARCH='$(APPIMAGE_ARCH)' VERSION='$(VERSION)' $(MKAPPIMAGE) --appimage-extract-and-run $(APPDIR) ffi-cdecl-$(VERSION)-$(APPIMAGE_ARCH).AppImage

PHONY = all appdir appimage clean re

include $(KOR_BASE)/Makefile
