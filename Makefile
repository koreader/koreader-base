include Makefile.defs

# main target
all: $(OUTPUT_DIR) $(LUAJIT) $(OUTPUT_DIR)/extr $(OUTPUT_DIR)/sdcv libs
ifndef EMULATE_READER
	$(STRIP) --strip-unneeded \
		$(OUTPUT_DIR)/extr \
		$(OUTPUT_DIR)/sdcv \
		$(LUAJIT) \
		$(OUTPUT_DIR)/*.so*
endif
	# set up some needed paths and links
	ln -sf ../../kpvcrlib/crengine/cr3gui/data $(OUTPUT_DIR)/data
	test -d $(OUTPUT_DIR)/history || mkdir $(OUTPUT_DIR)/history
	test -d $(OUTPUT_DIR)/clipboard || mkdir $(OUTPUT_DIR)/clipboard
	test -e $(OUTPUT_DIR)/data/cr3.css || \
		ln -sf ../../kpvcrlib/cr3.css $(OUTPUT_DIR)/data/
	test -d $(OUTPUT_DIR)/fonts || \
		ln -sf ../../$(TTF_FONTS_DIR) $(OUTPUT_DIR)/fonts
	test -e $(OUTPUT_DIR)/koreader-base || \
		ln -sf ../../koreader-base $(OUTPUT_DIR)/

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# ===========================================================================

# third party libraries:
# (for directory and file name config, see Makefile.defs)

# freetype, fetched via GIT as a submodule
$(FREETYPE_LIB):
	mkdir -p $(FREETYPE_DIR)/build
	cd $(FREETYPE_DIR) && sh autogen.sh
	cd $(FREETYPE_DIR)/build && \
		CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
			../configure --disable-static --enable-shared \
				--without-zlib --without-bzip2 \
				--without-png \
				--host=$(CHOST)
	$(MAKE) -C $(FREETYPE_DIR)/build
	cp -fL $(FREETYPE_DIR)/build/.libs/$(notdir $(FREETYPE_LIB)) $@


# libjpeg, fetched via GIT as a submodule
$(JPEG_LIB):
	cd $(JPEG_DIR) && \
		CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
			./configure --disable-static --enable-shared \
				--host=$(CHOST)
	$(MAKE) -C $(JPEG_DIR)
	cp -fL $(JPEG_DIR)/.libs/$(notdir $(JPEG_LIB)) $@


# mupdf, fetched via GIT as a submodule
# by default, mupdf compiles to a static library:
$(MUPDF_LIB_STATIC) $(MUPDF_THIRDPARTY_LIBS): $(JPEG_LIB) $(FREETYPE_LIB)
	$(MAKE) -C mupdf generate build="release" CC="$(HOSTCC)" \
		OS="Other" verbose=1
	$(MAKE) -C mupdf \
		LDFLAGS="-L../$(OUTPUT_DIR)" \
		XCFLAGS="$(CFLAGS) -DNOBUILTINFONT -fPIC -I../jpeg" \
		CC="$(CC)" \
		build="release" MUDRAW= MUTOOL= NOX11=yes \
		OS="Other" verbose=1 \
		FREETYPE_DIR=nonexisting \
		SYS_FREETYPE_INC="-I../$(FREETYPE_DIR)/include" \
		JPEG_DIR=nonexisting \
		CROSSCOMPILE=yes

# we generate a dynamic library from the static library:
$(MUPDF_LIB): $(MUPDF_LIB_STATIC) \
			$(MUPDF_THIRDPARTY_LIBS) \
			$(JPEG_LIB) \
			$(FREETYPE_LIB)
	$(CC) $(DYNLIB_CFLAGS) -fPIC -shared \
		-Wl,--whole-archive $(MUPDF_LIB_STATIC) \
		-Wl,--no-whole-archive $(MUPDF_THIRDPARTY_LIBS) \
		$(JPEG_LIB) $(FREETYPE_LIB) \
		-o $(MUPDF_LIB)


# djvulibre, fetched via GIT as a submodule
$(DJVULIBRE_LIB):
	mkdir -p $(DJVULIBRE_DIR)/build
	test -e $(DJVULIBRE_DIR)/build/Makefile \
		|| ( cd $(DJVULIBRE_DIR)/build \
		&& CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS) -fPIC" \
		CXXFLAGS="$(CXXFLAGS) -fPIC" LDFLAGS="$(LDFLAGS)" \
		../configure --disable-desktopfiles \
			--disable-static --enable-shared \
			--disable-xmltools --disable-largefile \
			$(if $(EMULATE_READER),,-host=$(CHOST)) )
	$(MAKE) -C $(DJVULIBRE_DIR)/build SUBDIRS_FIRST=libdjvu
	cp -fL $(DJVULIBRE_LIB_DIR)/$(notdir $(DJVULIBRE_LIB)) \
		$(DJVULIBRE_LIB)


# crengine, fetched via GIT as a submodule
$(CRENGINE_THIRDPARTY_LIBS) $(CRENGINE_LIB):
	test -e $(CRENGINE_WRAPPER_DIR)/CMakeFiles \
	|| ( cd $(CRENGINE_WRAPPER_DIR) \
	&& CFLAGS="$(CFLAGS) -fPIC" \
		CXXFLAGS="$(CXXFLAGS) -fPIC" CC="$(CC)" \
		CXX="$(CXX)" LDFLAGS="$(LDFLAGS)" \
		cmake -D CMAKE_BUILD_TYPE=Release . )
	cd $(CRENGINE_WRAPPER_DIR) &&  $(MAKE) VERBOSE=1
	cp -fL $(CRENGINE_WRAPPER_DIR)/$(notdir $(CRENGINE_LIB)) \
		$(CRENGINE_LIB)


# LuaJIT, fetched via GIT as a submodule
$(LUA_LIB) $(LUAJIT):
ifdef EMULATE_READER
	$(MAKE) -C $(LUA_DIR)
else
	# To recap: build its TARGET_CC from CROSS+CC, so we need HOSTCC in CC.
	# Build its HOST/TARGET_CFLAGS based on CFLAGS, so we need
	# a neutral CFLAGS without arch
	$(MAKE) -C $(LUA_DIR) \
		CC="$(HOSTCC)" HOST_CC="$(HOSTCC) -m32" \
		CFLAGS="$(BASE_CFLAGS)" HOST_CFLAGS="$(HOSTCFLAGS)" \
		TARGET_CFLAGS="$(CFLAGS)" \
		TARGET_FLAGS="-DLUAJIT_NO_LOG2 -DLUAJIT_NO_EXP2" \
		CROSS="$(CHOST)-"
endif
	# special case: LuaJIT compiles a libluajit.so, which must be named
	# differently when installing
	cp -fL $(LUA_DIR)/src/libluajit.so* $(LUA_LIB)
	cp -fL $(LUA_DIR)/src/$(notdir $(LUAJIT)) $(LUAJIT)


# popen-noshell, fetched via SVN
$(POPEN_NOSHELL_LIB):
	$(MAKE) -C $(POPEN_NOSHELL_DIR) \
		CC="$(CC)" AR="$(AR)" CFLAGS="$(CFLAGS) -fPIC"


# k2pdfopt, fetched via GIT as a submodule
$(K2PDFOPT_LIB) $(LEPTONICA_LIB) $(TESSERACT_LIB):
ifdef EMULATE_READER
	$(MAKE) -j$(PROCESSORS) -C $(K2PDFOPT_DIR) BUILDMODE=shared \
		CC="$(HOSTCC)" CFLAGS="$(HOSTCFLAGS)" \
		CXX="$(HOSTCXX)" CXXFLAGS="$(HOSTCFLAGS)" \
		AR="$(AR)" EMULATE_READER=1 all
else
	$(MAKE) -j$(PROCESSORS) -C $(K2PDFOPT_DIR) BUILDMODE=shared HOST="$(CHOST)" \
		CC="$(CC)" CFLAGS="$(CFLAGS) -O3" \
		CXX="$(CXX)" CXXFLAGS="$(CXXFLAGS)" \
		AR="$(AR)" all
endif
	cp -a $(K2PDFOPT_DIR)/libk2pdfopt.so* $(OUTPUT_DIR)/
	cp -a $(K2PDFOPT_DIR)/liblept.so* $(OUTPUT_DIR)/
	cp -a $(K2PDFOPT_DIR)/libtesseract.so* $(OUTPUT_DIR)/


# end of third-party code
# ===========================================================================

# our own Lua/C/C++ interfacing:

libs: \
	$(OUTPUT_DIR)/libkoreader-util.so \
	$(OUTPUT_DIR)/libkoreader-kobolight.so \
	$(OUTPUT_DIR)/libkoreader-input.so \
	$(OUTPUT_DIR)/libkoreader-einkfb.so \
	$(OUTPUT_DIR)/libkoreader-drawcontext.so \
	$(OUTPUT_DIR)/libkoreader-blitbuffer.so \
	$(OUTPUT_DIR)/libkoreader-lfs.so \
	$(OUTPUT_DIR)/libkoreader-koptcontext.so \
	$(OUTPUT_DIR)/libkoreader-pic.so \
	$(OUTPUT_DIR)/libkoreader-ft.so \
	$(OUTPUT_DIR)/libkoreader-pdf.so \
	$(OUTPUT_DIR)/libkoreader-djvu.so \
	$(OUTPUT_DIR)/libkoreader-cre.so \
	$(OUTPUT_DIR)/libkoreader-mupdfimg.so

$(OUTPUT_DIR)/libkoreader-util.so: util.c \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) $(EMU_CFLAGS) $(EMU_LDFLAGS) \
		-o $@ $<

$(OUTPUT_DIR)/libkoreader-kobolight.so: kobolight.c \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) $(EMU_CFLAGS) $(EMU_LDFLAGS) \
		-o $@ $<

$(OUTPUT_DIR)/libkoreader-input.so: input.c \
				$(POPEN_NOSHELL_LIB) \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) $(EMU_CFLAGS) $(EMU_LDFLAGS) \
		-o $@ $< $(POPEN_NOSHELL_LIB)

$(OUTPUT_DIR)/libkoreader-einkfb.so: einkfb.c \
				$(LUA_LIB)
	$(CC) -Iinclude/ $(DYNLIB_CFLAGS) $(EMU_CFLAGS) $(EMU_LDFLAGS) \
		-o $@ $<

$(OUTPUT_DIR)/libkoreader-drawcontext.so: drawcontext.c \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) -o $@ $<

$(OUTPUT_DIR)/libkoreader-blitbuffer.so: blitbuffer.c \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) -o $@ $<

$(OUTPUT_DIR)/libkoreader-lfs.so: luafilesystem/src/lfs.c \
				$(LUA_LIB)
	$(CC) $(DYNLIB_CFLAGS) -o $@ $<

$(OUTPUT_DIR)/libkoreader-koptcontext.so: koptcontext.c \
				$(K2PDFOPT_LIB) $(LUA_LIB)
	$(CC) $(K2PDFOPT_CFLAGS) $(DYNLIB_CFLAGS) -o $@ $<

$(OUTPUT_DIR)/libkoreader-pic.so: pic.c pic_jpeg.c \
				$(JPEG_LIB) \
				$(LUA_LIB)
	$(CC) -I$(JPEG_DIR) $(DYNLIB_CFLAGS) $(JPEG_LIB) \
		-o $@ $< pic_jpeg.c

$(OUTPUT_DIR)/libkoreader-ft.so: ft.c \
				$(MUPDF_THIRDPARTY_LIBS) \
				$(LUA_LIB)
	$(CC) -I$(FREETYPE_DIR)/include $(DYNLIB_CFLAGS) $(FREETYPE_LIB) \
		-lkoreader-blitbuffer -o $@ $<

$(OUTPUT_DIR)/libkoreader-pdf.so: pdf.c \
				$(MUPDF_LIB) \
				$(K2PDFOPT_LIB) \
				$(LUA_LIB)
	$(CC) -I$(MUPDF_DIR) $(K2PDFOPT_CFLAGS) $(DYNLIB_CFLAGS) \
		$(K2PDFOPT_LIB) $(MUPDF_LIB) -lpthread -o $@ $<

$(OUTPUT_DIR)/libkoreader-djvu.so: djvu.c \
				$(DJVULIBRE_LIB) \
				$(LUA_LIB)
	$(CC) -I$(DJVULIBRE_DIR)/ $(K2PDFOPT_CFLAGS) \
		$(DYNLIB_CFLAGS) $(DJVULIBRE_LIB) $(K2PDFOPT_LIB) \
		-o $@ $<

$(OUTPUT_DIR)/libkoreader-cre.so: cre.cpp \
				$(CRENGINE_LIB) \
				$(CRENGINE_THIRDPARTY_LIBS) \
				$(MUPDF_LIB_DIR)/libz.a \
				$(LUA_LIB)
	$(CC) -I$(CRENGINE_DIR)/crengine/include/ $(DYNLIB_CFLAGS) \
		$(CRENGINE_LIB) $(JPEG_LIB) $(FREETYPE_LIB) \
		$(DYNAMICLIBSTDCPP) -o $@ $< \
		$(CRENGINE_THIRDPARTY_LIBS) $(MUPDF_LIB_DIR)/libz.a \
		$(STATICLIBSTDCPP)

$(OUTPUT_DIR)/libkoreader-mupdfimg.so: mupdfimg.c \
				$(JPEG_LIB) \
				$(FREETYPE_LIB) \
				$(LUA_LIB)
	$(CC) -I$(MUPDF_DIR) $(DYNLIB_CFLAGS) $(MUPDF_LIB) \
		-lkoreader-blitbuffer -o $@ $<

# ===========================================================================

# the attachment extraction tool:

$(OUTPUT_DIR)/extr: extr.c \
				$(MUPDF_LIB) \
				$(JPEG_LIB) \
				$(FREETYPE_LIB)
	$(CC) -I$(MUPDF_DIR) -I$(MUPDF_DIR)/pdf -I$(MUPDF_DIR)/fitz \
		$(CFLAGS) -Wl,-rpath,'$$ORIGIN' \
		$(MUPDF_LIB) $(JPEG_LIB) $(FREETYPE_LIB) -lm \
		-o $@ $<

# ===========================================================================

# StarDict tool

$(OUTPUT_DIR)/sdcv:
ifdef EMULATE_READER
ifeq ("$(shell gcc -dumpmachine | sed s/-.*//)","x86_64")
	# quick fix for x86_64 (zeus)
	cd $(SDCV_DIR) && sed -i 's|guint32 page_size|guint64 page_size|' src/lib/lib.cpp
	cd $(SDCV_DIR) && ./configure \
		CXXFLAGS=-I$(CURDIR)/$(MUPDF_DIR)/thirdparty/zlib \
		&& AM_CXXFLAGS=-static-libstdc++ make
	# restore to original source
	cd $(SDCV_DIR) && sed -i 's|guint64 page_size|guint32 page_size|' src/lib/lib.cpp
