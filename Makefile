include Makefile.defs

# main target
all: $(OUTPUT_DIR)/libs $(if $(ANDROID),,$(LUAJIT)) \
		$(if $(USE_LUAJIT_LIB),$(LUAJIT_LIB),) \
		$(LUAJIT_JIT) \
		libs $(K2PDFOPT_LIB) \
		$(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/common $(OUTPUT_DIR)/rocks \
		$(OUTPUT_DIR)/plugins $(LUASOCKET) \
		$(OUTPUT_DIR)/ffi $(OUTPUT_DIR)/data \
		$(if $(WIN32),,$(LUASEC)) \
		$(if $(ANDROID),$(LUACOMPAT52) $(LUALONGNUMBER),) \
		$(if $(or $(DARWIN),$(WIN32)),,$(EVERNOTE_LIB)) \
		$(LUASERIAL_LIB) \
		$(TURBOJPEG_LIB) \
		$(LODEPNG_LIB) \
		$(GIF_LIB) \
		$(if $(USE_LJ_WPACLIENT),$(LJ_WPACLIENT),) \
		$(if $(DARWIN),,$(TURBO_FFI_WRAP_LIB)) \
		$(LUA_SPORE_ROCK) \
		$(if $(ANDROID),$(LPEG_DYNLIB) $(LPEG_RE),) \
		$(if $(or $(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/sdcv) \
		$(if $(or $(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(DARWIN),$(WIN32)),,$(OUTPUT_DIR)/zsync) \
		$(if $(or $(DARWIN),$(WIN32)), ,$(ZMQ_LIB) $(CZMQ_LIB) $(FILEMQ_LIB) $(ZYRE_LIB)) \
		$(SQLITE_LIB) \
		$(LUA_LJ_SQLITE) $(OUTPUT_DIR)/common/xsys.lua
ifndef EMULATE_READER
	STRIP_FILES="\
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(WIN32),,$(OUTPUT_DIR)/tar) \
		$(if $(WIN32),,$(OUTPUT_DIR)/zsync) \
		$(if $(ANDROID),,$(LUAJIT)) \
		$(OUTPUT_DIR)/libs/$(if $(WIN32),*.dll,*.so*)" ;\
	$(STRIP) --strip-unneeded $${STRIP_FILES} ;\
	touch -r $${STRIP_FILES}  # let all files have the same mtime
	find $(OUTPUT_DIR)/common -name "$(if $(WIN32),*.dll,*.so*)" | \
		xargs $(STRIP) --strip-unneeded
endif
	# set up some needed paths and links
	install -d $(OUTPUT_DIR)/{cache,history,clipboard,fonts} $(CURDIR)/$(EVERNOTE_THRIFT_DIR)
	ln -sf $(CURDIR)/$(THIRDPARTY_DIR)/kpvcrlib/cr3.css $(OUTPUT_DIR)/data/
ifndef DARWIN
	# setup Evernote SDK
	cd $(EVERNOTE_SDK_DIR) && \
		$(RCP) *.lua evernote $(CURDIR)/$(EVERNOTE_PLUGIN_DIR) && \
		cp thrift/*.lua $(CURDIR)/$(EVERNOTE_THRIFT_DIR)
endif
	test -e $(LPEG_RE) && chmod 664 $(LPEG_RE) || true  # hot fix re.lua permission

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
	$(OUTPUT_DIR)/libs/libkoreader-lfs.so \
	$(if $(ANDROID),,$(OUTPUT_DIR)/libs/libkoreader-djvu.so) \
	$(OUTPUT_DIR)/libs/libkoreader-cre.so \
	$(OUTPUT_DIR)/libs/libwrap-mupdf.so

$(OUTPUT_DIR)/libs/libkoreader-input.so: input/*.c input/*.h $(if $(KINDLE),$(POPEN_NOSHELL_LIB),)
	@echo "Building koreader input module..."
	$(CC) $(DYNLIB_CFLAGS) -I$(POPEN_NOSHELL_DIR) -I./input \
		$(if $(KOBO),-DKOBO,) $(if $(KINDLE),-DKINDLE,) $(if $(POCKETBOOK),-DPOCKETBOOK,) \
		-o $@ \
		input/input.c \
		$(if $(KINDLE),$(POPEN_NOSHELL_LIB),) \
		$(if $(POCKETBOOK),-linkview,)

$(OUTPUT_DIR)/libs/libkoreader-lfs.so: \
			$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
			luafilesystem/src/lfs.c
	$(CC) $(DYNLIB_CFLAGS) -o $@ $^

# put all the libs to the end of compile command to make ubuntu's tool chain
# happy
$(OUTPUT_DIR)/libs/libkoreader-djvu.so: djvu.c \
			$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
			$(DJVULIBRE_LIB) $(K2PDFOPT_LIB)
	$(CC) -I$(DJVULIBRE_DIR) -I$(MUPDF_DIR)/include $(K2PDFOPT_CFLAGS) \
		$(DYNLIB_CFLAGS) -o $@ $^ $(if $(ANDROID),,-lpthread)
ifdef DARWIN
	install_name_tool -change /usr/local/lib/$(notdir $(DJVULIBRE_LIB)) \
		libs/$(notdir $(DJVULIBRE_LIB)) $@
	install_name_tool -change $(notdir $(K2PDFOPT_LIB)) \
		libs/$(notdir $(K2PDFOPT_LIB)) $@
endif

$(OUTPUT_DIR)/libs/libkoreader-cre.so: cre.cpp \
			$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
			$(CRENGINE_LIB)
	$(CXX) -I$(CRENGINE_SRC_DIR)/crengine/include/ $(DYNLIB_CFLAGS) \
		-DLDOM_USE_OWN_MEM_MAN=$(if $(WIN32),0,1) \
		$(if $(WIN32),-DQT_GL=1) -static-libstdc++ -o $@ $^
ifdef DARWIN
	install_name_tool -change $(notdir $(CRENGINE_LIB)) \
		libs/$(notdir $(CRENGINE_LIB)) $@
endif

$(OUTPUT_DIR)/libs/libwrap-mupdf.so: wrap-mupdf.c \
			$(MUPDF_LIB)
	$(CC) -I$(MUPDF_DIR)/include $(DYNLIB_CFLAGS) -o $@ $^

ffi/mupdf_h.lua: ffi-cdecl/mupdf_decl.c $(MUPDF_DIR)/include
	CPPFLAGS="$(CFLAGS) -I. -I$(MUPDF_DIR)/include" $(FFI_CDECL) gcc ffi-cdecl/mupdf_decl.c $@

ffi/SDL2_0_h.lua: ffi-cdecl/SDL2_0_decl.c
	CPPFLAGS="$(CFLAGS) -I. -LSDL2" $(FFI_CDECL) gcc ffi-cdecl/SDL2_0_decl.c $@

ffi/lodepng_h.lua: ffi-cdecl/lodepng_decl.c $(LODEPNG_DIR)
	CPPFLAGS="$(CFLAGS) -I. -I$(LODEPNG_DIR)" $(FFI_CDECL) gcc ffi-cdecl/lodepng_decl.c $@

# include all third party libs
include Makefile.third

# ===========================================================================
# the attachment extraction tool:

$(OUTPUT_DIR)/extr: extr.c $(MUPDF_LIB) $(MUPDF_DIR)/include $(JPEG_LIB) $(FREETYPE_LIB)
	$(CC) -I$(MUPDF_DIR) -I$(MUPDF_DIR)/include \
		$(CFLAGS) -Wl,-rpath,'libs' -o $@ $^

# ===========================================================================
# helper target for creating standalone android toolchain from NDK
# NDK variable should be set in your environment and it should point to
# the root directory of the NDK
android-toolchain:
ifeq ($(wildcard $(NDK)/build/tools/make_standalone_toolchain.py),)
	install -d $(ANDROID_TOOLCHAIN)
	$(NDK)/build/tools/make-standalone-toolchain.sh --platform=android-$(NDKABI) \
		--install-dir=$(ANDROID_TOOLCHAIN)
else
	$(NDK)/build/tools/make_standalone_toolchain.py --force --install-dir=$(ANDROID_TOOLCHAIN) \
		--arch arm --api $(NDKABI)
endif

# ===========================================================================
# helper target for creating standalone pocket toolchain from
# pocketbook-free SDK: https://github.com/pocketbook-free/SDK_481

pocketbook-toolchain:
	install -d toolchain
	cd toolchain && \
		git clone https://github.com/pocketbook-free/SDK_481 pocketbook-toolchain

# ===========================================================================
# helper target for initializing third-party code

clean:
	-rm -rf $(OUTPUT_DIR)/*
	-rm -rf $(THIRDPARTY_DIR)/{$(CMAKE_THIRDPARTY_LIBS)}/build/$(MACHINE)

dist-clean:
	-rm -rf build
	-rm -rf $(THIRDPARTY_DIR)/{$(CMAKE_THIRDPARTY_LIBS)}/build

# ===========================================================================
# start of unit tests section

$(OUTPUT_DIR)/.busted:
	test -e $(OUTPUT_DIR)/.busted || \
		ln -sf ../../.busted $(OUTPUT_DIR)/

$(OUTPUT_DIR)/spec/base:
	install -d $(OUTPUT_DIR)/spec
	test -e $(OUTPUT_DIR)/spec/base || \
		ln -sf ../../../spec $(OUTPUT_DIR)/spec/base

test: $(OUTPUT_DIR)/spec $(OUTPUT_DIR)/.busted
	cd $(OUTPUT_DIR) && \
		./luajit $(shell which busted) \
		--exclude-tags=notest \
		--no-auto-insulate \
		-o ./spec/base/unit/verbose_print ./spec/base/unit

.PHONY: test
