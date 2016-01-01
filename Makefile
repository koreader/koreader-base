include Makefile.defs

# main target
all: $(OUTPUT_DIR)/libs $(if $(ANDROID),,$(LUAJIT)) \
		$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
		$(LUAJIT_JIT) \
		libs $(K2PDFOPT_LIB) \
		$(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/common $(OUTPUT_DIR)/rocks \
		$(OUTPUT_DIR)/plugins $(LUASOCKET) \
		$(if $(WIN32),,$(LUASEC)) \
		$(if $(ANDROID),luacompat52 lualongnumber,) \
		$(if $(WIN32),,$(EVERNOTE_LIB)) \
		$(LUASERIAL_LIB) \
		$(TURBOJPEG_LIB) \
		$(LODEPNG_LIB) \
		$(GIF_LIB) \
		$(TURBO_FFI_WRAP_LIB) \
		$(LUA_SPORE_ROCK) \
		$(if $(ANDROID),lpeg,) \
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/zsync) \
		$(if $(WIN32), ,$(ZMQ_LIB) $(CZMQ_LIB) $(FILEMQ_LIB) $(ZYRE_LIB))
ifndef EMULATE_READER
	STRIP_FILES="\
		$(if $(WIN32),,$(OUTPUT_DIR)/sdcv) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/zsync) \
		$(if $(ANDROID),,$(LUAJIT)) \
		$(OUTPUT_DIR)/libs/$(if $(WIN32),*.dll,*.so*)" ;\
	$(STRIP) --strip-unneeded $${STRIP_FILES} ;\
	touch -r $${STRIP_FILES}  # let all files have the same mtime
	find $(OUTPUT_DIR)/common -name "$(if $(WIN32),*.dll,*.so*)" | \
		xargs $(STRIP) --strip-unneeded
