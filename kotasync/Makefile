KODEBUG ?=
KOR_BASE ?= ..

APPIMAGE = 1
KOTASYNC = 1
VERSION = 1.0.0

include $(KOR_BASE)/Makefile.defs

APPDIR = $(OUTPUT_DIR)/AppDir

LINUXDEPLOY = linuxdeploy-$(APPIMAGE_ARCH).AppImage
LINUXDEPLOY_URL = https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/$(LINUXDEPLOY)

NINJA_GOALS = dkjson\ koreader-lfs\ luasec\ xxhash\ xz\ zstd

all: appimage

clean: base-clean

define LUA_FILES

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
ffi/posix_h.lua
ffi/posix_types_64b_h.lua
ffi/posix_types_def_h.lua
ffi/posix_types_x64_h.lua
ffi/posix_types_x86_h.lua
ffi/util.lua
ffi/xxhash_h.lua
ffi/xz_h.lua
ffi/zstd.lua
ffi/zstd_h.lua

kotasync.lua

libs/libkoreader-lfs.so

endef

define make_appimage
LINUXDEPLOY_OUTPUT_VERSION='$(VERSION)'
./$(LINUXDEPLOY) --appimage-extract-and-run
--appdir $(APPDIR)
--custom-apprun AppRun
--desktop-file kotasync.desktop
--executable $(OUTPUT_DIR)/luajit
--icon-file kotasync.png
--library $(OUTPUT_DIR)/libs/libcrypto.so.[0-9][0-9]
--library $(OUTPUT_DIR)/libs/liblzma.so.[0-9]
--library $(OUTPUT_DIR)/libs/libssl.so.[0-9][0-9]
--library $(OUTPUT_DIR)/libs/libxxhash.so.[0-9]
--library $(OUTPUT_DIR)/libs/libzstd.so.[0-9]
--library $(OUTPUT_DIR)/libs/libzstd.so.[0-9]
--output appimage
endef

define newline


endef

linuxdeploy $(LINUXDEPLOY):
	wget -O $(LINUXDEPLOY).part '$(LINUXDEPLOY_URL)'
	# Zero-out AppImage magic bytes from the ELF header extended ABI version so
	# binfmt+qemu can be used (e.g. when executed from `docker run --platform …`).
	# Cf. https://github.com/AppImage/AppImageKit/issues/1056.
	printf '\0\0\0' | dd conv=notrunc obs=1 seek=8 of=$(LINUXDEPLOY).part
	chmod +x $(LINUXDEPLOY).part
	mv $(LINUXDEPLOY).part $(LINUXDEPLOY)

appdir: $(NINJA_GOALS)
	rm -rf $(APPDIR) $(APPDIR).part
	$(foreach f,$(LUA_FILES), install -Dv $(wildcard $f $(OUTPUT_DIR)/$f) $(APPDIR).part/usr/share/lua/$(f:common/%=%)$(newline))
	chrpath -c -r '$$ORIGIN/../../../lib' $(APPDIR).part/usr/share/lua/*.so
	chrpath -c -r '$$ORIGIN/../../lib' $(APPDIR).part/usr/share/lua/*.so
	mv $(APPDIR).part $(APPDIR)

appimage: appdir $(LINUXDEPLOY)
	$(strip $(make_appimage))

PHONY = all appdir appimage clean linuxdeploy
SOUND = $(LINUXDEPLOY)

.NOTPARALLEL:
.PHONY: $(PHONY)

include $(KOR_BASE)/Makefile
