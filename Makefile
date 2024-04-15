include Makefile.defs

# Since top-level rules' dependencies are not
# properly declared, disable parallelisation.
.NOTPARALLEL:

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(DEBIAN)),1,)

$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)

# main target
all: $(CMAKE_KO) $(CMAKE_TCF) $(OUTPUT_DIR)/libs $(if $(ANDROID),,$(LUAJIT)) \
		$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
		$(LUAJIT_JIT) \
		libs $(K2PDFOPT_LIB) \
		$(OUTPUT_DIR)/common $(OUTPUT_DIR)/rocks \
		$(OUTPUT_DIR)/plugins $(LUASOCKET) \
		$(OUTPUT_DIR)/ffi $(OUTPUT_DIR)/data \
		$(if $(WIN32),,$(LUASEC)) \
		$(TURBOJPEG_LIB) \
		$(LODEPNG_LIB) \
		$(GIF_LIB) \
		$(ZSTD_LIB) \
		$(if $(USE_LJ_WPACLIENT),$(LJ_WPACLIENT),) \
		$(TURBO_FFI_WRAP_LIB) \
		$(LUA_HTMLPARSER_ROCK) \
		$(LPEG_ROCK) \
		$(LUAJSON_ROCK) \
		$(LUA_RAPIDJSON_ROCK) \
		$(LUA_SPORE_MOD) \
		$(if $(WIN32),,$(ZMQ_LIB) $(CZMQ_LIB)) \
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(MACOS),$(OUTPUT_DIR)/koreader,) \
		$(if $(MACOS),$(SDL2_LIB),) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/dropbear,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/sftp-server,) \
		$(if $(or $(ANDROID),$(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbink,) \
		$(if $(KOBO),$(OUTPUT_DIR)/data/KoboUSBMS.tar.gz,) \
		$(if $(REMARKABLE),$(OUTPUT_DIR)/button-listen,) \
		$(SQLITE_LIB) \
		$(LUA_LJ_SQLITE) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(CURL_LIB),) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/zsync2,)
ifeq ($(DO_STRIP),1)
	STRIP_FILES="\
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(or $(ANDROID),$(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/dropbear,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/sftp-server,) \
		$(if $(or $(KINDLE),$(KOBO)),$(OUTPUT_DIR)/scp,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbink,) \
		$(if $(REMARKABLE),$(OUTPUT_DIR)/button-listen,) \
		$(if $(or $(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbdepth,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/zsync2,) \
		$(if $(ANDROID),,$(LUAJIT)) \
		$(OUTPUT_DIR)/rocks/lib/lua/5.1/$(if $(WIN32),*.dll,*.so*) \
		$(OUTPUT_DIR)/libs/$(if $(WIN32),*.dll,*.so*)" ;\
	$(STRIP) --strip-unneeded $${STRIP_FILES} ;\
	touch -r $${STRIP_FILES}  # let all files have the same mtime
	find $(OUTPUT_DIR)/common -name "$(if $(WIN32),*.dll,*.so*)" | \
		xargs $(STRIP) --strip-unneeded
endif
	# set up some needed paths and links
	install -d $(OUTPUT_DIR)/{cache,clipboard,fonts}
	ln -sf $(CURDIR)/$(THIRDPARTY_DIR)/kpvcrlib/cr3.css $(OUTPUT_DIR)/data/

$(OUTPUT_DIR)/:
	mkdir -p $@

$(OUTPUT_DIR)/%/:
	mkdir -p $@

$(CMAKE_KO): Makefile.defs | $(CMAKE_DIR)/
	$(if $(DRY_RUN),: $@,$(file > $(CMAKE_KO),$(cmake_koreader)))

$(CMAKE_TCF): Makefile.defs | $(CMAKE_DIR)/
	$(if $(DRY_RUN),: $@,$(file > $(CMAKE_TCF),$(if $(EMULATE_READER),$(cmake_toolchain),$(cmake_cross_toolchain))))

$(OUTPUT_DIR)/libs:
	install -d $(OUTPUT_DIR)/libs

