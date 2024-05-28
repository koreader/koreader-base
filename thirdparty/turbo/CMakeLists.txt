cmake_minimum_required(VERSION 3.15)
project(turbo LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Some of the LUA files are executables for no good reason.
list(APPEND PATCH_CMD COMMAND chmod a-x turbo/platform.lua turbo/socket_ffi.lua turbo/syscall.lua)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # Drop duplicate cdefs, make sure turbo find its
    # libtffi_wrap library, and pull in upstream fixes.
    ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/d7a8a247a4a2689b0f207162eb804141c87c4899.patch
)
# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
list(APPEND PATCH_CMD COMMAND rm turbo/ca-certificates.crt)
if (APPLE AND ANDROID)
    # Makefile of turbo hardcodes the shared library filename on macOS.
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|libtffi_wrap.dylib|libtffi_wrap.so|" Makefile)
endif()

set(MYCFLAGS "${CFLAGS} -I${STAGING_DIR}/include")
string(REPLACE "${CFLAGS}" "" MYLDFLAGS "${DYNLIB_LDFLAGS} ${STAGING_DIR}/lib/libcrypto${LIB_EXT} ${STAGING_DIR}/lib/libssl${LIB_EXT}")

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    CC=${CC}
    MYCFLAGS=${MYCFLAGS}
    MYLDFLAGS=${MYLDFLAGS}
    all
)

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
