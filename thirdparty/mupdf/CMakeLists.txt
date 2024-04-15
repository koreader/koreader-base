cmake_minimum_required(VERSION 3.15)
project(mupdf LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(AES_LIB)
assert_var_defined(FREETYPE_DIR)
assert_var_defined(FREETYPE_LIB)
assert_var_defined(HARFBUZZ_DIR)
assert_var_defined(HARFBUZZ_LIB)
assert_var_defined(JPEG_DIR)
assert_var_defined(JPEG_LIB)
assert_var_defined(LIBWEBPDEMUX_LIB)
assert_var_defined(LIBWEBP_DIR)
assert_var_defined(LIBWEBP_LIB)
assert_var_defined(MINIZIP_DIR)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # use external fonts
    ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch
    # add support for encryted zips
    ${CMAKE_CURRENT_SOURCE_DIR}/encrypted_zip.patch
    # use libjpeg as a shared library
    ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg_shared.patch
    # Disable potentially crashy ARM ASM (it's 7 years old, and hell to debug)
    # NOTE: There's also a few ARCH_UNALIGNED_OK checks, but we never did pass that define.
    #       (FWIW, we *could*, on anything not kindle-legacy).
    ${CMAKE_CURRENT_SOURCE_DIR}/no_arm_asm.patch
    # Honor CFLAGS
    ${CMAKE_CURRENT_SOURCE_DIR}/honor_cflags.patch
    # Patch for https://bugs.ghostscript.com/show_bug.cgi?id=698877; should be in upstream from 1.15
    # cf. https://github.com/koreader/koreader/issues/5182
    ${CMAKE_CURRENT_SOURCE_DIR}/upstream-698877.patch
    # Patch for tar/cbt support; should be in upstream from 1.17
    # cf. https://github.com/koreader/koreader-base/issues/1041
    ${CMAKE_CURRENT_SOURCE_DIR}/tar-fixes.patch
    # Backport a metric shitton of fixes
    # https://github.com/ArtifexSoftware/mupdf/commit/9920e40365821fbef6c3050695b3dcf0fa5f512e
    # https://github.com/ArtifexSoftware/mupdf/commit/3a263069d58416c251ef9f6a100a54be1e90dc0b
    # https://github.com/ArtifexSoftware/mupdf/commit/bc214b010556553720b8ab6eb6a41dff0057e5d1
    # https://github.com/ArtifexSoftware/mupdf/commit/75c457ddd28a629a9e1d6e1a8fa313ffef1457cb
    # https://github.com/ArtifexSoftware/mupdf/commit/6f8cb5606e426084160eaec82e9c11966e7fb5f4
    # ! https://github.com/ArtifexSoftware/mupdf/commit/984887ee8fb431e5c5d243c40dcb73d5149b033f (dep on https://github.com/ArtifexSoftware/mupdf/commit/43fa518a6981e2b392b1c11fa547d12ee300c62e)
    # ! https://github.com/ArtifexSoftware/mupdf/commit/94d6166428a679baa5a34fc5faa18a2aa26cee4a (dep on page_next/page_prev stuff)
    # https://github.com/ArtifexSoftware/mupdf/commit/98d7d24e67664600aeb346d2abfa29ff2f9653b1
    # https://github.com/ArtifexSoftware/mupdf/commit/351c99d8ce23bbf7099dbd52771a095f67e45a2c
    # https://github.com/ArtifexSoftware/mupdf/commit/6e0b9f10730db6dfd4636dd66dd6bf5bc32c9853
    # https://github.com/ArtifexSoftware/mupdf/commit/2be83b57e77938fddbb06bdffb11979ad89a9c7d
    # https://github.com/ArtifexSoftware/mupdf/commit/2df0c5fc8660ae72a8b0c438524ec6d103b86532
    # ! https://github.com/ArtifexSoftware/mupdf/commit/2eac2819b343ce5a20d8f730ceac1106d6412832 (dep)
    # ! https://github.com/ArtifexSoftware/mupdf/commit/90b3fce452e2e84a33d4c26095f5969ab1825be7 (dep)
    # https://github.com/ArtifexSoftware/mupdf/commit/03fd6221c10a5e66cac029b099ab29d7db7bb0e0
    # https://github.com/ArtifexSoftware/mupdf/commit/928dd4a53c295efec0ab4961f5c19a0d8b1161a5 (dep)
    # https://github.com/ArtifexSoftware/mupdf/commit/b09f19fe7f2771de93d84c96e26a25361dfe0e31
    # ! https://github.com/ArtifexSoftware/mupdf/commit/e4d1507169fa54961c0b77265da59118da813f2d (dep)
    # https://github.com/ArtifexSoftware/mupdf/commit/60b95f895b41ee8060f877358c88e41aed168ef4
    # https://github.com/ArtifexSoftware/mupdf/commit/f5b8388aa266bf2d563f21bdd41018a9160815fe
    # ~ https://github.com/ArtifexSoftware/mupdf/commit/a4d4552b8fd8f9ff794eadb825cc700109f0f052
    # https://github.com/ArtifexSoftware/mupdf/commit/0c6385c8818f871ff72cd109634b8ad1811b5d76
    # https://github.com/ArtifexSoftware/mupdf/commit/fbe2b9d428b5ab5d945ee8e6bd95e1b55db60d57
    # ~ https://github.com/ArtifexSoftware/mupdf/commit/e7f2b9954df26da99bbd5b6b578c3fe08eb30a4a (dep on https://github.com/ArtifexSoftware/mupdf/commit/821a0b2589e750318d2b2cd2a3232bc60d4bbe07)
    # ~ https://github.com/ArtifexSoftware/mupdf/commit/fa50848fb18407e2c517631e11b822e90cd213c4
    # ! https://github.com/ArtifexSoftware/mupdf/commit/72ea6e6ed9b73b06fa32677de4dc066e3c3e3018 (feature dep)
    # https://github.com/ArtifexSoftware/mupdf/commit/50c4c0176510ca068f13bbe04ad001ece9132523
    # https://github.com/ArtifexSoftware/mupdf/commit/0942e8d3ca7358c97182b3fee32a4bdfece3ea77
    # ! https://github.com/ArtifexSoftware/mupdf/commit/7d3e75c0eb2b5a8d2e57e11419838f5bf0777676 (feature dep)
    # https://github.com/ArtifexSoftware/mupdf/commit/5a6b7a1be9463700ca06e9148b6837eb1a491a02
    # https://github.com/ArtifexSoftware/mupdf/commit/296b8ee5c46ee386c484dcaf0b5a3e274cd8c2d6
    # https://github.com/ArtifexSoftware/mupdf/commit/8ecbf1b58dbf4de93e01a76b84ddb59f10e9f204
    # https://github.com/ArtifexSoftware/mupdf/commit/da5170bb4c9af9ddbfa8bdf91102ffdd6effee4a
    # ~ https://github.com/ArtifexSoftware/mupdf/commit/8719e07834d6a72b6b4131539e49ed1e8e2ff79e
    # https://github.com/ArtifexSoftware/mupdf/commit/d50cbc1f593fd86acf20a9d17104ba49e7665719
    # https://github.com/ArtifexSoftware/mupdf/commit/351492ddaafef2459cff80bd5e2e0cfb04ab4183
    # https://github.com/ArtifexSoftware/mupdf/commit/49159d918e3c655c5a763053fc8eb348eee8b23d
    # https://github.com/ArtifexSoftware/mupdf/commit/e5a718dfa2fb5f1487151f2e99c1a29761cf8c67
    # https://github.com/ArtifexSoftware/mupdf/commit/6b187fa3ffe48943545cebb9a3daee4b414d289a
    # https://github.com/ArtifexSoftware/mupdf/commit/bc4ec04e21027e226052e0a4c767cbf09994552e
    # https://github.com/ArtifexSoftware/mupdf/commit/a7c435ac1836cc9e46ec4329c1543892148a7a0e
    ${CMAKE_CURRENT_SOURCE_DIR}/mupdf-1.13.0-backports.patch
    # Support for WebP images (unmerged-yet proposed upstream patch cleaned up of win32 stuff)
    ${CMAKE_CURRENT_SOURCE_DIR}/webp-upstream-697749.patch
    # add support for cbz chapters
    ${CMAKE_CURRENT_SOURCE_DIR}/mupdf_cbz_chapter_support.patch
    # Backport https://github.com/ArtifexSoftware/mupdf/commit/50d80e509356784720ba8a7def5359f2673697ea (handle > 2GB Zip64)
    ${CMAKE_CURRENT_SOURCE_DIR}/read_large_zip.patch
    # Ensure an HTML document fonts are freed on close.
    ${CMAKE_CURRENT_SOURCE_DIR}/free-html-doc-fonts-on-close.patch
    # By default, mupdf compiles to a static library: we want a shared library.
    ${CMAKE_CURRENT_SOURCE_DIR}/shared-libmupdf.patch
    # Only install development files: headers & library.
    ${CMAKE_CURRENT_SOURCE_DIR}/minimal_install.patch
)

