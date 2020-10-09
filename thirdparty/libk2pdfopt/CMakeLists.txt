project(libk2pdfopt)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_asm")
include("koreader_thirdparty_git")

enable_language(C CXX ASM)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

if(NOT DEFINED ENV{DARWIN})
    set(LDFLAGS "${LDFLAGS} -Wl,-soname,${LIBNAME}")
endif()

set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LIBNAME=\"${LIBNAME}\" LDFLAGS=\"${LDFLAGS}\"")

set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/android.patch")
set(PATCH_CMD2 sh -c "${ISED} '/#define WILLUS_HAVE_FILE64/d' ${SOURCE_DIR}/k2pdfopt/willuslib/willus.h")


ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/ezdiy/libk2pdfopt.git
    master
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${PATCH_CMD2}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
