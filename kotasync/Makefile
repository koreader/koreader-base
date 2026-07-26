KODEBUG ?=
KOR_BASE ?= ..

TARGET = linux
KOTASYNC = 1
VERSION = 1.0.0

include $(KOR_BASE)/Makefile.defs

NINJA_GOALS = dkjson\ koreader-lfs\ luasec\ xxhash\ xz\ zstd

all: appimage

clean: base-clean

re: clean
	$(MAKE) all

define APPIMAGE_FILES
common/dkjson.lua
common/ltn12.lua
common/mime.lua
common/mime/mcore.so
common/socket.lua
common/socket/ftp.lua
common/socket/headers.lua
common/socket/http.lua
common/socket/score.so
common/socket/smtp.lua
common/socket/tp.lua
common/socket/url.lua
common/ssl.lua
common/ssl.so
common/ssl/https.lua
ffi/downloader.lua
ffi/hashoir.lua
ffi/kotasync.lua
ffi/loadlib.lua
ffi/posix.lua
ffi/posix_h.lua
ffi/util.lua
ffi/xxhash_h.lua
ffi/xz_h.lua
ffi/zstd.lua
ffi/zstd_h.lua
libs/libcrypto.so.*[0-9]
libs/libkoreader-lfs.so
libs/liblzma.so.*[0-9]
libs/libssl.so.*[0-9]
libs/libxxhash.so.*[0-9]
libs/libzstd.so.*[0-9]
luajit
endef

appdir: $(NINJA_GOALS)
	rm -rf $(APPDIR)
	$(call appimage_install,,AppRun kotasync.desktop kotasync.png,.)
	$(call appimage_install,kotasync,$(APPIMAGE_FILES))
	$(call appimage_install,kotasync,kotasync.lua,.)

appimage: appdir $(MKAPPIMAGE)
	$(call appimage_generate,kotasync,1.0.0)

PHONY = all appdir appimage clean

include $(KOR_BASE)/Makefile