else
	cd $(SDCV_DIR) && ./configure \
		CXXFLAGS=-I$(CURDIR)/$(MUPDF_DIR)/thirdparty/zlib \
		&& AM_CXXFLAGS=-static-libstdc++ make
endif
else
	cd $(SDCV_DIR) && ./configure \
		--host=$(CHOST) \
		CXXFLAGS=-I$(CURDIR)/$(MUPDF_DIR)/thirdparty/zlib \
		LDFLAGS=-L$(CURDIR)/$(SDCV_DIR)/thirdparty \
		&& AM_CXXFLAGS=-static-libstdc++ make
endif
	cp $(SDCV_DIR)/src/sdcv $(OUTPUT_DIR)/

# ===========================================================================

# helper target for initializing third-party code

fetchthirdparty:
	rm -rf mupdf/thirdparty
	test -d mupdf \
		&& (cd mupdf; git checkout .) \
		|| echo warn: mupdf folder not found
	test -d $(LUA_DIR) \
		&& (cd $(LUA_DIR); git checkout .) \
		|| echo warn: $(LUA_DIR) folder not found
	git submodule init
	git submodule update
	cd mupdf && (git submodule init; git submodule update)
	# CREngine patch: change child nodes' type face
	# @TODO replace this dirty hack  24.04 2012 (houqp)
	cd $(CRENGINE_DIR) && git stash && \
		git apply ../lvrend-setNodeStyle.patch && \
		git apply ../lvdocview-getCurrentPageLinks.patch
	# CREngine patch: disable fontconfig
	grep USE_FONTCONFIG $(CRENGINE_DIR)/crengine/include/crsetup.h \
		&& grep -v USE_FONTCONFIG \
			$(CRENGINE_DIR)/crengine/include/crsetup.h \
			> /tmp/new \
		&& mv /tmp/new $(CRENGINE_DIR)/crengine/include/crsetup.h \
		|| echo "USE_FONTCONFIG already disabled"
	# MuPDF patch: use external fonts
	cd mupdf && patch -N -p1 < ../mupdf.patch
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
	[ ! -f $(K2PDFOPT_DIR)/tesseract-ocr-3.02.02.tar.gz ] \
		&& cd $(K2PDFOPT_DIR) \
		&& wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz || true
	[ `md5sum $(K2PDFOPT_DIR)/tesseract-ocr-3.02.02.tar.gz|cut -d\  -f1` != 26adc8154f0e815053816825dde246e6 ] \
		&& cd $(K2PDFOPT_DIR) && rm tesseract-ocr-3.02.02.tar.gz \
		&& wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz || true
	cd $(K2PDFOPT_DIR) && tar zxf tesseract-ocr-3.02.02.tar.gz
	sed -i "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g" $(K2PDFOPT_DIR)/tesseract-ocr/configure.ac

