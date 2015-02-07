include Makefile.defs

# main target
all: $(OUTPUT_DIR)/libs $(if $(ANDROID),,$(LUAJIT)) \
		$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
		$(LUAJIT_JIT) \
		libs $(K2PDFOPT_LIB) \
		$(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/common \
		$(OUTPUT_DIR)/plugins $(LUASOCKET) \
		$(if $(WIN32),,$(LUASEC)) \
		$(if $(ANDROID),luacompat52 lualongnumber,) \
		$(if $(WIN32),,$(EVERNOTE_LIB)) \
		$(LUASERIAL_LIB) \
		$(TURBOJPEG_LIB) \
		$(LODEPNG_LIB) \
		$(GIF_LIB) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/sdcv) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/zsync) \
		$(if $(WIN32), ,$(ZMQ_LIB) $(CZMQ_LIB) $(FILEMQ_LIB) $(ZYRE_LIB))
ifndef EMULATE_READER
	STRIP_FILES="\
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/tar) \
		$(if $(or $(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/sdcv) \
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
			mkdir $(OUTPUT_DIR)/fonts && \
			cd $(OUTPUT_DIR)/fonts && \
			ln -sf ../../../$(MUPDF_TTF_FONTS_DIR)/* . \
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

$(OUTPUT_DIR)/plugins:
	mkdir -p $(OUTPUT_DIR)/plugins

# ===========================================================================

# third party libraries:
# (for directory and file name config, see Makefile.defs)

# freetype, fetched via GIT as a submodule
$(FREETYPE_LIB):
	mkdir -p $(FREETYPE_DIR)/build
	cd $(FREETYPE_DIR) && sh autogen.sh
	cd $(FREETYPE_DIR)/build && \
		CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" \
			../configure -q --prefix=$(CURDIR)/$(FREETYPE_DIR)/build \
				--disable-static --enable-shared \
				--with-zlib=no --with-bzip2=no \
				--with-png=no --with-harfbuzz=no \
				--host=$(CHOST)
	$(MAKE) -j$(PROCESSORS) -C $(FREETYPE_DIR)/build
	-$(MAKE) -C $(FREETYPE_DIR)/build --silent install
	cp -fL $(FREETYPE_DIR)/build/$(if $(WIN32),bin,lib)/$(notdir $(FREETYPE_LIB)) $@

# libjpeg-turbo, fetched via subversion
$(JPEG_LIB):
	cd $(JPEG_DIR) && \
		CC="$(CC)" CXX="$(CXX)" CPPFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
		./configure -q --prefix=$(CURDIR)/$(JPEG_DIR) \
			--host=$(if $(ANDROID),"arm-linux",$(CHOST)) \
			$(if $(findstring armv6, $(ARM_ARCH)),--without-simd,) \
			--disable-static --enable-shared --with-jpeg8
	$(MAKE) -j$(PROCESSORS) -C $(JPEG_DIR) --silent install
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(JPEG_LIB)) $@

$(TURBOJPEG_LIB): $(JPEG_LIB)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(TURBOJPEG_LIB)) $@

# libpng, fetched via GIT as a submodule
$(PNG_LIB): $(ZLIB)
	-cd $(PNG_DIR) && sh autogen.sh
	cd $(PNG_DIR) && \
		CC="$(CC)" CXX="$(CXX)" \
		CPPFLAGS="$(CFLAGS) -I$(CURDIR)/$(ZLIB_DIR)" \
		LDFLAGS="$(LDFLAGS) -L$(CURDIR)/$(ZLIB_DIR)" \
		./configure -q --prefix=$(CURDIR)/$(PNG_DIR) \
			--disable-static --enable-shared --host=$(CHOST)
	$(MAKE) -j$(PROCESSORS) -C $(PNG_DIR) --silent install
	cp -fL $(PNG_DIR)/.libs/$(notdir $(PNG_LIB)) $@

# mupdf, fetched via GIT as a submodule
# by default, mupdf compiles to a static library:
# we generate a dynamic library from the static library:
$(MUPDF_LIB): $(JPEG_LIB) $(FREETYPE_LIB)
	env CFLAGS="$(HOSTCFLAGS)" \
		$(MAKE) -j$(PROCESSORS) -C mupdf generate build="release" CC="$(HOSTCC)" \
		OS=$(if $(WIN32),,Other) verbose=1
	$(MAKE) -j$(PROCESSORS) -C mupdf \
		LDFLAGS="$(LDFLAGS) -L../$(OUTPUT_DIR)" \
		XCFLAGS="$(CFLAGS) -DNOBUILTINFONT -I../$(JPEG_DIR)/include -I../$(FREETYPE_DIR)/include" \
		CC="$(CC)" \
		build="release" MUDRAW= MUTOOL= CURL_LIB= \
		OS=$(if $(WIN32),,Other) verbose=1 \
		FREETYPE_DIR=nonexisting \
		JPEG_DIR=nonexisting \
		CROSSCOMPILE=yes \
		third libs
	$(CC) -shared $(CFLAGS) \
		-Wl,-E -Wl,-rpath,'$$ORIGIN' \
		-Wl,--whole-archive $(MUPDF_LIB_STATIC) \
		-Wl,--whole-archive $(MUPDF_JS_LIB_STATIC) \
		-Wl,--no-whole-archive $(MUPDF_THIRDPARTY_LIBS) \
		-Wl,-soname=$(notdir $(MUPDF_LIB)) \
		$(JPEG_LIB) $(FREETYPE_LIB) \
		-o $(MUPDF_LIB) -lm $(if $(ANDROID),-llog,)

$(LODEPNG_LIB): $(LODEPNG_DIR)/lodepng.cpp $(LODEPNG_DIR)/lodepng.h
	cp $(LODEPNG_DIR)/lodepng.cpp $(LODEPNG_DIR)/lodepng.c
	$(CC) -shared $(CFLAGS) \
		-Wl,-E -Wl,-rpath,'$$ORIGIN' \
		-Wl,-soname=$(notdir $(LODEPNG_LIB)) \
		$(LODEPNG_DIR)/lodepng.c \
		-o $(LODEPNG_LIB)

# giflib
$(GIF_LIB):
	cd $(GIF_DIR) && \
		CC="$(CC) $(if $(ANDROID),-DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR,)" \
		CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
		./configure -q --prefix=$(CURDIR)/$(GIF_DIR) \
			--disable-static --enable-shared --host=$(CHOST)
	$(MAKE) -j$(PROCESSORS) -C $(GIF_DIR) --silent install
	cp -fL $(GIF_DIR)/lib/$(notdir $(GIF_LIB)) $@

# djvulibre, fetched via GIT as a submodule
$(DJVULIBRE_LIB): $(JPEG_LIB)
	mkdir -p $(DJVULIBRE_DIR)/build
	test -e $(DJVULIBRE_DIR)/build/Makefile \
		|| ( cd $(DJVULIBRE_DIR)/build \
		&& CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" \
		../configure -q --disable-desktopfiles \
			--disable-static --enable-shared \
			--disable-xmltools --disable-largefile \
			--without-jpeg --without-tiff \
			$(if $(EMULATE_READER),,-host=$(CHOST)) )
	$(MAKE) -j$(PROCESSORS) -C $(DJVULIBRE_DIR)/build \
		SUBDIRS_FIRST=libdjvu --silent
	cp -fL $(DJVULIBRE_LIB_DIR)/$(notdir $(DJVULIBRE_LIB)) \
		$(DJVULIBRE_LIB)

# crengine, fetched via GIT as a submodule
$(CRENGINE_LIB): $(ZLIB) $(PNG_LIB) $(FREETYPE_LIB) $(JPEG_LIB)
	test -e $(CRENGINE_WRAPPER_DIR)/build \
	|| mkdir $(CRENGINE_WRAPPER_DIR)/build
	cd $(CRENGINE_WRAPPER_DIR)/build \
	&& CC="$(CC)" CXX="$(CXX)" RC="$(RC)" \
		CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" \
		JPEG_LIB="$(CURDIR)/$(JPEG_LIB)" \
		PNG_LIB="$(CURDIR)/$(PNG_LIB)" \
		FREETYPE_LIB="$(CURDIR)/$(FREETYPE_LIB)" \
		ZLIB="$(CURDIR)/$(ZLIB)" \
		LIBS_DIR="$(CURDIR)/$(OUTPUT_DIR)/libs" \
		cmake -DCMAKE_BUILD_TYPE=Release \
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

# popen-noshell, fetched via SVN
$(POPEN_NOSHELL_LIB):
	$(MAKE) -j$(PROCESSORS) -C $(POPEN_NOSHELL_DIR) \
		CC="$(CC)" AR="$(AR)" \
		CFLAGS="$(CFLAGS) $(if $(ANDROID),--sysroot=$(SYSROOT),)"

# k2pdfopt, fetched via GIT as a submodule
$(K2PDFOPT_LIB) $(LEPTONICA_LIB) $(TESSERACT_LIB): $(PNG_LIB) $(ZLIB)
	$(MAKE) -j$(PROCESSORS) -C $(K2PDFOPT_DIR) BUILDMODE=shared \
		$(if $(EMULATE_READER),,HOST=$(if $(ANDROID),"arm-linux",$(CHOST))) \
		CC="$(CC)" CFLAGS="$(CFLAGS) -O3" \
		CXX="$(CXX)" CXXFLAGS="$(CXXFLAGS) -O3" \
		AR="$(AR)" ZLIB=../$(ZLIB) \
		LEPT_CFLAGS="$(CFLAGS) -I$(CURDIR)/$(ZLIB_DIR) -I$(CURDIR)/$(PNG_DIR)" \
		LEPT_LDFLAGS="$(LDFLAGS) -L$(CURDIR)/$(ZLIB_DIR) -L$(CURDIR)/$(PNG_DIR)/lib" \
		ZLIB_LDFLAGS="-Wl,-rpath-link,$(CURDIR)/$(ZLIB_DIR)" \
		PNG_LDFLAGS="-Wl,-rpath-link,$(CURDIR)/$(PNG_DIR)/lib" \
		all
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(K2PDFOPT_LIB)) $(K2PDFOPT_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(LEPTONICA_LIB)) $(LEPTONICA_LIB)
	cp -fL $(K2PDFOPT_DIR)/$(notdir $(TESSERACT_LIB)) $(TESSERACT_LIB)

# end of third-party code
# ===========================================================================

# our own Lua/C/C++ interfacing:

libs: \
	$(if $(or $(EMULATE_READER),$(ANDROID),$(WIN32)),,$(OUTPUT_DIR)/libs/libkoreader-input.so) \
	$(OUTPUT_DIR)/libs/libkoreader-lfs.so \
	$(if $(ANDROID),,$(OUTPUT_DIR)/libs/libkoreader-djvu.so) \
	$(OUTPUT_DIR)/libs/libkoreader-cre.so \
	$(OUTPUT_DIR)/libs/libwrap-mupdf.so

$(OUTPUT_DIR)/libs/libkoreader-input.so: input.c \
			$(POPEN_NOSHELL_LIB)
	$(CC) $(DYNLIB_CFLAGS) $(if $(POCKETBOOK),-DPOCKETBOOK,) \
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
	$(CC) -I$(DJVULIBRE_DIR)/ -I$(MUPDF_DIR)/include $(K2PDFOPT_CFLAGS) \
		$(DYNLIB_CFLAGS) -o $@ $^ $(if $(ANDROID),,-lpthread)

$(OUTPUT_DIR)/libs/libkoreader-cre.so: cre.cpp \
			$(if $(or $(ANDROID),$(WIN32)),$(LUAJIT_LIB),) \
			$(CRENGINE_LIB)
	$(CXX) -I$(CRENGINE_DIR)/crengine/include/ $(DYNLIB_CFLAGS) \
		-DLDOM_USE_OWN_MEM_MAN=$(if $(WIN32),0,1) \
		$(if $(WIN32),-DQT_GL=1) \
		-Wl,-rpath,'libs' -o $@ $^ $(STATICLIBSTDCPP)

$(OUTPUT_DIR)/libs/libwrap-mupdf.so: wrap-mupdf.c \
			$(MUPDF_LIB)
	$(CC) -I$(MUPDF_DIR)/include $(DYNLIB_CFLAGS) \
		-o $@ $^

# ===========================================================================
# the attachment extraction tool:

$(OUTPUT_DIR)/extr: extr.c \
				$(MUPDF_LIB) \
				$(JPEG_LIB) \
				$(FREETYPE_LIB)
	$(CC) -I$(MUPDF_DIR) -I$(MUPDF_DIR)/include \
		$(CFLAGS) -Wl,-rpath,'libs' -o $@ $^

# ===========================================================================
# sdcv dependencies: glib-2.0 and zlib

$(GLIB):
	echo -e "glib_cv_stack_grows=no\nglib_cv_uscore=no\nac_cv_func_posix_getpwuid_r=no" > \
		$(GLIB_DIR)/arm_cache.conf
	cd $(GLIB_DIR) && CC="$(CC) -std=gnu89" ./configure -q \
		--with-libiconv=no --with-threads=none --prefix=$(CURDIR)/$(GLIB_DIR) \
		$(if $(EMULATE_READER),,--host=$(CHOST) --cache-file=arm_cache.conf) \
		&& $(MAKE) -j$(PROCESSORS) install
ifdef POCKETBOOK
	cp -fL $(GLIB_DIR)/lib/$(notdir $(GLIB)) $(OUTPUT_DIR)/libs/$(notdir $(GLIB))
endif

$(ZLIB):
ifdef WIN32
	cd $(ZLIB_DIR) && DESTDIR=$(CURDIR)/$(ZLIB_DIR)/ INCLUDE_PATH=include \
		LIBRARY_PATH=lib BIN_PATH=bin \
		$(MAKE) -f win32/Makefile.gcc \
		CC="$(CC)" RC=$(CHOST)-windres \
		SHARED_MODE=1 install
	cp -fL $(ZLIB_DIR)/$(notdir $(ZLIB)) $(ZLIB)
else
	cd $(ZLIB_DIR) && CC="$(CC)" ./configure \
		--prefix=$(CURDIR)/$(ZLIB_DIR) \
		&& $(MAKE) -j$(PROCESSORS) --silent shared install
	cp -fL $(ZLIB_DIR)/lib/$(notdir $(ZLIB)) $(ZLIB)
endif

# ===========================================================================
# console version of StarDict(sdcv)

$(OUTPUT_DIR)/sdcv: $(GLIB) $(ZLIB)
ifeq ("$(shell $(CC) -dumpmachine | sed s/-.*//)","x86_64")
	# quick fix for x86_64 (zeus)
	cd $(SDCV_DIR) && sed -i 's|guint32 page_size|guint64 page_size|' src/lib/lib.cpp