$(OUTPUT_DIR)/common:
	install -d $(OUTPUT_DIR)/common

$(OUTPUT_DIR)/rocks:
	install -d $(OUTPUT_DIR)/rocks

$(OUTPUT_DIR)/plugins:
	install -d $(OUTPUT_DIR)/plugins

$(OUTPUT_DIR)/ffi:
	ln -sf ../../ffi $(OUTPUT_DIR)/

$(OUTPUT_DIR)/data:
	ln -sf $(CRENGINE_SRC_DIR)/cr3gui/data $(OUTPUT_DIR)/data

# our own Lua/C/C++ interfacing:

libs: \
	$(if $(or $(SDL),$(ANDROID)),,$(OUTPUT_DIR)/libs/libkoreader-input.so) \
	$(if $(or $(SDL),$(ANDROID),$(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE),$(SONY_PRSTUX)),$(OUTPUT_DIR)/libs/libblitbuffer.so,) \
	$(if $(APPIMAGE),$(OUTPUT_DIR)/libs/libXss.so.1,) \
	$(if $(POCKETBOOK),$(OUTPUT_DIR)/libs/libinkview-compat.so,) \
	$(OUTPUT_DIR)/libs/libkoreader-lfs.so \
	$(OUTPUT_DIR)/libs/libkoreader-djvu.so \
	$(OUTPUT_DIR)/libs/libkoreader-cre.so \
	$(OUTPUT_DIR)/libs/libkoreader-xtext.so \
	$(OUTPUT_DIR)/libs/libkoreader-nnsvg.so \
	$(OUTPUT_DIR)/libs/libwrap-mupdf.so

$(OUTPUT_DIR)/libs/libinkview-compat.so: input/inkview-compat.c
	$(CC) $(DYNLIB_CFLAGS) -linkview $(LDFLAGS) -o $@ $<