endif
	# set up some needed paths and links
	test -e $(OUTPUT_DIR)/data || \
		ln -sf ../../kpvcrlib/crengine/cr3gui/data $(OUTPUT_DIR)/data
	test -d $(OUTPUT_DIR)/cache || mkdir $(OUTPUT_DIR)/cache
	test -d $(OUTPUT_DIR)/history || mkdir $(OUTPUT_DIR)/history
	test -d $(OUTPUT_DIR)/clipboard || mkdir $(OUTPUT_DIR)/clipboard
	# /$(OUTPUT_DIR)/data is a soft link to /kpvcrlib/crengine/cr3gui/data
	# while cr3.css is in /kpvcrlib, so we need three ".."
	test -e $(OUTPUT_DIR)/data/cr3.css || \
		ln -sf ../../../cr3.css $(OUTPUT_DIR)/data/
	test -d $(OUTPUT_DIR)/fonts || ( \
			mkdir $(OUTPUT_DIR)/fonts \
		)
	test -e $(OUTPUT_DIR)/ffi || \
		ln -sf ../../ffi $(OUTPUT_DIR)/
	# setup Evernote SDK
	mkdir -p $(CURDIR)/$(EVERNOTE_THRIFT_DIR)
	cd $(EVERNOTE_SDK_DIR) && cp -r *.lua evernote $(CURDIR)/$(EVERNOTE_PLUGIN_DIR) \
		&& cp thrift/*.lua $(CURDIR)/$(EVERNOTE_THRIFT_DIR)

$(OUTPUT_DIR)/libs:
	mkdir -p $(OUTPUT_DIR)/libs

$(OUTPUT_DIR)/common:
	mkdir -p $(OUTPUT_DIR)/common

$(OUTPUT_DIR)/rocks:
	mkdir -p $(OUTPUT_DIR)/rocks

$(OUTPUT_DIR)/plugins:
	mkdir -p $(OUTPUT_DIR)/plugins

# ===========================================================================

# third party libraries:
# (for directory and file name config, see Makefile.defs)

$(FREETYPE_LIB) $(FREETYPE_DIR)/include: $(THIRDPARTY_DIR)/freetype2/CMakeLists.txt
	-mkdir -p $(FREETYPE_BUILD_DIR)
	cd $(FREETYPE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" -DCFLAGS="$(CFLAGS)"\
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DCHOST=$(CHOST) -DMACHINE=$(MACHINE) \
		$(CURDIR)/$(THIRDPARTY_DIR)/freetype2 && \
		$(MAKE)
	cp -fL $(FREETYPE_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(FREETYPE_LIB)) $@

# libjpeg-turbo and libjepg
$(TURBOJPEG_LIB) $(JPEG_LIB): $(THIRDPARTY_DIR)/libjpeg-turbo/CMakeLists.txt
	-mkdir -p $(JPEG_BUILD_DIR)
	cd $(JPEG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" \
		-DCPPFLAGS="$(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		$(if $(findstring armv6, $(ARM_ARCH)),-DWITHOUT_SIMD:BOOL=ON,) \
		-DCHOST="$(if $(ANDROID),"arm-linux",$(CHOST))" -DMACHINE=$(MACHINE) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libjpeg-turbo && \
		$(MAKE)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(TURBOJPEG_LIB)) $(TURBOJPEG_LIB)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(JPEG_LIB)) $(JPEG_LIB)

$(PNG_LIB): $(ZLIB) $(THIRDPARTY_DIR)/libpng/CMakeLists.txt
	-mkdir -p $(PNG_BUILD_DIR)
	cd $(PNG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" \
		-DCPPFLAGS="$(CFLAGS) -I$(ZLIB_DIR)" \
		-DLDFLAGS="$(LDFLAGS) -L$(ZLIB_DIR)" \
		-DCHOST="$(CHOST)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/libpng && \
		$(MAKE)
	cp -fL $(PNG_DIR)/.libs/$(notdir $(PNG_LIB)) $@

$(AES_LIB): $(THIRDPARTY_DIR)/minizip/CMakeLists.txt
	-mkdir -p $(MINIZIP_BUILD_DIR)
	-rm -f $(MINIZIP_DIR)/../minizip-stamp/minizip-build
	cd $(MINIZIP_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DAR="$(AR)" -DRANLIB="$(RANLIB)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/minizip && \
		$(MAKE)

# by default, mupdf compiles to a static library:
# we generate a dynamic library from the static library:
$(MUPDF_LIB) $(MUPDF_DIR)/include: $(JPEG_LIB) \
		$(FREETYPE_LIB) $(FREETYPE_DIR)/include \
		$(ZLIB) $(AES_LIB) $(THIRDPARTY_DIR)/mupdf/CMakeLists.txt
	-mkdir -p $(MUPDF_BUILD_DIR)
	-rm -f $(MUPDF_DIR)/../mupdf-stamp/mupdf-build
	cd $(MUPDF_BUILD_DIR) && \
		$(CMAKE) -DHOSTCFLAGS="$(HOSTCFLAGS)" -DHOSTCC="$(HOSTCC)" \
		-DCC="$(CC)" -DCFLAGS="$(CFLAGS)" -DOS="$(if $(WIN32),,Other)" \
		-DLDFLAGS="$(LDFLAGS) -L$(CURDIR)/$(OUTPUT_DIR)" \
		-DXCFLAGS="$(CFLAGS) -DNOBUILTINFONT -I$(JPEG_DIR)/include -I$(FREETYPE_DIR)/include/freetype2 -I$(ZLIB_DIR) -I$(MINIZIP_DIR)" \
		-DMUPDF_LIB_STATIC=$(MUPDF_LIB_STATIC) \
		-DMUPDF_JS_LIB_STATIC=$(MUPDF_JS_LIB_STATIC) \
		-DMUPDF_THIRDPARTY_LIBS=$(MUPDF_THIRDPARTY_LIBS) \
		-DMUPDF_LIB=$(CURDIR)/$(MUPDF_LIB) $(if $(ANDROID),-DANDROID:BOOL=ON,) \
		-DMUPDF_SONAME=$(notdir $(MUPDF_LIB)) \
		-DZLIB=$(CURDIR)/$(ZLIB) -DJPEG_LIB=$(CURDIR)/$(JPEG_LIB) \
		-DFREETYPE_LIB=$(CURDIR)/$(FREETYPE_LIB) \
		-DMACHINE=$(MACHINE) \
		$(CURDIR)/$(THIRDPARTY_DIR)/mupdf && \
		$(MAKE)

$(LODEPNG_LIB): $(THIRDPARTY_DIR)/lodepng/CMakeLists.txt
	-mkdir -p $(LODEPNG_BUILD_DIR)
	-rm -f $(LODEPNG_DIR)/../lodepng-stamp/lodepng-build
	cd $(LODEPNG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS)" \
		-DSONAME="$(notdir $(LODEPNG_LIB))" -DMACHINE="$(MACHINE)" \
		-DOUTPUT_PATH="$(CURDIR)/$(dir $(LODEPNG_LIB))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/lodepng && \
		$(MAKE)

$(GIF_LIB): $(THIRDPARTY_DIR)/giflib/CMakeLists.txt
	test -e $(GIF_BUILD_DIR) || mkdir -p $(GIF_BUILD_DIR)
	cd $(GIF_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(if $(ANDROID),-DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR,)" \
		-DCFLAGS="$(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DCHOST="$(CHOST)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/thirdparty/giflib && \
		$(MAKE)
	cp -fL $(GIF_DIR)/lib/$(notdir $(GIF_LIB)) $@

$(DJVULIBRE_LIB): $(JPEG_LIB) $(THIRDPARTY_DIR)/djvulibre/CMakeLists.txt
	-mkdir -p $(DJVULIBRE_BUILD_DIR)
	cd $(DJVULIBRE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" -DCFLAGS="$(CFLAGS)" \
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DLIBS="$(if $(ANDROID),$(SYSROOT)/usr/lib/,)$(STATIC_LIBSTDCPP)" \
		-DCHOST="$(if $(EMULATE_READER),,$(CHOST))" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/djvulibre && \
		$(MAKE)
	cp -fL $(DJVULIBRE_LIB_DIR)/$(notdir $(DJVULIBRE_LIB)) $(DJVULIBRE_LIB)

# crengine, fetched via GIT as a submodule
$(CRENGINE_LIB): $(ZLIB) $(PNG_LIB) $(FREETYPE_LIB) $(JPEG_LIB)
	# make clean build of crengine
	rm -rf $(CRENGINE_WRAPPER_DIR)/build
	mkdir -p $(CRENGINE_WRAPPER_DIR)/build
	cd $(CRENGINE_WRAPPER_DIR)/build \
	&& CC="$(CC)" CXX="$(CXX)" RC="$(RC)" \
		CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS) -static-libstdc++" \
		JPEG_LIB="$(CURDIR)/$(JPEG_LIB)" \
		PNG_LIB="$(CURDIR)/$(PNG_LIB)" \
		FREETYPE_LIB="$(CURDIR)/$(FREETYPE_LIB)" \
		ZLIB="$(CURDIR)/$(ZLIB)" \
		LIBS_DIR="$(CURDIR)/$(OUTPUT_DIR)/libs" \
		cmake -DJPEGLIB_INCLUDE_DIR=$(JPEG_DIR)/include \
		-DPNG_INCLUDE_DIR="$(PNG_DIR)/include" \
		-DZLIB_INCLUDE_DIR="$(ZLIB_DIR)/include" \
		-DFREETYPE_INCLUDE_DIR="$(FREETYPE_DIR)/include/freetype2" \
		-DMACHINE="$(MACHINE)" -DCMAKE_BUILD_TYPE=Release \
		$(if $(WIN32),-DCMAKE_SYSTEM_NAME=Windows,) ..
	cd $(CRENGINE_WRAPPER_DIR)/build &&  $(MAKE)
	cp -fL $(CRENGINE_WRAPPER_DIR)/build/$(notdir $(CRENGINE_LIB)) \
		$(CRENGINE_LIB)

# LuaJIT, fetched via GIT as a submodule
$(LUAJIT) $(LUAJIT_LIB):
ifdef EMULATE_READER
	$(MAKE) -j$(PROCESSORS) -C $(LUA_DIR)
else
	# To recap: build its TARGET_CC from CROSS+CC, so we need HOSTCC in CC.
	# Build its HOST/TARGET_CFLAGS based on CFLAGS, so we need
	# a neutral CFLAGS without arch
	$(MAKE) -j$(PROCESSORS) -C $(LUA_DIR) \
		CC="$(HOSTCC)" HOST_CC="$(HOSTCC) -m32" \
		CFLAGS="$(BASE_CFLAGS)" HOST_CFLAGS="$(HOSTCFLAGS)" \
		$(if $(WIN32),LDFLAGS="$(LDFLAGS)",) \
		$(if $(WIN32),TARGET_SYS=Windows,) \
		TARGET_SONAME=$(notdir $(LUAJIT_LIB)) \
		TARGET_CFLAGS="$(CFLAGS)" \
		TARGET_FLAGS="-DLUAJIT_NO_LOG2 -DLUAJIT_NO_EXP2" \
		CROSS="$(strip $(CCACHE) $(CHOST))-" amalg
endif
ifdef WIN32
	cp -fL $(LUA_DIR)/src/$(notdir $(LUAJIT_LIB)) $(LUAJIT_LIB)
endif
ifdef ANDROID
	cp -fL $(LUA_DIR)/src/$(notdir $(LUAJIT_LIB)) $(LUAJIT_LIB)
else
	cp -fL $(LUA_DIR)/src/$(notdir $(LUAJIT)) $(LUAJIT)
endif

$(LUAJIT_JIT): $(if $(ANDROID),$(LUAJIT_LIB),$(LUAJIT))
	cp -rfL $(LUA_DIR)/src/jit $(OUTPUT_DIR)

$(POPEN_NOSHELL_LIB): $(THIRDPARTY_DIR)/popen-noshell/CMakeLists.txt
	-mkdir -p $(POPEN_NOSHELL_BUILD_DIR)
	cd $(POPEN_NOSHELL_BUILD_DIR) && \
		$(CMAKE) $(if $(LEGACY),-DLEGACY:BOOL=ON,) \
		-DCC="$(CC)" -DAR="$(AR)" \
		-DCFLAGS="$(CFLAGS) $(if $(ANDROID),--sysroot=$(SYSROOT),)" \
		-DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/popen-noshell && \
		$(MAKE)

# k2pdfopt depends on leptonica and tesseract
$(LEPTONICA_DIR): $(THIRDPARTY_DIR)/leptonica/CMakeLists.txt
	-mkdir -p $(LEPTONICA_BUILD_DIR)
	cd $(LEPTONICA_BUILD_DIR) && \
		$(CMAKE) -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/leptonica && \
		$(MAKE)

$(TESSERACT_DIR): $(THIRDPARTY_DIR)/tesseract/CMakeLists.txt
	-mkdir -p $(TESSERACT_BUILD_DIR)
	cd $(TESSERACT_BUILD_DIR) && \
		$(CMAKE) -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/tesseract && \
		$(MAKE)

$(K2PDFOPT_LIB) $(LEPTONICA_LIB) $(TESSERACT_LIB): $(PNG_LIB) $(ZLIB) \
		$(THIRDPARTY_DIR)/libk2pdfopt/CMakeLists.txt \
		$(TESSERACT_DIR) $(LEPTONICA_DIR)
	-mkdir -p $(K2PDFOPT_BUILD_DIR)
	cd $(K2PDFOPT_BUILD_DIR) && \
		$(CMAKE) $(if $(EMULATE_READER),,-DHOST="$(if $(ANDROID),"arm-linux",$(CHOST))") \
		-DCC="$(CC)" -DCFLAGS="$(CFLAGS)" -DCXX="$(CXX)" -DCXXFLAGS="$(CXXFLAGS) -O3" \
		-DAR="$(AR)" -DLDFLAGS="$(LDFLAGS)" -DMACHINE="$(MACHINE)" \
		-DSTDCPPLIB="$(if $(ANDROID),$(SYSROOT)/usr/lib/,)$(STATIC_LIBSTDCPP)" \
		-DZLIB_DIR=$(ZLIB_DIR) -DZLIB=$(CURDIR)/$(ZLIB) -DPNG_DIR=$(PNG_DIR) \
		-DLEPTONICA_DIR=$(LEPTONICA_DIR) -DTESSERACT_DIR=$(TESSERACT_DIR) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libk2pdfopt && \
		$(MAKE)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(K2PDFOPT_LIB)) $(K2PDFOPT_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(LEPTONICA_LIB)) $(LEPTONICA_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(TESSERACT_LIB)) $(TESSERACT_LIB)

# end of third-party code
# ===========================================================================

# our own Lua/C/C++ interfacing:

libs: \
	$(if $(or $(SDL),$(ANDROID)),,$(OUTPUT_DIR)/libs/libkoreader-input.so) \
	$(OUTPUT_DIR)/libs/libkoreader-lfs.so \
	$(if $(ANDROID),,$(OUTPUT_DIR)/libs/libkoreader-djvu.so) \
	$(OUTPUT_DIR)/libs/libkoreader-cre.so \
	$(OUTPUT_DIR)/libs/libwrap-mupdf.so

$(OUTPUT_DIR)/libs/libkoreader-input.so: input.c $(POPEN_NOSHELL_LIB)
	$(CC) $(DYNLIB_CFLAGS) -I$(POPEN_NOSHELL_DIR) $(if $(POCKETBOOK),-DPOCKETBOOK,) \
		-o $@ $^ $(if $(POCKETBOOK),-linkview,) \

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

$(OUTPUT_DIR)/libs/libkoreader-cre.so: cre.cpp \
			$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
			$(CRENGINE_LIB)
	$(CXX) -I$(CRENGINE_DIR)/crengine/include/ $(DYNLIB_CFLAGS) \
		-DLDOM_USE_OWN_MEM_MAN=$(if $(WIN32),0,1) \
		$(if $(WIN32),-DQT_GL=1) \
		-Wl,-rpath,'libs' -static-libstdc++ -o $@ $^

$(OUTPUT_DIR)/libs/libwrap-mupdf.so: wrap-mupdf.c \
			$(MUPDF_LIB)
	$(CC) -I$(MUPDF_DIR)/include $(DYNLIB_CFLAGS) \
		-o $@ $^

ffi/mupdf_h.lua: ffi-cdecl/mupdf_decl.c $(MUPDF_DIR)/include
	CPPFLAGS="$(CFLAGS) -I. -I$(MUPDF_DIR)/include" $(FFI-CDECL) gcc ffi-cdecl/mupdf_decl.c ffi/mupdf_h.lua

# ===========================================================================
# the attachment extraction tool:

$(OUTPUT_DIR)/extr: extr.c $(MUPDF_LIB) $(MUPDF_DIR)/include $(JPEG_LIB) $(FREETYPE_LIB)
	$(CC) -I$(MUPDF_DIR) -I$(MUPDF_DIR)/include \
		$(CFLAGS) -Wl,-rpath,'libs' -o $@ $^

# ===========================================================================
# sdcv dependencies: glib-2.0 and zlib

# libiconv for glib on android
$(LIBICONV): $(THIRDPARTY_DIR)/libiconv/CMakeLists.txt
	-mkdir -p $(LIBICONV_BUILD_DIR)
	cd $(LIBICONV_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" \
		-DHOST="$(if $(EMULATE_READER),,$(if $(ANDROID),"arm-linux",$(CHOST)))" \
		-DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/libiconv && \
		$(MAKE)

# libgettext for glib on android
$(LIBGETTEXT): $(LIBICONV) $(THIRDPARTY_DIR)/gettext/CMakeLists.txt
	-mkdir -p $(GETTEXT_BUILD_DIR)
	cd $(GETTEXT_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" \
		-DLIBICONV_PREFIX=$(LIBICONV_DIR) -DMACHINE=$(MACHINE) \
		-DCHOST_OPTS="$(if $(EMULATE_READER),,--host=$(if $(ANDROID),arm-linux,$(CHOST)))" \
		$(if $(ANDROID),-DIS_ANDROID:BOOL=on,) \
		$(CURDIR)/thirdparty/gettext && \
		$(MAKE)

$(LIBFFI_DIR)/include:
	-mkdir -p $(LIBFFI_BUILD_DIR)
	cd $(LIBFFI_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DMACHINE="$(MACHINE)" -DHOST="$(CHOST)" \
		$(if $(ANDROID),-DSYSROOT="$(SYSROOT)",) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libffi && \
		$(MAKE)

$(GLIB): $(LIBFFI_DIR)/include $(THIRDPARTY_DIR)/glib/CMakeLists.txt
	-mkdir -p $(GLIB_BUILD_DIR)
	-rm -f $(GLIB_DIR)/../glib-stamp/glib-install
	cd $(GLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" -DMACHINE="$(MACHINE)" \
		-DCFLAGS="$(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DLIBFFI_DIR="$(LIBFFI_DIR)" -DZLIB_DIR="$(ZLIB_DIR)" \
		-DWITH_LIBICONV="no" -DENABLE_SHARED="glib" \
		-DHOST_OPTS="$(if $(EMULATE_READER),,--host=$(CHOST) --cache-file=arm_cache.conf)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/glib && \
		$(MAKE)
ifdef POCKETBOOK
	cp -fL $(GLIB_DIR)/lib/$(notdir $(GLIB)) $(OUTPUT_DIR)/libs/$(notdir $(GLIB))
endif

$(GLIB_STATIC): $(LIBICONV) $(LIBGETTEXT) $(LIBFFI_DIR)/include $(THIRDPARTY_DIR)/glib/CMakeLists.txt
	-mkdir -p $(GLIB_BUILD_DIR)
	-rm -f $(GLIB_DIR)/../glib-stamp/glib-install
	cd $(GLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" -DMACHINE="$(MACHINE)" \
		-DLDFLAGS="$(LDFLAGS) $(if $(ANDROID), \
			-L$(LIBICONV_DIR)/lib -L$(GETTEXT_DIR)/lib,)" \
		-DCFLAGS="$(CFLAGS) $(if $(ANDROID), \
			-I$(LIBICONV_DIR)/include -I$(GETTEXT_DIR)/include,)" \
 		-DLIBFFI_DIR="$(LIBFFI_DIR)" -DZLIB_DIR="$(ZLIB_DIR)" \
		-DWITH_LIBICONV="gnu" -DENABLE_SHARED="false" \
		-DHOST_OPTS="$(if $(EMULATE_READER),,--host=$(CHOST) --cache-file=arm_cache.conf)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/glib && \
		$(MAKE)

$(ZLIB) $(ZLIB_STATIC): $(THIRDPARTY_DIR)/zlib/CMakeLists.txt
	-mkdir -p $(ZLIB_BUILD_DIR)
	-rm -f $(ZLIB_DIR)/../zlib-stamp/zlib-install
ifdef WIN32
	cd $(ZLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCHOST="$(CHOST)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/thirdparty/zlib && \
		$(MAKE)
	cp -fL $(ZLIB_DIR)/$(notdir $(ZLIB)) $(ZLIB)
else
	cd $(ZLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCHOST="$(CHOST)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/thirdparty/zlib && \
		$(MAKE)
	cp -fL $(ZLIB_DIR)/lib/$(notdir $(ZLIB)) $(ZLIB)
endif

# ===========================================================================
# console version of StarDict(sdcv)
ifeq ("$(shell $(CC) -dumpmachine | sed s/-.*//)","x86_64")
PAGE_SIZE_CFG=-D64BIT_PAGE:BOOL=on
endif
$(OUTPUT_DIR)/sdcv: $(if $(ANDROID),$(GLIB_STATIC),$(GLIB)) $(ZLIB_STATIC) $(THIRDPARTY_DIR)/sdcv/CMakeLists.txt
	-mkdir -p $(SDCV_BUILD_DIR)
	cd $(SDCV_BUILD_DIR) && \
		$(CMAKE) -DHOST="$(if $(EMULATE_READER),,$(CHOST))" -DMACHINE="$(MACHINE)" \
		$(PAGE_SIZE_CFG) -DPKG_CONFIG_PATH="$(GLIB_DIR)/lib/pkgconfig" \
		-DCXX="$(CXX) $(if $(ANDROID),-D_GETOPT_DEFINED,)" \
		-DCXXFLAGS="$(CXXFLAGS) -I$(ZLIB_DIR) $(if $(ANDROID), \
			-I$(LIBICONV_DIR)/include -I$(GETTEXT_DIR)/include,)" \
		-DLDFLAGS="$(LDFLAGS) -L$(ZLIB_DIR) $(if $(ANDROID), \
			-L$(LIBICONV_DIR)/lib -L$(GETTEXT_DIR)/lib,)" \
		-DLIBS="$(if $(ANDROID),$(GLIB_STATIC),) \
			$(if $(ANDROID),,-lpthread -lrt) \
			$(ZLIB_STATIC) \
			-static-libgcc -static-libstdc++" \
		$(CURDIR)/$(THIRDPARTY_DIR)/sdcv && \
		$(MAKE)
	cp $(SDCV_DIR)/src/sdcv $(OUTPUT_DIR)/