endif
	cd $(SDCV_DIR) && ./configure \
		$(if $(EMULATE_READER),,--host=$(CHOST)) \
		PKG_CONFIG_PATH="../$(GLIB_DIR)/lib/pkgconfig" \
		CXX="$(CXX)" \
		CXXFLAGS="$(CXXFLAGS) -I$(CURDIR)/$(ZLIB_DIR)" \
		LDFLAGS="$(LDFLAGS) -L$(CURDIR)/$(ZLIB_DIR) -static-libstdc++" \
		&& $(MAKE) -j$(PROCESSORS) --silent
	# restore to original source
	cd $(SDCV_DIR) && sed -i 's|guint64 page_size|guint32 page_size|' src/lib/lib.cpp
	cp $(SDCV_DIR)/src/sdcv $(OUTPUT_DIR)/

# ===========================================================================
# tar: tar package for zsync

$(OUTPUT_DIR)/tar:
	cd $(TAR_DIR) && ./configure -q LIBS=$(if $(WIN32),,-lrt) \
		$(if $(EMULATE_READER),,--host=$(CHOST)) \
		&& $(MAKE) -j$(PROCESSORS) --silent
	cp $(TAR_DIR)/src/tar $(OUTPUT_DIR)/

# ===========================================================================
# zsync: rsync over HTTP

