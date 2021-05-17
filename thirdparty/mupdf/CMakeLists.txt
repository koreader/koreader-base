project(mupdf)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(XCFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(OS)
assert_var_defined(MUPDF_LIB)

if($ENV{KODEBUG})
    set(MUPDF_BUILD_TYPE "debug")
else()
    set(MUPDF_BUILD_TYPE "release")
endif()

# TODO: Is this necessary?
if($ENV{ANDROID})
    set(LDFLAGS "${LDFLAGS} -llog")
endif()

# Disable a couple of things to save a small bit of space
# CMYK plotter only 100 kB
# javascript (for form data validation) close to 800 kB
set(XCFLAGS "${XCFLAGS} -DFZ_PLOTTERS_CMYK=0 -DFZ_ENABLE_JS=0")

# Disable builtin font lookups, we have to provide those via fz_install_load_system_font_funcs()
set(XCFLAGS "${XCFLAGS} -DTOFU_CJK -DTOFU -DTOFU_BASE14")

# Disable ARM assembly until https://bugs.ghostscript.com/show_bug.cgi?id=698879 gets resolved
set(XCFLAGS "${XCFLAGS} -DFZ_DISABLE_ARM_ASM")

set(MAKE_CMD "${KO_MAKE_RECURSIVE} XCFLAGS=\"${XCFLAGS}\" XLIBS=\"${LDFLAGS}\"")

# Use "system" libs, ones *we* have built as shared.
# However gumbo-parser and jbig2dec are left static and private to libmupdf
set(MAKE_CMD "${MAKE_CMD} USE_SYSTEM_LIBS=yes USE_SYSTEM_GUMBO=no USE_SYSTEM_JBIG2DEC=no SYS_FREETYPE_LIBS=\"-lfreetype\"")
set(MAKE_CMD "${MAKE_CMD} build=${MUPDF_BUILD_TYPE} CC=\"${CC}\" OS=${OS} shared=yes builtinfonts=no libs")

# By nuking pkg-config like so, we make mupdf use default -lname for each system lib, searching only via LDFLAGS.
set(BUILD_CMD sh -c "PKG_CONFIG_PATH=/var/nothanks ${MAKE_CMD} -j${PARALLEL_JOBS}")


set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/mupdf-k2pdfopt.patch")

set(SHARED_BUILD_CMD "${SHARED_BUILD_STR}")
# use external fonts
set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/external_fonts.patch")
# add support for encryted zips
set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/encrypted_zip.patch")
# use libjpeg as a shared library
set(PATCH_CMD3 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg_shared.patch")
# Disable potentially crashy ARM ASM (it's 7 years old, and hell to debug)
# NOTE: There's also a few ARCH_UNALIGNED_OK checks, but we never did pass that define.
#       (FWIW, we *could*, on anything not kindle-legacy).
set(PATCH_CMD4 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_arm_asm.patch")
# Honor CFLAGS
set(PATCH_CMD5 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/honor_cflags.patch")
# Patch for https://bugs.ghostscript.com/show_bug.cgi?id=698877; should be in upstream from 1.15
# cf. https://github.com/koreader/koreader/issues/5182
set(PATCH_CMD6 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/upstream-698877.patch")
# Patch for tar/cbt support; should be in upstream from 1.17
# cf. https://github.com/koreader/koreader-base/issues/1041
set(PATCH_CMD7 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-fixes.patch")
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
set(PATCH_CMD8 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/mupdf-1.13.0-backports.patch")

# TODO: ignore *some* of the shared git submodules that are built outside of mupdf by us?
ep_get_source_dir(SOURCE_DIR)
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/ezdiy/mupdf
    koreader
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3} COMMAND ${PATCH_CMD4} COMMAND ${PATCH_CMD5} COMMAND ${PATCH_CMD6} COMMAND ${PATCH_CMD7} COMMAND ${PATCH_CMD8}
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
