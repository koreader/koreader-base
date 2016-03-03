# ===========================================================================
# third party libraries:
# (for directory and file name config, see Makefile.defs)

fetchthirdparty:
	git submodule init
	git submodule sync
	git submodule foreach --recursive git reset --hard
	git submodule update
	rm -rf thirdparty/kpvcrlib/crengine/thirdparty
	test -d thirdparty/kpvcrlib/crengine \
		&& (cd thirdparty/kpvcrlib/crengine; git checkout .) \
		|| echo warn: crengine folder not found

$(FREETYPE_LIB) $(FREETYPE_DIR)/include: $(THIRDPARTY_DIR)/freetype2/CMakeLists.txt
	install -d $(FREETYPE_BUILD_DIR)
	cd $(FREETYPE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" -DCFLAGS="$(CFLAGS)"\
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS)" -DCHOST=$(CHOST) \
		$(CURDIR)/$(THIRDPARTY_DIR)/freetype2 && \
		$(MAKE)
	cp -fL $(FREETYPE_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(FREETYPE_LIB)) $@

# libjpeg-turbo and libjepg
$(TURBOJPEG_LIB) $(JPEG_LIB): $(THIRDPARTY_DIR)/libjpeg-turbo/CMakeLists.txt
	install -d $(JPEG_BUILD_DIR)
	cd $(JPEG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" \
		-DCPPFLAGS="$(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		$(if $(findstring armv6, $(ARM_ARCH)),-DWITHOUT_SIMD:BOOL=ON,) \
		-DCHOST="$(if $(ANDROID),"arm-linux",$(CHOST))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/libjpeg-turbo && \
		$(MAKE)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(TURBOJPEG_LIB)) $(TURBOJPEG_LIB)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(JPEG_LIB)) $(JPEG_LIB)

$(PNG_LIB): $(ZLIB) $(THIRDPARTY_DIR)/libpng/CMakeLists.txt
	install -d $(PNG_BUILD_DIR)
	cd $(PNG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" -DCHOST="$(CHOST)" \
		-DCPPFLAGS="$(CFLAGS) -I$(ZLIB_DIR)" \
		-DLDFLAGS="$(LDFLAGS) -L$(ZLIB_DIR) -Wl,-rpath,'$(ORIGIN_CMAKE_TO_AUTOCFG)'" \
		$(CURDIR)/$(THIRDPARTY_DIR)/libpng && \
		$(MAKE)
	cp -fL $(PNG_DIR)/.libs/$(notdir $(PNG_LIB)) $@

$(AES_LIB): $(THIRDPARTY_DIR)/minizip/CMakeLists.txt
	install -d $(MINIZIP_BUILD_DIR)
	-rm -f $(MINIZIP_DIR)/../minizip-stamp/minizip-build
	cd $(MINIZIP_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DAR="$(AR)" -DRANLIB="$(RANLIB)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/minizip && \
		$(MAKE)

# by default, mupdf compiles to a static library:
# we generate a dynamic library from the static library:
$(MUPDF_LIB) $(MUPDF_DIR)/include: $(JPEG_LIB) \
		$(FREETYPE_LIB) $(FREETYPE_DIR)/include \
		$(ZLIB) $(AES_LIB) $(THIRDPARTY_DIR)/mupdf/CMakeLists.txt
	install -d $(MUPDF_BUILD_DIR)
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
		-DAES_LIB=$(AES_LIB) -DRPATH="\$$ORIGIN" \
		-DZLIB=$(CURDIR)/$(ZLIB) -DJPEG_LIB=$(CURDIR)/$(JPEG_LIB) \
		-DFREETYPE_LIB=$(CURDIR)/$(FREETYPE_LIB) \
		$(CURDIR)/$(THIRDPARTY_DIR)/mupdf && \
		$(MAKE)

$(LODEPNG_LIB) $(LODEPNG_DIR): $(THIRDPARTY_DIR)/lodepng/CMakeLists.txt
	install -d $(LODEPNG_BUILD_DIR)
	-rm -f $(LODEPNG_DIR)/../lodepng-stamp/lodepng-build
	cd $(LODEPNG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS)" \
		-DSONAME="$(notdir $(LODEPNG_LIB))" \
		-DOUTPUT_PATH="$(CURDIR)/$(dir $(LODEPNG_LIB))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/lodepng && \
		$(MAKE)

$(GIF_LIB): $(THIRDPARTY_DIR)/giflib/CMakeLists.txt
	install -d $(GIF_BUILD_DIR)
	cd $(GIF_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(if $(ANDROID),-DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR,)" \
		-DCFLAGS="$(CFLAGS)" -DLDFLAGS="$(LDFLAGS)" -DCHOST="$(CHOST)" \
		$(CURDIR)/thirdparty/giflib && \
		$(MAKE)
	cp -fL $(GIF_DIR)/lib/$(notdir $(GIF_LIB)) $@

$(DJVULIBRE_LIB): $(JPEG_LIB) $(THIRDPARTY_DIR)/djvulibre/CMakeLists.txt
	install -d $(DJVULIBRE_BUILD_DIR)
	cd $(DJVULIBRE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" -DCFLAGS="$(CFLAGS)" \
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS)" \
		-DLIBS="$(STATIC_LIBSTDCPP)" \
		-DCHOST="$(if $(EMULATE_READER),,$(CHOST))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/djvulibre && \
		$(MAKE)
	cp -fL $(DJVULIBRE_LIB_DIR)/$(notdir $(DJVULIBRE_LIB)) $(DJVULIBRE_LIB)

# crengine, fetched via GIT as a submodule
$(CRENGINE_LIB): $(ZLIB) $(PNG_LIB) $(FREETYPE_LIB) $(JPEG_LIB) \
		$(THIRDPARTY_DIR)/kpvcrlib/crengine $(THIRDPARTY_DIR)/kpvcrlib/CMakeLists.txt
	install -d $(CRENGINE_BUILD_DIR)
	cd $(CRENGINE_BUILD_DIR) && \
		CC="$(CC)" CXX="$(CXX)" RC="$(RC)" \
		CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS) -static-libstdc++" \
		JPEG_LIB="$(CURDIR)/$(JPEG_LIB)" \
		PNG_LIB="$(CURDIR)/$(PNG_LIB)" \
		FREETYPE_LIB="$(CURDIR)/$(FREETYPE_LIB)" \
		ZLIB="$(CURDIR)/$(ZLIB)" \
		LIBS_DIR="$(CURDIR)/$(OUTPUT_DIR)/libs" \
		$(CMAKE) -DJPEGLIB_INCLUDE_DIR=$(JPEG_DIR)/include \
		-DJCONFIG_INCLUDE_DIR="$(MUPDF_DIR)/scripts" \
		-DPNG_INCLUDE_DIR="$(PNG_DIR)/include" \
		-DZLIB_INCLUDE_DIR="$(ZLIB_DIR)/include" \
		-DFREETYPE_INCLUDE_DIR="$(FREETYPE_DIR)/include/freetype2" \
		-DCMAKE_BUILD_TYPE=Release \
		$(if $(WIN32),-DCMAKE_SYSTEM_NAME=Windows,) \
		$(CURDIR)/$(THIRDPARTY_DIR)/kpvcrlib && \
		$(MAKE)
	cp -fL $(CRENGINE_DIR)/$(notdir $(CRENGINE_LIB)) $(CRENGINE_LIB)

$(LUAJIT) $(LUAJIT_LIB) $(LUAJIT_JIT): $(THIRDPARTY_DIR)/luajit/CMakeLists.txt
	install -d $(LUAJIT_BUILD_DIR)
	cd $(LUAJIT_BUILD_DIR) && \
		$(CMAKE) -DCC="$(HOSTCC)" \
		-DXCOMPILE:BOOL=$(if $(EMULATE_READER),off,on) \
		-DBASE_CFLAGS="$(BASE_CFLAGS)" -DHOST_CFLAGS="$(HOSTCFLAGS)" \
		$(if $(WIN32),-DLDFLAGS="$(LDFLAGS)" -DTARGET_SYS=Windows,) \
		-DTARGET_SONAME=$(notdir $(LUAJIT_LIB)) \
		-DTARGET_CFLAGS="$(CFLAGS)" \
		-DCROSS="$(strip $(CCACHE) $(CHOST))-" \
		$(CURDIR)/$(THIRDPARTY_DIR)/luajit && \
		$(MAKE)
ifdef WIN32
	cp -fL $(LUAJIT_DIR)/src/$(notdir $(LUAJIT_LIB)) $(LUAJIT_LIB)
endif
ifdef ANDROID
	cp -fL $(LUAJIT_DIR)/src/$(notdir $(LUAJIT_LIB)) $(LUAJIT_LIB)
else
	cp -fL $(LUAJIT_DIR)/src/$(notdir $(LUAJIT)) $(LUAJIT)
endif
	-rm -rf $(LUAJIT_JIT)
	cp -rfL $(LUAJIT_DIR)/src/jit $(OUTPUT_DIR)

$(POPEN_NOSHELL_LIB): $(THIRDPARTY_DIR)/popen-noshell/CMakeLists.txt
	install -d $(POPEN_NOSHELL_BUILD_DIR)
	cd $(POPEN_NOSHELL_BUILD_DIR) && \
		$(CMAKE) $(if $(LEGACY),-DLEGACY:BOOL=ON,) \
		-DCC="$(CC)" -DAR="$(AR)" \
		-DCFLAGS="$(CFLAGS) $(if $(ANDROID),--sysroot=$(SYSROOT),)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/popen-noshell && \
		$(MAKE)

# k2pdfopt depends on leptonica and tesseract
$(LEPTONICA_DIR): $(THIRDPARTY_DIR)/leptonica/CMakeLists.txt
	install -d $(LEPTONICA_BUILD_DIR)
	cd $(LEPTONICA_BUILD_DIR) && \
		$(CMAKE) $(CURDIR)/$(THIRDPARTY_DIR)/leptonica && \
		$(MAKE)

$(TESSERACT_DIR): $(THIRDPARTY_DIR)/tesseract/CMakeLists.txt
	install -d $(TESSERACT_BUILD_DIR)
	cd $(TESSERACT_BUILD_DIR) && \
		$(CMAKE) $(CURDIR)/$(THIRDPARTY_DIR)/tesseract && \
		$(MAKE)

$(K2PDFOPT_LIB) $(LEPTONICA_LIB) $(TESSERACT_LIB): $(PNG_LIB) $(ZLIB) \
		$(THIRDPARTY_DIR)/libk2pdfopt/CMakeLists.txt \
		$(TESSERACT_DIR) $(LEPTONICA_DIR)
	install -d $(K2PDFOPT_BUILD_DIR)
	cd $(K2PDFOPT_BUILD_DIR) && \
		$(CMAKE) $(if $(EMULATE_READER),,-DHOST="$(if $(ANDROID),"arm-linux",$(CHOST))") \
		-DCC="$(CC)" -DCFLAGS="$(CFLAGS)" -DCXX="$(CXX)" -DCXXFLAGS="$(CXXFLAGS) -O3" \
		-DAR="$(AR)" -DSTDCPPLIB="$(STATIC_LIBSTDCPP)" -DLDFLAGS="$(LDFLAGS)" \
		-DZLIB_DIR=$(ZLIB_DIR) -DZLIB=$(CURDIR)/$(ZLIB) -DPNG_DIR=$(PNG_DIR) \
		-DLEPTONICA_DIR=$(LEPTONICA_DIR) -DTESSERACT_DIR=$(TESSERACT_DIR) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libk2pdfopt && \
		$(MAKE)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(K2PDFOPT_LIB)) $(K2PDFOPT_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(LEPTONICA_LIB)) $(LEPTONICA_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(TESSERACT_LIB)) $(TESSERACT_LIB)

# ===========================================================================
# sdcv dependencies: glib-2.0 and zlib

# libiconv for glib on android
$(LIBICONV): $(THIRDPARTY_DIR)/libiconv/CMakeLists.txt
	install -d $(LIBICONV_BUILD_DIR)
	cd $(LIBICONV_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" \
		-DHOST="$(if $(EMULATE_READER),,$(if $(ANDROID),"arm-linux",$(CHOST)))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/libiconv && \
		$(MAKE)

# libgettext for glib on android
$(LIBGETTEXT): $(LIBICONV) $(THIRDPARTY_DIR)/gettext/CMakeLists.txt
	install -d $(GETTEXT_BUILD_DIR)
	cd $(GETTEXT_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" -DLIBICONV_PREFIX=$(LIBICONV_DIR) \
		-DCHOST_OPTS="$(if $(EMULATE_READER),,--host=$(if $(ANDROID),arm-linux,$(CHOST)))" \
		$(if $(ANDROID),-DIS_ANDROID:BOOL=on,) \
		$(CURDIR)/thirdparty/gettext && \
		$(MAKE)

$(LIBFFI_DIR)/include: $(THIRDPARTY_DIR)/libffi/CMakeLists.txt
	install -d $(LIBFFI_BUILD_DIR)
	-rm -rf $(LIBFFI_DIR)/include $(LIBFFI_DIR)/../libffi-stamp
	cd $(LIBFFI_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DHOST="$(CHOST)" \
		$(if $(ANDROID),-DSYSROOT="$(SYSROOT)",) \
		$(CURDIR)/$(THIRDPARTY_DIR)/libffi && \
		$(MAKE)

$(GLIB): $(LIBFFI_DIR)/include $(THIRDPARTY_DIR)/glib/CMakeLists.txt
	install -d $(GLIB_BUILD_DIR)
	-rm -f $(GLIB_DIR)/../glib-stamp/glib-install
	cd $(GLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" \
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
	install -d $(GLIB_BUILD_DIR)
	-rm -f $(GLIB_DIR)/../glib-stamp/glib-install
	cd $(GLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) -std=gnu89" \
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
	install -d $(ZLIB_BUILD_DIR)
	-rm -f $(ZLIB_DIR)/../zlib-stamp/zlib-install $(ZLIB) $(ZLIB_STATIC)
ifdef WIN32
	cd $(ZLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCHOST="$(CHOST)" \
		$(CURDIR)/thirdparty/zlib && \
		$(MAKE)
	cp -fL $(ZLIB_DIR)/$(notdir $(ZLIB)) $(ZLIB)
else
	cd $(ZLIB_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" \
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
	install -d $(SDCV_BUILD_DIR)
	cd $(SDCV_BUILD_DIR) && \
		$(CMAKE) -DHOST="$(if $(EMULATE_READER),,$(CHOST))" \
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
	install -d $(TAR_BUILD_DIR)
	cd $(TAR_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DLIBS="$(if $(WIN32),,-lrt)" \
		$(if $(LEGACY),-DDISABLE_LARGEFILE:BOOL=ON -DDISABLE_FORTIFY:BOOL=ON,) \
		-DCHOST="$(if $(EMULATE_READER),,$(CHOST))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/tar && \
		$(MAKE)
	cp $(TAR_DIR)/src/tar $(OUTPUT_DIR)/

# ===========================================================================
# zsync: rsync over HTTP

$(OUTPUT_DIR)/zsync: $(THIRDPARTY_DIR)/zsync/CMakeLists.txt
	install -d $(ZSYNC_BUILD_DIR)
	cd $(ZSYNC_BUILD_DIR) && \
		$(CMAKE) -DHOST="$(if $(EMULATE_READER),,$(CHOST))" -DCC="$(CC)" \
		$(CURDIR)/$(THIRDPARTY_DIR)/zsync && \
		$(MAKE)
	cp $(ZSYNC_DIR)/zsync $(OUTPUT_DIR)/

# ===========================================================================
# common lua library for networking
$(LUASOCKET): $(THIRDPARTY_DIR)/luasocket/CMakeLists.txt
	-rm -rf $(LUASOCKET) $(LUASOCKET_BUILD_DIR)
	install -d $(LUASOCKET_BUILD_DIR)
	cd $(LUASOCKET_BUILD_DIR) && \
		$(CMAKE) -DPLAT="$(if $(WIN32),mingw,linux)" \
		-DCC="$(CC) $(CFLAGS)" \
		$(if $(ANDROID),-DMYLDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),-DLUALIB_mingw="$(CURDIR)/$(LUAJIT_LIB)",) \
		-DLUAINC="$(LUAJIT_DIR)/src" \
		-DINSTALL_DIR="$(CURDIR)/$(OUTPUT_DIR)/common" \
		$(CURDIR)/$(THIRDPARTY_DIR)/luasocket && \
		$(MAKE)

# RPATH for OPENSSL is even uglier because its Makefile uses single quote :/
OPENSSL_RPATH_ORIGIN=\\\"'$(ORIGIN_CMAKE_TO_AUTOCFG)'\\\"
$(OPENSSL_LIB) $(OPENSSL_DIR): $(THIRDPARTY_DIR)/openssl/CMakeLists.txt
	install -d $(OPENSSL_BUILD_DIR)
	-rm -f $(OPENSSL_DIR)/../openssl-stamp/openssl-build
	cd $(OPENSSL_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" \
		-DSHARED_LDFLAGS="$(LDFLAGS) -Wl,-rpath,$(OPENSSL_RPATH_ORIGIN)" \
		-DLD="$(LD)" -DRANLIB="$(RANLIB)" $(if $(WIN32),-DCHOST="$(CHOST)",) \
		-DCONFIG_SCRIPT="$(if $(EMULATE_READER),config,Configure $(if $(WIN32),mingw,linux-generic32))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/openssl && \
		$(MAKE)

$(SSL_LIB): $(OPENSSL_LIB)
	cp -fL $(OPENSSL_DIR)/$(notdir $(SSL_LIB)) $(SSL_LIB)
	cp -fL $(OPENSSL_DIR)/$(notdir $(CRYPTO_LIB)) $(CRYPTO_LIB)

# ssl.so locates in koreader/common, but libssl.so and libcrypto.so live
# in koreader/libs, so we need to set rpath accordingly
$(LUASEC): $(OPENSSL_DIR) $(THIRDPARTY_DIR)/luasec/CMakeLists.txt
	install -d $(LUASEC_BUILD_DIR)
	-rm -f $(LUASEC_DIR)/../luasec-stamp/luasec-install
	cd $(LUASEC_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" -DLD="$(CC) -Wl,-rpath,'$(ORIGIN_CMAKE_TO_AUTOCFG)/../libs'" \
		$(if $(ANDROID),-DLIBS="-lssl -lcrypto -lluasocket $(CURDIR)/$(LUAJIT_LIB)",) \
		-DINC_PATH="-I$(LUAJIT_DIR)/src -I$(OPENSSL_DIR)/include" \
		-DLIB_PATH="-L$(OPENSSL_DIR)" \
		-DLUAPATH="$(CURDIR)/$(OUTPUT_DIR)/common" \
		$(CURDIR)/$(THIRDPARTY_DIR)/luasec && \
		$(MAKE)

$(LUASERIAL_LIB): $(THIRDPARTY_DIR)/lua-serialize/CMakeLists.txt
	install -d $(LUASERIAL_BUILD_DIR)
	-rm -f $(LUASERIAL_DIR)/../lua-serialize-stamp/lua-serialize-build
	-rm -f $(LUASERIAL_LIB)
	cd $(LUASERIAL_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" \
		-DLDFLAGS="$(LDFLAGS)$(if $(or $(ANDROID),$(WIN32)), $(CURDIR)/$(LUAJIT_LIB),)" \
		-DOUTPUT_DIR=$(CURDIR)/$(OUTPUT_DIR)/common \
		$(CURDIR)/$(THIRDPARTY_DIR)/lua-serialize && \
		$(MAKE)

$(LUACOMPAT52): $(LUASERIAL_LIB) $(THIRDPARTY_DIR)/lua-serialize/CMakeLists.txt
	cp $(OUTPUT_DIR)/common/libluacompat52.so $(OUTPUT_DIR)/libs

# zeromq should be compiled without optimization in clang 3.4
# which otherwise may throw a warning saying "array index is past the end
# of the array" for strcmp comparing a string with exactly 2 chars.
# More details about this bug:
# https://gcc.gnu.org/ml/gcc-help/2009-10/msg00191.html
$(ZMQ_LIB): $(THIRDPARTY_DIR)/libzmq/CMakeLists.txt
	install -d $(ZMQ_BUILD_DIR)
	cd $(ZMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCXX="$(CXX)" \
		-DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" \
		-DCXXFLAGS="$(CXXFLAGS) $(if $(CLANG),-O0,)" \
		-DLDFLAGS="$(LDFLAGS)" -DSTATIC_LIBSTDCPP="$(STATIC_LIBSTDCPP)" \
		$(if $(LEGACY),-DLEGACY:BOOL=ON,) -DCHOST=$(CHOST) \
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
	install -d $(CZMQ_BUILD_DIR)
	cd $(CZMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DLDFLAGS="$(LDFLAGS) -Wl,-rpath,'$(ORIGIN_CMAKE_TO_AUTOCFG)'" \
		-DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) $(if $(WIN32),-DLIBCZMQ_EXPORTS)" \
		-DZMQ_DIR=$(ZMQ_DIR) -DHOST=$(CHOST) \
		$(CURDIR)/$(THIRDPARTY_DIR)/czmq && \
		$(MAKE)
	cp -fL $(CZMQ_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(CZMQ_LIB)) $@

$(FILEMQ_LIB): $(ZMQ_LIB) $(CZMQ_LIB) $(SSL_LIB) $(THIRDPARTY_DIR)/filemq/CMakeLists.txt
	install -d $(FILEMQ_BUILD_DIR)
	cd $(FILEMQ_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) -I$(OPENSSL_DIR)/include" \
		-DLDFLAGS="$(LDFLAGS) -L$(OPENSSL_DIR) -Wl,-rpath,'${ORIGIN_CMAKE_TO_AUTOCFG}'" \
		-DZMQ_DIR=$(ZMQ_DIR) -DCZMQ_DIR=$(CZMQ_DIR) -DHOST=$(CHOST) \
		$(CURDIR)/$(THIRDPARTY_DIR)/filemq && \
		$(MAKE)
	cp -fL $(FILEMQ_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(FILEMQ_LIB)) $@

$(ZYRE_LIB): $(ZMQ_LIB) $(CZMQ_LIB) $(THIRDPARTY_DIR)/zyre/CMakeLists.txt
	install -d $(ZYRE_BUILD_DIR)
	cd $(ZYRE_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DCFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" \
		-DCXXFLAGS="$(CXXFLAGS)" -DLDFLAGS="$(LDFLAGS) -Wl,-rpath,'$(ORIGIN_CMAKE_TO_AUTOCFG)'" \
		-DZMQ_DIR=$(ZMQ_DIR) -DCZMQ_DIR=$(CZMQ_DIR) -DHOST=$(CHOST) \
		$(CURDIR)/$(THIRDPARTY_DIR)/zyre && \
		$(MAKE)
	cp -fL $(ZYRE_DIR)/$(if $(WIN32),bin,lib)/$(notdir $(ZYRE_LIB)) $@

# libtffi_wrap.so locates in koreader/common, but libssl.so and libcrypto.so
# live in koreader/libs, so we need to set rpath accordingly
$(TURBO_FFI_WRAP_LIB): $(SSL_LIB) $(THIRDPARTY_DIR)/turbo/CMakeLists.txt
	install -d $(TURBO_BUILD_DIR)
	cd $(TURBO_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS) -I$(OPENSSL_DIR)/include" \
		-DLDFLAGS="$(LDFLAGS) -lcrypto -lssl \
			$(if $(ANDROID),$(CURDIR)/$(LUAJIT_LIB),) \
			$(if $(WIN32),$(CURDIR)/$(LUAJIT_LIB),) \
			-L$(OPENSSL_DIR) -Wl,-rpath,'$(ORIGIN_CMAKE_TO_AUTOCFG)/../libs'" \
		$(CURDIR)/$(THIRDPARTY_DIR)/turbo && \
		$(MAKE)
	cp -fL $(TURBO_DIR)/$(notdir $(TURBO_FFI_WRAP_LIB)) $@
	cp -r $(TURBO_DIR)/turbo $(OUTPUT_DIR)/common
	cp -r $(TURBO_DIR)/turbo.lua $(OUTPUT_DIR)/common
	cp -r $(TURBO_DIR)/turbovisor.lua $(OUTPUT_DIR)/common

$(LUA_SPORE_ROCK): $(THIRDPARTY_DIR)/lua-Spore/CMakeLists.txt
	install -d $(LUA_SPORE_BUILD_DIR)
	-rm -f $(LUA_SPORE_DIR)/../lua-Spore-stamp/lua-Spore-build
	-rm -f $(LUA_SPORE_ROCK)
	cd $(LUA_SPORE_BUILD_DIR) && \
		$(CMAKE) -DOUTPUT_DIR="$(CURDIR)/$(OUTPUT_DIR)" \
		-DLUA_SPORE_VER=$(LUA_SPORE_VER) -DLD="$(LD)" \
		-DCC="$(CC)" -DCFLAGS="$(CFLAGS) -I$(LUAJIT_DIR)/src" \
		$(if $(ANDROID),-DLDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(CURDIR)/$(THIRDPARTY_DIR)/lua-Spore && \
		$(MAKE)

# override lpeg built by luarocks, this is only necessary for Android
$(LPEG_DYNLIB) $(LPEG_RE): $(LUAJIT_LIB) $(THIRDPARTY_DIR)/lpeg/CMakeLists.txt
	install -d $(OUTPUT_DIR)/rocks/lib/lua/5.1
	install -d $(OUTPUT_DIR)/rocks/share/lua/5.1
	install -d $(LPEG_BUILD_DIR)
	cd $(LPEG_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC)" -DDYNLIB_CFLAGS="$(DYNLIB_CFLAGS)" \
		-DLUA_DIR="$(LUAJIT_DIR)" $(CURDIR)/$(THIRDPARTY_DIR)/lpeg && \
		$(MAKE)
	cp -rf $(LPEG_DIR)/lpeg.so $(OUTPUT_DIR)/rocks/lib/lua/5.1
	cp -rf $(LPEG_DIR)/re.lua $(OUTPUT_DIR)/rocks/share/lua/5.1

$(EVERNOTE_LIB): $(THIRDPARTY_DIR)/evernote-sdk-lua/CMakeLists.txt
	install -d $(EVERNOTE_SDK_BUILD_DIR)
	-rm -f $(EVERNOTE_LIB) $(EVERNOTE_SDK_DIR)/../evernote-sdk-lua-stamp/evernote-sdk-lua-build
	cd $(EVERNOTE_SDK_BUILD_DIR) && \
		$(CMAKE) -DCC="$(CC) $(CFLAGS)" \
		-DOUTPUT_DIR="$(CURDIR)/$(EVERNOTE_PLUGIN_DIR)/lib" \
		-DLDFLAGS="$(LDFLAGS)$(if $(or $(ANDROID),$(WIN32)), -lm $(CURDIR)/$(LUAJIT_LIB))" \
		$(CURDIR)/$(THIRDPARTY_DIR)/evernote-sdk-lua && \
		$(MAKE)

$(LUALONGNUMBER): $(EVERNOTE_LIB) $(THIRDPARTY_DIR)/evernote-sdk-lua/CMakeLists.txt
	cp $(CURDIR)/$(EVERNOTE_PLUGIN_DIR)/lib/liblualongnumber.so \
		$(CURDIR)/$(OUTPUT_DIR)/libs