string(TOLOWER ${CMAKE_BUILD_TYPE} MUPDF_BUILD_TYPE)

# There's some headers to generate on the host's side first, before we run our actual build (where we enforce CROSSCOMPILE to avoid trying to regen those).
list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    CC=${HOSTCC}
    LIBS= # don't try to link with system libraries when building generator helpers…
    XCFLAGS=${HOSTCFLAGS}
    build=${MUPDF_BUILD_TYPE}
    verbose=no
    generate
)

if(WIN32)
    set(OS)
else()
    set(OS Other)
endif()

set(MUPDF_LIB libmupdf${LIB_EXT})

string(APPEND XCFLAGS
    " ${CFLAGS}"
    # Disable a couple of things to save a small bit of space:
    # - builtin fonts
    # - color profile support
    # - CMYK plotter only 100 kB
    # - javascript (for form data validation) close to 800 kB
    " -DNOBUILTINFONT"
    " -DNO_ICC"
    " -DFZ_PLOTTERS_CMYK=0"
    " -DFZ_ENABLE_JS=0"
)
if(ANDROID AND CHOST MATCHES "^armv7a-.*")
    # NOTE: to be removed when upgrading the minimal supported API level to 24.
    # (https://android.googlesource.com/platform/bionic/+/master/docs/32-bit-abi.md)
    string(APPEND XCFLAGS " -D_FILE_OFFSET_BITS=32")
