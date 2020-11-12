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
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