# ===========================================================================

clean:
	-$(MAKE) -C $(LUA_DIR) CC="$(HOSTCC)" CFLAGS="$(BASE_CFLAGS)" clean
	-$(MAKE) -C $(MUPDF_DIR) build="release" clean
	-$(MAKE) -C $(CRENGINE_DIR)/thirdparty/antiword clean
	-test -d $(CRENGINE_DIR)/thirdparty/chmlib \
		&& $(MAKE) -C $(CRENGINE_DIR)/thirdparty/chmlib clean \
		|| echo warn: chmlib folder not found
	-test -d $(CRENGINE_DIR)/thirdparty/libpng \
		&& ($(MAKE) -C $(CRENGINE_DIR)/thirdparty/libpng clean) \
		|| echo warn: chmlib folder not found
	-test -d $(CRENGINE_DIR)/crengine \
		&& ($(MAKE) -C $(CRENGINE_DIR)/crengine clean) \
		|| echo warn: chmlib folder not found
	-test -d $(CRENGINE_WRAPPER_DIR) \
		&& ($(MAKE) -C $(CRENGINE_WRAPPER_DIR) clean) \
		|| echo warn: chmlib folder not found
	-rm -rf $(CRENGINE_WRAPPER_DIR)/CMakeCache.txt
	-rm -rf $(CRENGINE_WRAPPER_DIR)/CMakeFiles
	-rm -rf $(DJVULIBRE_DIR)/build
	-$(MAKE) -C $(POPEN_NOSHELL_DIR) clean
	-$(MAKE) -C $(K2PDFOPT_DIR) clean
	-$(MAKE) -C $(JPEG_DIR) clean
	-$(MAKE) -C $(SDCV_DIR) clean
	-rm -rf $(FREETYPE_DIR)/build
	-rm -rf $(OUTPUT_DIR)/*