endif()
string(APPEND XCFLAGS
    " -I${FREETYPE_DIR}/include/freetype2"
    " -I${HARFBUZZ_DIR}/include/harfbuzz"
    " -I${JPEG_DIR}/include"
    " -I${LIBWEBP_DIR}/include"
    " -I${MINIZIP_DIR}/include"
    " -I${ZLIB_DIR}/include"
)

string(APPEND LINK_OPTS " ${DYNLIB_LDFLAGS}")
if(DARWIN)
    string(APPEND LINK_OPTS
        " -install_name @rpath/libmupdf${LIB_EXT}"
        " -Wl,-force_load build/${MUPDF_BUILD_TYPE}/libmupdf.a"
    )
else()
    string(APPEND LINK_OPTS
        " -Wl,-soname=libmupdf${LIB_EXT}"
        " -Wl,--whole-archive build/${MUPDF_BUILD_TYPE}/libmupdf.a -Wl,--no-whole-archive"
    )
endif()
string(APPEND LINK_OPTS " build/${MUPDF_BUILD_TYPE}/libmupdfthird.a -lm")
if(ANDROID)
    string(APPEND LINK_OPTS " -llog")
endif()

string(APPEND LIBS
    " ${AES_LIB}"
    " ${FREETYPE_LIB}"
    " ${HARFBUZZ_LIB}"
    " ${JPEG_LIB}"
    " ${LIBWEBP_LIB}"
    " ${LIBWEBPDEMUX_LIB}"
    " ${ZLIB}"
)

set(MAKE_CMD
    env
    -u CFLAGS
    -u LDFLAGS
    ${KO_MAKE_RECURSIVE}
    # Compilation flags.
    AR=${AR}
    CC=${CC}
    CXX=${CXX}
    LDFLAGS=
    XCFLAGS=${XCFLAGS}
    # Disable some vendored libraries.
    CURL_DIR=nonexisting
    FREETYPE_DIR=nonexisting
    HARFBUZZ_DIR=nonexisting
    LCMS2_DIR=nonexisting
    LIBJPEG_DIR=nonexisting
    ZLIB_DIR=nonexisting
    # Other.
    CROSSCOMPILE=yes
    MUDRAW=
    MUTOOL=
    OS=${OS}
    build=${MUPDF_BUILD_TYPE}
    verbose=no
    # Final shared library.
    LIBS=${LIBS}
    LINK_OPTS=${LINK_OPTS}
    MUPDF_SHLIB=${MUPDF_LIB}
)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD} shared)

list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} install
    DESTDIR=${INSTALL_DIR}
    INSTALL_APPS=
    INSTALL_LIBS=${MUPDF_LIB}
    prefix=/
)

external_project(
    URL https://mupdf.com/downloads/archive/mupdf-1.13.0-source.tar.xz
    URL_MD5 0b567ae03d7a94321134dfcde95210cf
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