# ===========================================================================
# tar: tar package for zsync

$(OUTPUT_DIR)/tar: $(THIRDPARTY_DIR)/tar/CMakeLists.txt
	-mkdir -p $(TAR_BUILD_DIR)
	cd $(TAR_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DLIBS="$(if $(WIN32),,-lrt)" \
		$(if $(LEGACY),-DDISABLE_LARGEFILE:BOOL=ON -DDISABLE_FORTIFY:BOOL=ON,) \
		-DCHOST="$(if $(EMULATE_READER),,$(CHOST))" -DMACHINE=$(MACHINE) \
		$(CURDIR)/$(THIRDPARTY_DIR)/tar && \
		$(MAKE)
	cp $(TAR_DIR)/src/tar $(OUTPUT_DIR)/

# ===========================================================================
# zsync: rsync over HTTP

$(OUTPUT_DIR)/zsync: $(THIRDPARTY_DIR)/zsync/CMakeLists.txt
	-mkdir -p $(ZSYNC_BUILD_DIR)
	cd $(ZSYNC_BUILD_DIR) && \
		$(CMAKE) -DHOST="$(if $(EMULATE_READER),,$(CHOST))" \
		-DCC="$(CC)" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/zsync && \
		$(MAKE) VERBOSE=1
	cp $(ZSYNC_DIR)/zsync $(OUTPUT_DIR)/

# ===========================================================================
# common lua library for networking
$(LUASOCKET): $(THIRDPARTY_DIR)/luasocket/CMakeLists.txt
	-rm -rf $(LUASOCKET) $(LUASOCKET_BUILD_DIR)
	-mkdir -p $(LUASOCKET_BUILD_DIR)
	cd $(LUASOCKET_BUILD_DIR) && \
		$(CMAKE) -DPLAT="$(if $(WIN32),mingw,linux)" \
		-DCC="$(CC) $(CFLAGS)" -DMACHINE="$(MACHINE)" \
		$(if $(ANDROID),-DMYLDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),-DLUALIB_mingw="$(CURDIR)/$(LUAJIT_LIB)",) \
		-DLUAINC="$(CURDIR)/$(LUA_DIR)/src" \
		-DINSTALL_DIR="$(CURDIR)/$(OUTPUT_DIR)/common" \
		$(CURDIR)/$(THIRDPARTY_DIR)/luasocket && \
		$(MAKE)

