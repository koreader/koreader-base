list(APPEND PATCH_CMD COMMAND rm -rf
    thirdparty/curl
    thirdparty/freeglut
    thirdparty/freetype
    thirdparty/harfbuzz
    thirdparty/lcms2
    thirdparty/leptonica
    thirdparty/libjpeg
    thirdparty/mujs
    thirdparty/tesseract
    thirdparty/zlib
)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # Use external fonts.
    ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch
    # Add support for encrypted zips.
    ${CMAKE_CURRENT_SOURCE_DIR}/encrypted_zip.patch
    # Disable potentially crashy ARM ASM (it's 7 years old, and hell to debug).
    # NOTE: There's also a few ARCH_UNALIGNED_OK checks, but we never did pass that define.
    #       (FWIW, we *could*, on anything not kindle-legacy).
    ${CMAKE_CURRENT_SOURCE_DIR}/no_arm_asm.patch
    # Honor CFLAGS.
    ${CMAKE_CURRENT_SOURCE_DIR}/honor_cflags.patch
    # Support for WebP images (unmerged-yet proposed upstream patch cleaned up of win32 stuff).
    ${CMAKE_CURRENT_SOURCE_DIR}/webp-upstream-697749.patch
    # Add support for CBZ chapters.
    ${CMAKE_CURRENT_SOURCE_DIR}/mupdf_cbz_chapter_support.patch
    # Ensure an HTML document fonts are freed on close.
    ${CMAKE_CURRENT_SOURCE_DIR}/free-html-doc-fonts-on-close.patch
    # Relink on change(s) to external libraries.
    ${CMAKE_CURRENT_SOURCE_DIR}/relink_on_xlibs_change.patch
    # Fix symbols visiblity.
    ${CMAKE_CURRENT_SOURCE_DIR}/visibility.patch
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
    " ${CFLAGS} -fno-fast-math -fvisibility=hidden"
    # Disable a couple of things to save a small bit of space:
    # - builtin fonts
    # - color profile support
    # - CMYK plotter only 100 kB
    # - javascript (for form data validation) close to 800 kB
    " -DNOBUILTINFONT"
    " -DFZ_ENABLE_ICC=0"
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

string(APPEND LIB_LDFLAGS " ${CFLAGS} ${DYNLIB_LDFLAGS}")
if(DARWIN)
    string(APPEND LIB_LDFLAGS " -install_name @rpath/libmupdf${LIB_EXT}")
else()
    string(APPEND LIB_LDFLAGS " -Wl,-soname=libmupdf${LIB_EXT}")
endif()
if(ANDROID)
    string(APPEND LIB_LDFLAGS " -llog")
endif()

string(SUBSTRING ${LIB_EXT} 1 -1 LIB_SO)

string(APPEND XLIBS
    " ${STAGING_DIR}/lib/libaes.a"
    " ${STAGING_DIR}/lib/libfreetype${LIB_EXT}"
    " ${STAGING_DIR}/lib/libharfbuzz${LIB_EXT}"
    " ${STAGING_DIR}/lib/libjpeg${LIB_EXT}"
    " ${STAGING_DIR}/lib/libwebp${LIB_EXT}"
    " ${STAGING_DIR}/lib/libwebpdemux${LIB_EXT}"
    " ${STAGING_DIR}/lib/libz${LIB_EXT}"
)

set(MAKE_CMD
    ${KO_MAKE_RECURSIVE} -C ${SOURCE_DIR}
    # Compilation flags.
    AR=${AR}
    CC=${CC}
    CXX=${CXX}
    LDFLAGS=
    LIB_LDFLAGS=${LIB_LDFLAGS}
    XCFLAGS=${XCFLAGS}
    XLIBS=${XLIBS}
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
    # - lcms2
    USE_SYSTEM_LCMS2=yes
    SYS_LCMS2_LIBS=
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
    # NOTE: need "shared" somewhere in the path,
    # or the main makefile will raise an error.
    OUT=${BINARY_DIR}/shared
    SO=${LIB_SO}
    # Other.
    OS=${OS}
    build=${MUPDF_BUILD_TYPE}
    shared=yes
    verbose=no
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} libs)

list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} DESTDIR=${STAGING_DIR} prefix=/ install-libs)
list(APPEND INSTALL_CMD COMMAND chmod 755 ${STAGING_DIR}/lib/${LIB})

append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})

external_project(
    URL https://mupdf.com/downloads/archive/mupdf-1.24.2-source.tar.lz
    URL_MD5 d8f835e414202946d1c6c8192dd4315d
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
