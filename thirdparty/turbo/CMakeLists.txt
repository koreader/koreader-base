cmake_minimum_required(VERSION 3.5.1)
project(turbo LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Some of the LUA files are executables for no good reason.
list(APPEND PATCH_CMD COMMAND chmod a-x turbo/platform.lua turbo/socket_ffi.lua turbo/syscall.lua)

set(BUILD_CMD ${KO_MAKE_RECURSIVE} "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" all)

# Drop duplicate cdefs, make sure turbo find its libtffi_wrap library, and pull in upstream fixes
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/d7a8a247a4a2689b0f207162eb804141c87c4899.patch)
# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
list(APPEND PATCH_CMD COMMAND rm -f ${SOURCE_DIR}/turbo/ca-certificates.crt)
list(APPEND PATCH_CMD COMMAND ${ISED} "s|CC=|CC:=|" ${SOURCE_DIR}/Makefile)
if (APPLE AND ANDROID)
    # makefile of turbo hardcodes the shared library filename on darwin
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|libtffi_wrap.dylib|libtffi_wrap.so|" ${SOURCE_DIR}/Makefile)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/kernelsauce/turbo
    tags/v2.1.3
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