$(OUTPUT_DIR)/zsync:
	cd $(ZSYNC_DIR) && autoreconf -fi && ./configure -q \
		$(if $(EMULATE_READER),,--host=$(CHOST)) \
		&& $(MAKE) -j$(PROCESSORS) --silent
	cp $(ZSYNC_DIR)/zsync $(OUTPUT_DIR)/

# ===========================================================================
# common lua library for networking
$(LUASOCKET):
	cd $(LUA_SOCKET_DIR) && sed -i 's|socket\.core|socket\.score|' src/*
	cd $(LUA_SOCKET_DIR) && sed -i 's|socket_core|socket_score|' src/*
	cd $(LUA_SOCKET_DIR) && sed -i 's|mime\.core|mime\.mcore|' src/*
	cd $(LUA_SOCKET_DIR) && sed -i 's|mime_core|mime_mcore|' src/*
	cd $(LUA_SOCKET_DIR) && sed -i 's|SOCKET_CDIR)/core|SOCKET_CDIR)/score|' src/*
	cd $(LUA_SOCKET_DIR) && sed -i 's|MIME_CDIR)/core|MIME_CDIR)/mcore|' src/*
	$(MAKE) -C $(LUA_SOCKET_DIR) PLAT=$(if $(WIN32),mingw,linux) \
		CC="$(CC) $(CFLAGS)" LD="$(CC)" \
		$(if $(ANDROID),MYLDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),LUALIB_mingw="$(CURDIR)/$(LUAJIT_LIB)",) \
		LUAINC="$(CURDIR)/$(LUA_DIR)/src" \
		INSTALL_TOP_LDIR="$(CURDIR)/$(OUTPUT_DIR)/common" \
		INSTALL_TOP_CDIR="$(CURDIR)/$(OUTPUT_DIR)/common" \
		--silent all install

$(OPENSSL_LIB):
	cd $(OPENSSL_DIR) && \
		$(if $(WIN32),CROSS_COMPILE=$(CHOST)-,) \
		$(if $(EMULATE_READER),./config,./Configure \
		$(if $(WIN32),mingw,linux-generic32)) \
		$(if $(WIN32),no-,)shared no-asm no-idea no-mdc2 no-rc5 \
		&& $(MAKE) CC="$(CC) $(CFLAGS)" \
		LD=$(LD) RANLIB=$(RANLIB) \
		--silent build_crypto build_ssl
ifneq (,$(filter $(TARGET), android pocketbook))
	cp -fL $(OPENSSL_DIR)/$(notdir $(SSL_LIB)) $(SSL_LIB)
	cp -fL $(OPENSSL_DIR)/$(notdir $(CRYPTO_LIB)) $(CRYPTO_LIB)
endif

$(LUASEC): $(OPENSSL_LIB)
	$(MAKE) -C $(LUA_SEC_DIR) CC="$(CC) $(CFLAGS)" LD="$(CC)" \
		$(if $(ANDROID),LIBS="-lssl -lcrypto -lluasocket $(CURDIR)/$(LUAJIT_LIB)",) \
		INC_PATH="-I$(CURDIR)/$(LUA_DIR)/src -I$(CURDIR)/$(OPENSSL_DIR)/include" \
		LIB_PATH="-L$(CURDIR)/$(OPENSSL_DIR)" \
		LUAPATH="$(CURDIR)/$(OUTPUT_DIR)/common" \
		LUACPATH="$(CURDIR)/$(OUTPUT_DIR)/common" \
		--silent linux install

$(EVERNOTE_LIB):
	$(MAKE) -C $(EVERNOTE_SDK_DIR)/thrift CC="$(CC) $(CFLAGS)" \
		$(if $(ANDROID),LDFLAGS="$(LDFLAGS) -lm $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),LDFLAGS="$(LDFLAGS) -lm $(CURDIR)/$(LUAJIT_LIB)",) \
		OUTPUT_DIR=$(CURDIR)/$(EVERNOTE_PLUGIN_DIR)/lib

$(LUASERIAL_LIB):
	$(MAKE) -C $(LUASERIAL_DIR) CC="$(CC) $(CFLAGS)" \
		$(if $(ANDROID),LDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		$(if $(WIN32),LDFLAGS="$(LDFLAGS) $(CURDIR)/$(LUAJIT_LIB)",) \
		OUTPUT_DIR=$(CURDIR)/$(OUTPUT_DIR)/common

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
$(ZMQ_LIB):
	mkdir -p $(ZMQ_DIR)/build
	cd $(ZMQ_DIR) && sh autogen.sh
	cd $(ZMQ_DIR)/src && sed -i 's|libzmq_la_LDFLAGS = -avoid-version|libzmq_la_LDFLAGS =|g' Makefile.am
	cd $(ZMQ_DIR)/build && \
		CC="$(CC)" CFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" \
		LDFLAGS="$(LDFLAGS)" \
		libzmq_have_xmlto=no libzmq_have_asciidoc=no \
			../configure -q --prefix=$(CURDIR)/$(ZMQ_DIR)/build \
				$(if $(POCKETBOOK),--disable-eventfd,) \
				--disable-static --enable-shared \
				--host=$(CHOST)
	-$(MAKE) -j$(PROCESSORS) -C $(ZMQ_DIR)/build --silent uninstall
	$(MAKE) -j$(PROCESSORS) -C $(ZMQ_DIR)/build --silent install
	cp -fL $(ZMQ_DIR)/build/$(if $(WIN32),bin,lib)/$(notdir $(ZMQ_LIB)) $@
ifdef POCKETBOOK
	# when cross compiling libtool would find libstdc++.la in wrong location
	# accoding to the GCC configuration
	sed -i 's|^dependency_libs=.*|dependency_libs=" -lrt -lpthread -lstdc++"|g' \
		$(ZMQ_DIR)/build/lib/libzmq.la
	# and the libuuid.so is also missing in the PocketBook SDK, but libuuid.la
	# may let the build system assume that libuuid is installed
	rm -f $(CURDIR)/$(POCKETBOOK_TOOLCHAIN)/arm-obreey-linux-gnueabi/sysroot/usr/lib/libuuid*
endif

$(CZMQ_LIB): $(ZMQ_LIB)
	mkdir -p $(CZMQ_DIR)/build
	cd $(CZMQ_DIR) && sh autogen.sh
	cd $(CZMQ_DIR)/build && \
		CC="$(CC)" \
		LDFLAGS="$(LDFLAGS) -Wl,-rpath,'libs'" \
		CFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) $(if $(WIN32),-DLIBCZMQ_EXPORTS)" \
		czmq_have_xmlto=no czmq_have_asciidoc=no \
			../configure -q --prefix=$(CURDIR)/$(CZMQ_DIR)/build \
				--with-gnu-ld \
				--with-libzmq=$(CURDIR)/$(ZMQ_DIR)/build \
				--disable-static --enable-shared \
				--host=$(CHOST)
	# hack to remove hardcoded rpath
	cd $(CZMQ_DIR)/build && \
		sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool && \
		sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool
	# patch: ignore limited broadcast address
	-cd $(CZMQ_DIR) && patch -N -p1 < ../zbeacon.patch
	# patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
	-cd $(CZMQ_DIR) && patch -N -p1 < ../czmq_default_source_define.patch
	-$(MAKE) -j$(PROCESSORS) -C $(CZMQ_DIR)/build --silent uninstall
	$(MAKE) -j$(PROCESSORS) -C $(CZMQ_DIR)/build --silent install
	-cd $(CZMQ_DIR) && patch -R -p1 < ../zbeacon.patch
	-cd $(CZMQ_DIR) && patch -R -p1 < ../czmq_default_source_define.patch
	cp -fL $(CZMQ_DIR)/build/$(if $(WIN32),bin,lib)/$(notdir $(CZMQ_LIB)) $@

$(FILEMQ_LIB): $(ZMQ_LIB) $(CZMQ_LIB) $(OPENSSL_LIB)
	mkdir -p $(FILEMQ_DIR)/build
	cd $(FILEMQ_DIR) && sh autogen.sh
	cd $(FILEMQ_DIR)/build && \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) $(if $(CLANG),-O0,) -I$(CURDIR)/$(OPENSSL_DIR)/include" \
		LDFLAGS="$(LDFLAGS) -L$(CURDIR)/$(OPENSSL_DIR) -Wl,-rpath,'libs'" \
		fmq_have_xmlto=no fmq_have_asciidoc=no \
			../configure -q --prefix=$(CURDIR)/$(FILEMQ_DIR)/build \
				--with-libzmq=$(CURDIR)/$(ZMQ_DIR)/build \
				--with-libczmq=$(CURDIR)/$(CZMQ_DIR)/build \
				--disable-static --enable-shared \
				--host=$(CHOST)
	cd $(FILEMQ_DIR)/build && \
		sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool && \
		sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool
	-$(MAKE) -j$(PROCESSORS) -C $(FILEMQ_DIR)/build --silent uninstall
	$(MAKE) -j$(PROCESSORS) -C $(FILEMQ_DIR)/build --silent install
	cp -fL $(FILEMQ_DIR)/build/$(if $(WIN32),bin,lib)/$(notdir $(FILEMQ_LIB)) $@

$(ZYRE_LIB): $(ZMQ_LIB) $(CZMQ_LIB)
	mkdir -p $(ZYRE_DIR)/build
	cd $(ZYRE_DIR) && sh autogen.sh
	cd $(ZYRE_DIR)/build && \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS) $(if $(CLANG),-O0,)" CXXFLAGS="$(CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS) -Wl,-rpath,'libs'" \
		zyre_have_xmlto=no zyre_have_asciidoc=no \
			../configure -q --prefix=$(CURDIR)/$(ZYRE_DIR)/build \
				--with-libzmq=$(CURDIR)/$(ZMQ_DIR)/build \
				--with-libczmq=$(CURDIR)/$(CZMQ_DIR)/build \
				--disable-static --enable-shared \
				--host=$(CHOST)
	cd $(ZYRE_DIR)/build && \
		sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' libtool && \
		sed -i 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool
	-$(MAKE) -j$(PROCESSORS) -C $(ZYRE_DIR)/build --silent uninstall
	$(MAKE) -j$(PROCESSORS) -C $(ZYRE_DIR)/build --silent install
	cp -fL $(ZYRE_DIR)/build/$(if $(WIN32),bin,lib)/$(notdir $(ZYRE_LIB)) $@

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
	rm -rf mupdf/thirdparty
	rm -rf kpvcrlib/crengine/thirdparty
	test -d mupdf \
		&& (cd mupdf; git checkout .) \
		|| echo warn: mupdf folder not found
	test -d kpvcrlib/crengine \
		&& (cd kpvcrlib/crengine; git checkout .) \
		|| echo warn: crengine folder not found
	test -d $(LUA_DIR) \
		&& (cd $(LUA_DIR); git checkout .) \
		|| echo warn: $(LUA_DIR) folder not found
	git submodule init
	git submodule sync
	git submodule update
	cd mupdf && (git submodule init; git submodule update)
	# MuPDF patch: use external fonts
	cd mupdf && patch -N -p1 < ../mupdf.patch
	# update submodules in plugins
	cd plugins/evernote-sdk-lua && (git submodule init; git submodule update)
	# update submodules in lua-serialize
	cd lua-serialize && (git submodule init; git submodule update)
	# Download popen-noshell
	test -f popen-noshell/popen_noshell.c \
		|| svn co http://popen-noshell.googlecode.com/svn/trunk/ \
			popen-noshell
	# popen_noshell patch: Make it build on recent TCs, and implement
	# a simple Makefile for building it as a static lib
	cd popen-noshell \
		&& test -f Makefile \
		|| patch -N -p0 < popen_noshell-buildfix.patch
	# download leptonica and tesseract-ocr src for libk2pdfopt
	[ ! -f $(K2PDFOPT_DIR)/leptonica-1.69.tar.gz ] \
		&& cd $(K2PDFOPT_DIR) \
		&& wget http://leptonica.com/source/leptonica-1.69.tar.gz || true
	[ `md5sum $(K2PDFOPT_DIR)/leptonica-1.69.tar.gz|cut -d\  -f1` != d4085c302cbcab7f9af9d3d6f004ab22 ] \
		&& cd $(K2PDFOPT_DIR) && rm leptonica-1.69.tar.gz \
		&& wget http://leptonica.com/source/leptonica-1.69.tar.gz || true
	cd $(K2PDFOPT_DIR) && tar zxf leptonica-1.69.tar.gz
	# patch leptonica for a small typo, it's already fixed in 1.70
	cd $(K2PDFOPT_DIR)/leptonica-1.69 && sed -i 's|hfind|hFind|g' src/utils.c
	[ ! -f $(K2PDFOPT_DIR)/tesseract-ocr-3.02.02.tar.gz ] \
		&& cd $(K2PDFOPT_DIR) \
		&& wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz || true
	[ `md5sum $(K2PDFOPT_DIR)/tesseract-ocr-3.02.02.tar.gz|cut -d\  -f1` != 26adc8154f0e815053816825dde246e6 ] \
		&& cd $(K2PDFOPT_DIR) && rm tesseract-ocr-3.02.02.tar.gz \
		&& wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz || true
	cd $(K2PDFOPT_DIR) && tar zxf tesseract-ocr-3.02.02.tar.gz
	sed -i "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g" $(K2PDFOPT_DIR)/tesseract-ocr/configure.ac
	# download glib-2.6.6 for sdcv
	[ ! -f glib-2.6.6.tar.gz ] \
		&& wget http://ftp.gnome.org/pub/gnome/sources/glib/2.6/glib-2.6.6.tar.gz || true
	[ `md5sum glib-2.6.6.tar.gz |cut -d\  -f1` != dba15cceeaea39c5a61b6844d2b7b920 ] \
		&& rm glib-2.6.6.tar.gz && wget http://ftp.gnome.org/pub/gnome/sources/glib/2.6/glib-2.6.6.tar.gz || true
	tar zxf glib-2.6.6.tar.gz
	# download openssl-1.0.1 for luasec
	[ ! -f openssl-1.0.1h.tar.gz ] \
		&& wget http://www.openssl.org/source/openssl-1.0.1h.tar.gz || true
	[ `md5sum openssl-1.0.1h.tar.gz |cut -d\  -f1` != 8d6d684a9430d5cc98a62a5d8fbda8cf ] \
		&& rm openssl-1.0.1h.tar.gz && wget http://www.openssl.org/source/openssl-1.0.1h.tar.gz || true
	tar zxf openssl-1.0.1h.tar.gz
	# download tar for zsync
	[ ! -f tar-1.28.tar.gz ] \
		&& wget http://ftp.gnu.org/gnu/tar/tar-1.28.tar.gz || true
	[ `md5sum tar-1.28.tar.gz |cut -d\  -f1` != 6ea3dbea1f2b0409b234048e021a9fd7 ] \
		&& rm tar-1.28.tar.gz && wget http://ftp.gnu.org/gnu/tar/tar-1.28.tar.gz || true
	tar zxf tar-1.28.tar.gz
	# download libpng
	[ ! -f libpng-1.6.12.tar.gz ] \
		&& wget http://download.sourceforge.net/libpng/libpng-1.6.12.tar.gz || true
	[ `md5sum libpng-1.6.12.tar.gz |cut -d\  -f1` != 297388a6746a65a2127ecdeb1c6e5c82 ] \
		&& rm libpng-1.6.12.tar.gz && wget http://download.sourceforge.net/libpng/libpng-1.6.12.tar.gz || true
	tar zxf libpng-1.6.12.tar.gz
	# download libjpeg-turbo
	[ ! -f libjpeg-turbo-1.3.1.tar.gz ] \
		&& wget http://download.sourceforge.net/libjpeg-turbo/libjpeg-turbo-1.3.1.tar.gz || true
	[ `md5sum libjpeg-turbo-1.3.1.tar.gz |cut -d\  -f1` != 2c3a68129dac443a72815ff5bb374b05 ] \
		&& rm libjpeg-turbo-1.3.1.tar.gz && false || tar zxf libjpeg-turbo-1.3.1.tar.gz
	# download giflib
	[ ! -f giflib-5.1.0.tar.gz ] \
		&& wget http://download.sourceforge.net/giflib/giflib-5.1.0.tar.gz || true
	[ `md5sum giflib-5.1.0.tar.gz |cut -d\  -f1` != 40248cb52f525dc82981761628dbd853 ] \
		&& rm giflib-5.1.0.tar.gz && false || tar zxf giflib-5.1.0.tar.gz

# ===========================================================================
clean:
	-rm -rf $(OUTPUT_DIR)/*
	-rm -rf $(CRENGINE_WRAPPER_BUILD_DIR)
	-rm -rf $(DJVULIBRE_DIR)/build
	-$(MAKE) -C $(LUA_DIR) CC="$(HOSTCC)" CFLAGS="$(BASE_CFLAGS)" clean
	-$(MAKE) -C $(MUPDF_DIR) build="release" clean
	-$(MAKE) -C $(POPEN_NOSHELL_DIR) clean
	-$(MAKE) -C $(K2PDFOPT_DIR) clean
	-$(MAKE) -C $(JPEG_DIR) clean uninstall
	-$(MAKE) -C $(SDCV_DIR) clean
	-$(MAKE) -C $(PNG_DIR) clean uninstall
	-$(MAKE) -C $(GIF_DIR) clean uninstall
	-$(MAKE) -C $(GLIB_DIR) clean uninstall
	-$(MAKE) -C $(ZLIB_DIR) clean uninstall
	-$(MAKE) -C $(ZSYNC_DIR) clean
	-$(MAKE) -C $(TAR_DIR) clean
	-$(MAKE) -C $(FREETYPE_DIR)/build clean uninstall distclean
	-$(MAKE) -C $(LUA_SOCKET_DIR) clean
	-$(MAKE) -C $(LUA_SEC_DIR) clean
	-$(MAKE) -C $(OPENSSL_DIR) clean
	-$(MAKE) -C $(ZMQ_DIR)/build clean uninstall
	-$(MAKE) -C $(CZMQ_DIR)/build clean uninstall
	-$(MAKE) -C $(FILEMQ_DIR)/build clean uninstall
	-$(MAKE) -C $(ZYRE_DIR)/build clean uninstall

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
	cd $(OUTPUT_DIR) && busted -l ./luajit

.PHONY: test
