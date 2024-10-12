list(APPEND PATCH_FILES
    # Use external fonts.
    external_fonts.patch
    # Add support for encrypted zips.
    encrypted_zip.patch
    # Disable potentially crashy ARM ASM (it's 7 years old, and hell to debug).
    # NOTE: There's also a few ARCH_UNALIGNED_OK checks, but we never did pass that define.
    #       (FWIW, we *could*, on anything not kindle-legacy).
    no_arm_asm.patch
    # Honor CFLAGS.
    honor_cflags.patch
    # Support for WebP images (unmerged-yet proposed upstream patch cleaned up of win32 stuff).
    webp-upstream-697749.patch
    # Add support for CBZ chapters.
    mupdf_cbz_chapter_support.patch
    # Ensure an HTML document fonts are freed on close.
    free-html-doc-fonts-on-close.patch
    # Relink on change(s) to external libraries.
    relink_on_xlibs_change.patch
    # Fix symbols visiblity.
    visibility.patch
    # Expand list of supported CSS color names.
    css_color_names.patch
)

list(APPEND PATCH_CMD COMMAND rm -rf
    thirdparty/curl
    thirdparty/freeglut
    thirdparty/freetype
    thirdparty/harfbuzz
    thirdparty/leptonica
    thirdparty/libjpeg
    thirdparty/mujs
    thirdparty/tesseract
    thirdparty/zlib
)

string(TOLOWER ${CMAKE_BUILD_TYPE} MUPDF_BUILD_TYPE)

if(WIN32)
    set(OS)
else()
    set(OS Other)
endif()

set(LIB_SPEC mupdf)
set_libname(LIB ${LIB_SPEC})

string(APPEND XCFLAGS
    " ${CFLAGS} -fvisibility=hidden"
    # Disable a couple of things to save a small bit of space:
    # - builtin fonts
    # - color profile support
    # - CMYK plotter only 100 kB
    # - javascript (for form data validation) close to 800 kB
    " -DNOBUILTINFONT"
    " -DFZ_ENABLE_JS=0"
    " -DFZ_PLOTTERS_CMYK=0"
    " -DHAVE_LIBAES=1"
    " -DHAVE_WEBP=1"
)
if(ANDROID AND CHOST MATCHES "^armv7a-.*")
    # NOTE: to be removed when upgrading the minimal supported API level to 24.
    # (https://android.googlesource.com/platform/bionic/+/master/docs/32-bit-abi.md)
    string(APPEND XCFLAGS " -D_FILE_OFFSET_BITS=32")
endif()

set(MAKE_CMD
    make -C ${SOURCE_DIR}
    # Compilation flags.
    AR=${AR}
    CC=${CC}
    CXX=${CXX}
    LDFLAGS=
    XCFLAGS=${XCFLAGS}
    # Disable some vendored libraries:
    # - curl
    USE_SYSTEM_CURL=yes
    HAVE_SYS_CURL=no
    # - freetype
    USE_SYSTEM_FREETYPE=yes
    SYS_FREETYPE_CFLAGS=-I${STAGING_DIR}/include/freetype2
    SYS_FREETYPE_LIBS=
    # - harfbuzzz
    USE_SYSTEM_HARFBUZZ=yes
    SYS_HARFBUZZ_CFLAGS=-I${STAGING_DIR}/include/harfbuzz
    SYS_HARFBUZZ_LIBS=
    # - libjpeg
    USE_SYSTEM_LIBJPEG=yes
    SYS_LIBJPEG_LIBS=
    # - mujs
    MUJS_CFLAGS=
    MUJS_SRC=
    # - zlib
    USE_SYSTEM_ZLIB=yes
    SYS_ZLIB_CFLAGS=-I${STAGING_DIR}/include
    SYS_ZLIB_LIBS=
    ZLIB_CFLAGS=-I${STAGING_DIR}/include
    # Build out of tree.
    OUT=${BINARY_DIR}
    # Other.
    OS=${OS}
    build=${MUPDF_BUILD_TYPE}
    shared=no
    verbose=no
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} libs)

list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} DESTDIR=${STAGING_DIR} prefix=/ install-libs)

external_project(
    DOWNLOAD URL 9634ed1444943a62796c68ec25507619
    https://mupdf.com/downloads/archive/mupdf-1.24.10-source.tar.lz
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
