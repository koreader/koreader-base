cmake_minimum_required(VERSION 3.5.1)
project(turbo)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" all)

# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
set(PATCH_CMD sh -c "rm -f ${SOURCE_DIR}/turbo/ca-certificates.crt && ${ISED} 's|CC=|CC:=|' ${SOURCE_DIR}/Makefile")
if (APPLE AND DEFINED ENV{ANDROID})
    # makefile of turbo hardcodes the shared library filename on darwin
    set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|libtffi_wrap.dylib|libtffi_wrap.so|' ${SOURCE_DIR}/Makefile")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/kernelsauce/turbo
    tags/v2.1.3
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    # Drop duplicate cdefs, make sure turbo find its libtffi_wrap library, and pull in upstream fixes
    PATCH_COMMAND COMMAND "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch" COMMAND "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/d7a8a247a4a2689b0f207162eb804141c87c4899.patch"
    CONFIGURE_COMMAND COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