$(OPENSSL_LIB) $(OPENSSL_DIR): $(THIRDPARTY_DIR)/openssl/CMakeLists.txt
	-mkdir -p $(OPENSSL_BUILD_DIR)
	-rm -f $(OPENSSL_DIR)/../openssl-stamp/openssl-build
	cd $(OPENSSL_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" \
		-DSHARED_LDFLAGS="$(LDFLAGS) -Wl,-rpath,'libs'" \
		-DLD="$(LD)" -DRANLIB="$(RANLIB)" \
		-DCONFIG_SCRIPT="$(if $(EMULATE_READER),config,Configure $(if $(WIN32),mingw,linux-generic32))" \
		-DMACHINE="$(MACHINE)" -DCHOST="$(CHOST)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/openssl && \
		$(MAKE)

$(SSL_LIB): $(OPENSSL_LIB)
	cp -fL $(OPENSSL_DIR)/$(notdir $(SSL_LIB)) $(SSL_LIB)
	cp -fL $(OPENSSL_DIR)/$(notdir $(CRYPTO_LIB)) $(CRYPTO_LIB)

$(LUASEC): $(OPENSSL_DIR) $(THIRDPARTY_DIR)/luasec/CMakeLists.txt
	-mkdir -p $(LUASEC_BUILD_DIR)
	-rm -f $(LUASEC_DIR)/../luasec-stamp/luasec-install
	cd $(LUASEC_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" -DLD="$(CC) -Wl,-rpath,'libs'" \
		$(if $(ANDROID),-DLIBS="-lssl -lcrypto -lluasocket $(CURDIR)/$(LUAJIT_LIB)",) \
		-DINC_PATH="-I$(CURDIR)/$(LUA_DIR)/src -I$(OPENSSL_DIR)/include" \
		-DLIB_PATH="-L$(OPENSSL_DIR)" -DMACHINE="$(MACHINE)" \
		-DLUAPATH="$(CURDIR)/$(OUTPUT_DIR)/common" \
		$(CURDIR)/$(THIRDPARTY_DIR)/luasec && \
		$(MAKE)

$(EVERNOTE_LIB):
	$(MAKE) -C $(EVERNOTE_SDK_DIR)/thrift CC="$(CC) $(CFLAGS)" \
		$(if $(ANDROID),LDFLAGS="$(LDFLAGS) -lm $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),LDFLAGS="$(LDFLAGS) -lm $(CURDIR)/$(LUAJIT_LIB)",) \
		OUTPUT_DIR=$(CURDIR)/$(EVERNOTE_PLUGIN_DIR)/lib

$(LUASERIAL_LIB): $(THIRDPARTY_DIR)/lua-serialize/CMakeLists.txt
	-mkdir -p $(LUASERIAL_BUILD_DIR)
	-rm -f $(LUASERIAL_DIR)/../lua-serialize-stamp/lua-serialize-build
	-rm -f $(LUASERIAL_LIB)
	cd $(LUASERIAL_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" -DMACHINE="$(MACHINE)" \
		-DLDFLAGS="$(LDFLAGS)$(if $(or $(ANDROID),$(WIN32)), $(CURDIR)/$(LUAJIT_LIB),)" \
		-DOUTPUT_DIR=$(CURDIR)/$(OUTPUT_DIR)/common \
		$(CURDIR)/$(THIRDPARTY_DIR)/lua-serialize && \
		$(MAKE)

luacompat52: $(LUASERIAL_LIB)
	cp $(CURDIR)/$(OUTPUT_DIR)/common/libluacompat52.so \
		$(CURDIR)/$(OUTPUT_DIR)/libs

lualongnumber: $(EVERNOTE_LIB)
	cp $(CURDIR)/$(EVERNOTE_PLUGIN_DIR)/lib/liblualongnumber.so \
		$(CURDIR)/$(OUTPUT_DIR)/libs

# zeromq should be compiled without optimization in clang 3.4
# which otherwise may throw a warning saying "array index is past the end
# of the array" for strcmp comparing a string with exactly 2 chars.
# More details about this bug:
# https://gcc.gnu.org/ml/gcc-help/2009-10/msg00191.html
$(ZMQ_LIB): $(THIRDPARTY_DIR)/libzmq/CMakeLists.txt
	-mkdir -p $(ZMQ_BUILD_DIR)
	cd $(ZMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" \
		-DLDFLAGS="$(LDFLAGS)" \
		-DSTATIC_LIBSTDCPP="$(if $(ANDROID),$(SYSROOT)/usr/lib/,)$(STATIC_LIBSTDCPP)" \
		$(if $(LEGACY),-DLEGACY:BOOL=ON,) \
		-DCHOST=$(CHOST) -DMACHINE=$(MACHINE) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libzmq && \
		$(MAKE)
	cp -fL $(ZMQ_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(ZMQ_LIB)) $@
ifdef POCKETBOOK
	# when cross compiling libtool would find libstdc++.la in wrong location
	# accoding to the GCC configuration
	sed -i 's|^dependency_libs=.*|dependency_libs=" -lrt -lpthread -lstdc++"|g' \
		$(ZMQ_DIR)/lib/libzmq.la
	# and the libuuid.so is also missing in the PocketBook SDK, but libuuid.la
	# may let the build system assume that libuuid is installed
	rm -f $(CURDIR)/$(POCKETBOOK_TOOLCHAIN)/arm-obreey-linux-gnueabi/sysroot/usr/lib/libuuid*
endif

$(CZMQ_LIB): $(ZMQ_LIB) $(THIRDPARTY_DIR)/czmq/CMakeLists.txt
	-mkdir -p $(CZMQ_BUILD_DIR)
	cd $(CZMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DLDFLAGS="$(LDFLAGS) -Wl,-rpath,'libs'" \
		-DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) $(if $(WIN32),-DLIBCZMQ_EXPORTS)" \
		-DZMQ_DIR=$(ZMQ_DIR) -DHOST=$(CHOST) -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/czmq && \
		$(MAKE)
	cp -fL $(CZMQ_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(CZMQ_LIB)) $@

$(FILEMQ_LIB): $(ZMQ_LIB) $(CZMQ_LIB) $(SSL_LIB) $(THIRDPARTY_DIR)/filemq/CMakeLists.txt
	-mkdir -p $(FILEMQ_BUILD_DIR)
	cd $(FILEMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) -I$(OPENSSL_DIR)/include" \
		-DLDFLAGS="$(LDFLAGS) -L$(OPENSSL_DIR) -Wl,-rpath,'libs'" \
		-DZMQ_DIR=$(ZMQ_DIR) -DCZMQ_DIR=$(CZMQ_DIR) \
		-DHOST=$(CHOST) -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/filemq && \
		$(MAKE)
	cp -fL $(FILEMQ_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(FILEMQ_LIB)) $@

$(ZYRE_LIB): $(ZMQ_LIB) $(CZMQ_LIB) $(THIRDPARTY_DIR)/zyre/CMakeLists.txt
	-mkdir -p $(ZYRE_BUILD_DIR)
	cd $(ZYRE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" \
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS) -Wl,-rpath,'libs'" \
		-DZMQ_DIR=$(ZMQ_DIR) -DCZMQ_DIR=$(CZMQ_DIR) \
		-DHOST=$(CHOST) -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/zyre && \
		$(MAKE)
	cp -fL $(ZYRE_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(ZYRE_LIB)) $@

$(TURBO_FFI_WRAP_LIB): $(SSL_LIB) $(THIRDPARTY_DIR)/turbo/CMakeLists.txt
	-mkdir -p $(TURBO_BUILD_DIR)
	cd $(TURBO_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS) -I$(OPENSSL_DIR)/include" \
		-DLDFLAGS="$(LDFLAGS) -lcrypto -lssl \
		$(if $(ANDROID),$(CURDIR)/$(LUAJIT_LIB),) \
		$(if $(WIN32),$(CURDIR)/$(LUAJIT_LIB),) \
		-L$(OPENSSL_DIR) -Wl,-rpath,'libs'" -DMACHINE="$(MACHINE)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/turbo && \
		$(MAKE)
	cp -fL $(TURBO_DIR)/$(notdir $(TURBO_FFI_WRAP_LIB)) $@
	cp -r $(TURBO_DIR)/turbo $(OUTPUT_DIR)/common
	cp -r $(TURBO_DIR)/turbo.lua $(OUTPUT_DIR)/common
	cp -r $(TURBO_DIR)/turbovisor.lua $(OUTPUT_DIR)/common

$(LUA_SPORE_ROCK): $(THIRDPARTY_DIR)/lua-Spore/CMakeLists.txt
	-mkdir -p $(LUA_SPORE_BUILD_DIR)
	-rm -f $(LUA_SPORE_DIR)/../lua-Spore-stamp/lua-Spore-build
	-rm -f $(LUA_SPORE_ROCK)
	cd $(LUA_SPORE_BUILD_DIR) && \
		$(CMAKE) -DOUTPUT_DIR="$(CURDIR)/$(OUTPUT_DIR)" \
		-DLUA_SPORE_VER=$(LUA_SPORE_VER) \
		-DMACHINE="$(MACHINE)" -DLD="$(LD)" \
		-DCC="$(CC)" -DCFLAGS="$(CFLAGS) -I$(CURDIR)/$(LUA_DIR)/src" \
		$(if $(ANDROID),-DLDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(CURDIR)/$(THIRDPARTY_DIR)/lua-Spore && \
		$(MAKE)

# override lpeg built by luarocks, this is only necessary for Android
lpeg:
	mkdir -p $(OUTPUT_DIR)/rocks/lib/lua/5.1
	mkdir -p $(OUTPUT_DIR)/rocks/share/lua/5.1
	rm -rf lpeg* && luarocks download lpeg && luarocks unpack lpeg*.rock
	cd lpeg*/lpeg* && $(CC) $(DYNLIB_CFLAGS) -I$(CURDIR)/$(LUA_DIR)/src \
		$(CURDIR)/$(LUAJIT_LIB) \
		-o lpeg.so lpcap.c lpcode.c lpprint.c lptree.c lpvm.c \
		&& cp -rf lpeg.so $(CURDIR)/$(OUTPUT_DIR)/rocks/lib/lua/5.1 \
		&& cp -rf re.lua $(CURDIR)/$(OUTPUT_DIR)/rocks/share/lua/5.1

# ===========================================================================
# helper target for creating standalone android toolchain from NDK
# NDK variable should be set in your environment and it should point to
# the root directory of the NDK

android-toolchain:
	mkdir -p $(ANDROID_TOOLCHAIN)
	$(NDK)/build/tools/make-standalone-toolchain.sh --platform=android-9 \
		--install-dir=$(ANDROID_TOOLCHAIN)

# ===========================================================================
# helper target for creating standalone pocket toolchain from
# pocketbook-free SDK: https://github.com/pocketbook-free/SDK_481

pocketbook-toolchain:
	mkdir -p toolchain
	cd toolchain && \
		git clone https://github.com/pocketbook-free/SDK_481 pocketbook-toolchain

# ===========================================================================
# helper target for initializing third-party code

fetchthirdparty:
	rm -rf kpvcrlib/crengine/thirdparty
	test -d kpvcrlib/crengine \
		&& (cd kpvcrlib/crengine; git checkout .) \
		|| echo warn: crengine folder not found
	test -d $(LUA_DIR) \
		&& (cd $(LUA_DIR); git checkout .) \
		|| echo warn: $(LUA_DIR) folder not found
	git submodule init
	git submodule sync
	git submodule foreach --recursive git reset --hard
	git submodule update
	# update submodules in plugins
	cd plugins/evernote-sdk-lua && (git submodule init; git submodule update)

# ===========================================================================
CMAKE_THIRDPARTY_LIBS=turbo,zsync,zyre,czmq,filemq,libk2pdfopt,tesseract,leptonica,lua-Spore,sdcv,luasec,luasocket,libffi,lua-serialize,glib,lodepng,minizip,djvulibre,openssl,mupdf,libzmq,freetype2,giflib,libpng,zlib,tar,libiconv,gettext,libjpeg-turbo,popen-noshell
clean:
	-rm -rf $(OUTPUT_DIR)/*
	-rm -rf $(CRENGINE_WRAPPER_BUILD_DIR)
	-$(MAKE) -C $(LUA_DIR) CC="$(HOSTCC)" CFLAGS="$(BASE_CFLAGS)" clean
	-rm -rf $(THIRDPARTY_DIR)/{$(CMAKE_THIRDPARTY_LIBS)}/build/$(MACHINE)

dist-clean:
	-rm -rf $(THIRDPARTY_DIR)/{$(CMAKE_THIRDPARTY_LIBS)}/build

# ===========================================================================
# start of unit tests section
# ===========================================================================

$(OUTPUT_DIR)/.busted:
	test -e $(OUTPUT_DIR)/.busted || \
		ln -sf ../../.busted $(OUTPUT_DIR)/

$(OUTPUT_DIR)/spec/base:
	mkdir -p $(OUTPUT_DIR)/spec
	test -e $(OUTPUT_DIR)/spec/base || \
		ln -sf ../../../spec $(OUTPUT_DIR)/spec/base

test: $(OUTPUT_DIR)/spec $(OUTPUT_DIR)/.busted
	cd $(OUTPUT_DIR) && busted -l ./luajit --exclude-tags=notest

.PHONY: test