$(OUTPUT_DIR)/libs/libkoreader-input.so: input/*.c input/*.h $(if $(or $(KINDLE),$(REMARKABLE)),$(POPEN_NOSHELL_LIB),)
	@echo "Building koreader input module..."
	$(CC) $(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -I$(POPEN_NOSHELL_DIR) -I./input \
		$(if $(CERVANTES),-DCERVANTES,) $(if $(KOBO),-DKOBO,) $(if $(KINDLE),-DKINDLE,) $(if $(LEGACY),-DKINDLE_LEGACY,) $(if $(POCKETBOOK),-DPOCKETBOOK,) $(if $(REMARKABLE),-DREMARKABLE,) $(if $(SONY_PRSTUX),-DSONY_PRSTUX,) \
		-o $@ \
		input/input.c \
		$(if $(or $(KINDLE),$(REMARKABLE)),$(POPEN_NOSHELL_LIB),) \
		$(if $(POCKETBOOK),-linkview,)

# Would need a bit of patching to be able to use -fvisibility=hidden...
$(OUTPUT_DIR)/libs/libkoreader-lfs.so: \
			$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
			luafilesystem/src/lfs.c
	# Avoid precision loss on 32-bit arches (LFS is always built w/ LARGEFILE support, but lua_Integer is always a ptrdiff_t, which is not wide enough).
	-patch -d luafilesystem -t -N --no-backup-if-mismatch -r - -p1 < patches/lfs-pushnumber-for-wide-types.patch
	$(CC) $(DYNLIB_CFLAGS) $(LDFLAGS) -o $@ luafilesystem/src/lfs.c $(LUAJIT_LIB_LINK_FLAG)
	-patch -d luafilesystem -t -R --no-backup-if-mismatch -r - -p1 < patches/lfs-pushnumber-for-wide-types.patch
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
endif

# put all the libs to the end of compile command to make ubuntu's tool chain
# happy
$(OUTPUT_DIR)/libs/libkoreader-djvu.so: djvu.c \
			$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
			$(DJVULIBRE_LIB) $(K2PDFOPT_LIB)
	$(CC) -I$(DJVULIBRE_DIR)/include -I$(MUPDF_DIR)/include $(K2PDFOPT_CFLAGS) \
		$(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ djvu.c $(LUAJIT_LIB_LINK_FLAG) \
		$(DJVULIBRE_LIB_LINK_FLAG) $(K2PDFOPT_LIB_LINK_FLAG) $(if $(ANDROID),,-lpthread)
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
	install_name_tool -change \
		`otool -L "$@" | grep "$(notdir $(DJVULIBRE_LIB)) " | awk '{print $$1}'` \
		libs/$(notdir $(DJVULIBRE_LIB)) \
		$@
	install_name_tool -change \
		`otool -L "$@" | grep "$(notdir $(K2PDFOPT_LIB)) " | awk '{print $$1}'` \
		libs/$(notdir $(K2PDFOPT_LIB)) \
		$@
endif

$(OUTPUT_DIR)/libs/libkoreader-cre.so: cre.cpp \
			$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
			$(CRENGINE_LIB) $(CRENGINE_THIRDPARTY_LIBS) $(CRENGINE_NEEDED_LIBS)
	$(CXX) $(CRENGINE_CFLAGS) $(DYNLIB_CXXFLAGS) \
		$(SYMVIS_FLAGS) $(LDFLAGS) -o $@ cre.cpp $(LUAJIT_LIB_LINK_FLAG) \
		$(CRENGINE_LIB) $(CRENGINE_THIRDPARTY_LIBS) $(FREETYPE_LIB_LINK_FLAG) \
		$(FRIBIDI_LIB) $(HARFBUZZ_LIB_LINK_FLAG) $(JPEG_LIB_LINK_FLAG) \
		$(LIBWEBP_LIB) $(LIBWEBPDEMUX_LIB) $(LIBUNIBREAK_LIB_LINK_FLAG) \
		$(LUNASVG_LIB) $(PNG_LIB) $(UTF8PROC_LIB) $(ZLIB) $(ZSTD_LIB) \
		$(LUAJIT_LIB_LINK_FLAG) \
		$(if $(ANDROID),$(SHARED_STL_LINK_FLAG),)
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
endif

$(OUTPUT_DIR)/libs/libkoreader-xtext.so: xtext.cpp \
			$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
			$(FREETYPE_LIB) $(HARFBUZZ_LIB) $(FRIBIDI_LIB) $(LIBUNIBREAK_LIB)
	$(CXX) -I$(FREETYPE_DIR)/include/freetype2 \
	-I$(HARFBUZZ_DIR)/include/harfbuzz \
	-I$(FRIBIDI_DIR)/include/fribidi \
	-I$(LIBUNIBREAK_DIR)/include \
	$(DYNLIB_CXXFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) \
	-Wall -o $@ xtext.cpp \
	$(FREETYPE_LIB_LINK_FLAG) \
	$(FRIBIDI_LIB_LINK_FLAG) \
	$(HARFBUZZ_LIB_LINK_FLAG) \
	$(LIBUNIBREAK_LIB_LINK_FLAG) \
	$(LUAJIT_LIB_LINK_FLAG)
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
	install_name_tool -change \
		`otool -L "$@" | grep "$(notdir $(HARFBUZZ_LIB)) " | awk '{print $$1}'` \
		libs/$(notdir $(HARFBUZZ_LIB)) \
		$@
	install_name_tool -change \
		`otool -L "$@" | grep "$(notdir $(FRIBIDI_LIB)) " | awk '{print $$1}'` \
		libs/$(notdir $(FRIBIDI_LIB)) \
		$@
endif

$(OUTPUT_DIR)/libs/libkoreader-nnsvg.so: nnsvg.c \
			$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
			$(NANOSVG_HEADERS)
	$(CC) -I$(NANOSVG_INCLUDE_DIR) \
	$(DYNLIB_CFLAGS) -Wall $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ nnsvg.c $(LUAJIT_LIB_LINK_FLAG) -lm
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
endif

$(OUTPUT_DIR)/libs/libblitbuffer.so: blitbuffer.c
	$(CC) $(DYNLIB_CFLAGS) $(VECTO_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ $^

$(OUTPUT_DIR)/libs/libwrap-mupdf.so: wrap-mupdf.c \
			$(MUPDF_LIB)
	$(CC) -I$(MUPDF_DIR)/include $(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ wrap-mupdf.c -lmupdf
ifdef DARWIN
	install_name_tool -id \
		libs/libwrap-mupdf.so \
		$@
endif

$(OUTPUT_DIR)/libs/libXss.so.1: libxss-dummy.c
	$(CC) $(DYNLIB_CFLAGS) $(LDFLAGS) -o $@ $^

# include all third party libs
include Makefile.third

# ===========================================================================
# entry point for the application in OSX

$(OUTPUT_DIR)/koreader: osx_loader.c
	$(CC) -I$(LUAJIT_DIR)/src $(LUAJIT_STATIC) $(LDFLAGS) -o $@ $^

# ===========================================================================
# very simple "launcher" for koreader on the remarkable

$(OUTPUT_DIR)/button-listen: button-listen.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

# ===========================================================================
# the attachment extraction tool:

$(OUTPUT_DIR)/extr: extr.c $(MUPDF_LIB) $(JPEG_LIB) $(FREETYPE_LIB)
	$(CC) -I$(MUPDF_DIR) -I$(MUPDF_DIR)/include \
		$(CFLAGS) $(LDFLAGS) -o $@ extr.c \
		-lmupdf $(JPEG_LIB_LINK_FLAG) $(FREETYPE_LIB_LINK_FLAG)

# ===========================================================================
# helper target for initializing third-party code

clean:
	-rm -rf $(OUTPUT_DIR)

distclean:
	-rm -rf build
	-rm -rf $(THIRDPARTY_DIR)/{$(CMAKE_THIRDPARTY_LIBS)}/build

dist-clean: distclean

# Testsuite support. {{{

ifneq (,$(EMULATE_READER))

all: $(OUTPUT_DIR)/spec/base

$(OUTPUT_DIR)/.busted: | $(OUTPUT_DIR)/
	ln -sf ../../.busted $(OUTPUT_DIR)/

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	ln -sf ../../../spec $(OUTPUT_DIR)/spec/base

test: all test-data
	cd $(OUTPUT_DIR) && $(BUSTED_LUAJIT) ./spec/base/unit

test-data: $(OUTPUT_DIR)/.busted $(OUTPUT_DIR)/data/tessdata/eng.traineddata $(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf

TESSDATA_DIST = thirdparty/tesseract/build/downloads/tesseract-ocr-3.02.eng.tar.gz
TESSDATA_DIST_URL = https://src.fedoraproject.org/repo/pkgs/tesseract/$(notdir $(TESSDATA_DIST))/3562250fe6f4e76229a329166b8ae853/$(notdir $(TESSDATA_DIST))
TESSDATA_DIST_SHA1 = 989ed4c3a5b246d7353893e466c353099d8b73a1

$(OUTPUT_DIR)/data/tessdata/eng.traineddata: $(TESSDATA_DIST) | $(OUTPUT_DIR)/data
	tar xzf $(TESSDATA_DIST) --strip-components=1 -C $(OUTPUT_DIR)/data
	touch $@

$(TESSDATA_DIST):
	mkdir -p $(dir $(TESSDATA_DIST))
	$(call wget_and_validate,$(TESSDATA_DIST),$(TESSDATA_DIST_URL),$(TESSDATA_DIST_SHA1))

DROID_FONT = thirdparty/fonts/build/downloads/DroidSansMono.ttf
DROID_FONT_URL = https://github.com/koreader/koreader-fonts/raw/master/droid/$(notdir $(DROID_FONT))
DROID_FONT_SHA1 = 0b75601f8ef8e111babb6ed11de6573f7178ce44

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/droid/
	cp $^ $@

$(DROID_FONT):
	mkdir -p $(dir $(DROID_FONT))
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

endif

# }}}

.PHONY: all clean distclean dist-clean test

# vim: foldmethod=marker foldlevel=0
