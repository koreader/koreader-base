include Makefile.defs

# Since top-level rules' dependencies are not
# properly declared, disable parallelisation.
.NOTPARALLEL:

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(LINUX)),1,)

$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)
$(info ************ CMAKE_MAKE_PROGRAM: $(strip $(CMAKE_MAKE_PROGRAM) $(CMAKE_MAKE_PROGRAM_FLAGS)) **********)
$(info ************ NINJA: $(strip $(NINJA) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)
$(info ************ MAKE: $(strip $(MAKE) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)

# main target
all: $(CMAKE_KO) $(CMAKE_TCF) $(OUTPUT_DIR)/libs $(if $(ANDROID),,$(LUAJIT)) \
		$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
		$(LUAJIT_JIT) \
		libs $(K2PDFOPT_LIB) \
		$(OUTPUT_DIR)/common \
		$(LUASOCKET) \
		$(OUTPUT_DIR)/ffi $(OUTPUT_DIR)/data \
		$(if $(WIN32),,$(LUASEC)) \
		$(TURBOJPEG_LIB) \
		$(LODEPNG_LIB) \
		$(GIF_LIB) \
		$(ZSTD_LIB) \
		$(if $(USE_LJ_WPACLIENT),$(LJ_WPACLIENT),) \
		$(TURBO_FFI_WRAP_LIB) \
		$(LUA_HTMLPARSER_MOD) \
		$(LPEG_MOD) \
		$(LUAJSON_MOD) \
		$(LUA_RAPIDJSON_MOD) \
		$(LUA_SPORE_MOD) \
		$(if $(WIN32),,$(ZMQ_LIB) $(CZMQ_LIB)) \
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(MACOS),$(OUTPUT_DIR)/koreader,) \
		$(if $(MACOS),$(SDL2_LIB),) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/dropbear,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK)),$(OUTPUT_DIR)/sftp-server,) \
		$(if $(or $(ANDROID),$(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbink $(OUTPUT_DIR)/libs/libfbink_input.so.1) \
		$(if $(or $(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbdepth,) \
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
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbink $(OUTPUT_DIR)/libs/libfbink_input.so.1) \
		$(if $(REMARKABLE),$(OUTPUT_DIR)/button-listen,) \
		$(if $(or $(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/fbdepth,) \
		$(if $(or $(CERVANTES),$(KINDLE),$(KOBO),$(POCKETBOOK),$(REMARKABLE)),$(OUTPUT_DIR)/zsync2,) \
		$(if $(ANDROID),,$(LUAJIT)) \
		$(OUTPUT_DIR)/libs/$(if $(WIN32),*.dll,*.so*)" ;\
	$(STRIP) --strip-unneeded $${STRIP_FILES} ;\
	touch -r $${STRIP_FILES}  # let all files have the same mtime
	find $(OUTPUT_DIR)/common -name "$(if $(WIN32),*.dll,*.so*)" | \
		xargs $(STRIP) --strip-unneeded
endif
	# set up some needed paths and links
	install -d $(OUTPUT_DIR)/{cache,clipboard,fonts}
	$(SYMLINK) $(abspath $(THIRDPARTY_DIR)/kpvcrlib/cr3.css) $(OUTPUT_DIR)/data/

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

$(OUTPUT_DIR)/ffi:
	$(SYMLINK) $(abspath ffi) $@

$(OUTPUT_DIR)/data:
	$(SYMLINK) $(abspath $(CRENGINE_SRC_DIR)/cr3gui/data) $@

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
	$(CC) $(DYNLIB_CFLAGS) -linkview $(LDFLAGS) -o $@ $< -pthread

$(OUTPUT_DIR)/libs/libkoreader-input.so: input/*.c input/*.h $(if $(or $(KINDLE),$(REMARKABLE)),$(POPEN_NOSHELL_LIB),)
	@echo "Building koreader input module..."
	$(CC) $(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -I$(POPEN_NOSHELL_DIR) -I./input \
		$(if $(CERVANTES),-DCERVANTES,) $(if $(KOBO),-DKOBO,) $(if $(KINDLE),-DKINDLE,) $(if $(LEGACY),-DKINDLE_LEGACY,) $(if $(POCKETBOOK),-DPOCKETBOOK,) $(if $(REMARKABLE),-DREMARKABLE,) $(if $(SONY_PRSTUX),-DSONY_PRSTUX,) \
		-o $@ \
		input/input.c \
		$(if $(or $(KINDLE),$(REMARKABLE)),$(POPEN_NOSHELL_LIB),) \
		$(if $(POCKETBOOK),-ldl -linkview -pthread,)

# Would need a bit of patching to be able to use -fvisibility=hidden...
$(OUTPUT_DIR)/libs/libkoreader-lfs.so: \
			$(LUAJIT_LIB) \
			luafilesystem/src/lfs.c
	# Avoid precision loss on 32-bit arches (LFS is always built w/ LARGEFILE support, but lua_Integer is always a ptrdiff_t, which is not wide enough).
	-patch -d luafilesystem -t -N --no-backup-if-mismatch -r - -p1 < patches/lfs-pushnumber-for-wide-types.patch
	$(CC) $(DYNLIB_CFLAGS) $(LDFLAGS) -o $@ luafilesystem/src/lfs.c $(LUAJIT_LIB)
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
			$(LUAJIT_LIB) \
			$(DJVULIBRE_LIB) $(K2PDFOPT_LIB)
	$(CC) -I$(STAGING_DIR)/include -I$(STAGING_DIR)/include/mupdf $(K2PDFOPT_CFLAGS) \
		$(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ djvu.c \
		$(DJVULIBRE_LIB_LINK_FLAG) $(K2PDFOPT_LIB_LINK_FLAG) $(LUAJIT_LIB)
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
			$(LUAJIT_LIB) \
			$(CRENGINE_LIB) $(CRENGINE_THIRDPARTY_LIBS) $(CRENGINE_NEEDED_LIBS)
	$(CXX) $(CRENGINE_CFLAGS) $(DYNLIB_CXXFLAGS) \
		$(SYMVIS_FLAGS) $(LDFLAGS) -o $@ cre.cpp \
		$(CRENGINE_LIB) $(CRENGINE_THIRDPARTY_LIBS) $(FREETYPE_LIB_LINK_FLAG) \
		$(FRIBIDI_LIB) $(HARFBUZZ_LIB_LINK_FLAG) $(JPEG_LIB_LINK_FLAG) \
		$(PNG_LIB) $(LIBUNIBREAK_LIB_LINK_FLAG) $(LIBWEBP_LIB) \
		$(LIBWEBPDEMUX_LIB) $(LUNASVG_LIB) $(UTF8PROC_LIB) $(ZLIB) \
		$(ZSTD_LIB) $(LUAJIT_LIB) \
ifdef DARWIN
	install_name_tool -change \
		`otool -L "$@" | grep "libluajit" | awk '{print $$1}'` \
		libs/$(notdir $(LUAJIT_LIB)) \
		$@
endif

$(OUTPUT_DIR)/libs/libkoreader-xtext.so: xtext.cpp \
			$(LUAJIT_LIB) \
			$(FREETYPE_LIB) $(HARFBUZZ_LIB) $(FRIBIDI_LIB) $(LIBUNIBREAK_LIB)
	$(CXX) \
	-I$(STAGING_DIR)/include/freetype2 \
	-I$(STAGING_DIR)/include/harfbuzz \
	-I$(STAGING_DIR)/include/fribidi \
	-I$(STAGING_DIR)/include \
	$(DYNLIB_CXXFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) \
	-Wall -o $@ xtext.cpp \
	$(FREETYPE_LIB_LINK_FLAG) \
	$(FRIBIDI_LIB_LINK_FLAG) \
	$(HARFBUZZ_LIB_LINK_FLAG) \
	$(LIBUNIBREAK_LIB_LINK_FLAG) \
	$(LUAJIT_LIB)
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
			$(LUAJIT_LIB) \
			$(NANOSVG_HEADERS)
	$(CC) $(DYNLIB_CFLAGS) -Wall $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ nnsvg.c $(LUAJIT_LIB) -lm
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
	$(CC) -I$(STAGING_DIR)/include/mupdf $(DYNLIB_CFLAGS) $(SYMVIS_FLAGS) $(LDFLAGS) -o $@ wrap-mupdf.c -lmupdf
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
	$(CC) -I$(STAGING_DIR)/include/mupdf $(CFLAGS) $(LDFLAGS) -o $@ extr.c \
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
	$(SYMLINK) $(abspath .busted) $@

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	$(SYMLINK) $(abspath spec) $@

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

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/
	$(SYMLINK) $(abspath $(dir $(DROID_FONT))) $(OUTPUT_DIR)/fonts/droid

$(DROID_FONT):
	mkdir -p $(dir $(DROID_FONT))
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

endif

# }}}

# CI helpers. {{{

define cache_key_ignores
':!*.lua'
':!*/.*'
':!/.*'
':!/COPYING'
':!/README.md'
':!/ffi-cdecl/*'
':!/spec/*'
':!/toolchain/*'
':!/utils/*'
endef

cache-key: Makefile
	git ls-files -z $(strip $(cache_key_ignores)) | xargs -0 git ls-tree @ | tee $@

# }}}

# Dump binaries runtime path and dependencies. {{{

bindeps:
	@./utils/bindeps.sh $(filter-out $(STAGING_DIR) $(THIRDPARTY_BUILD),$(wildcard $(OUTPUT_DIR)/*))

# }}}

# Checking libraries for missing dependencies. {{{

# NOTE: the extra `$(filter %/,…)` is to work around some older versions
# of make (e.g. 4.2.1) returning files too when using `$(wildcard …/*/)`.
libcheck:
	@./utils/libcheck.sh $(CC) $(LDFLAGS) -Wl,-rpath-link=$(OUTPUT_DIR)/libs -- '$(if $(USE_LUAJIT_LIB),,1)' $(filter %/,$(filter-out $(OUTPUT_DIR)/thirdparty/,$(wildcard $(OUTPUT_DIR)/*/)))

ifneq (,$(POCKETBOOK))
libcheck: utils/libcheck/libinkview.so
utils/libcheck/libinkview.so: utils/libcheck/libinkview.ld
	$(LD) -shared -o $@ $<
endif

# }}}

.PHONY: all bindeps clean distclean dist-clean libcheck test

# vim: foldmethod=marker foldlevel=0
