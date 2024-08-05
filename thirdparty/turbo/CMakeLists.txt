# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_FILES
    # Drop duplicate cdefs, make sure turbo find its
    # libtffi_wrap library, and pull in upstream fixes.
    turbo.patch
    d7a8a247a4a2689b0f207162eb804141c87c4899.patch
)

# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
list(APPEND PATCH_CMD COMMAND rm turbo/ca-certificates.crt)
if(CMAKE_HOST_APPLE AND ANDROID)
    # Makefile of turbo hardcodes the shared library filename on macOS.
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|libtffi_wrap.dylib|libtffi_wrap.so|" Makefile)
endif()
# Some of the LUA files are executables for no good reason.
list(APPEND PATCH_CMD COMMAND chmod a-x turbo/platform.lua turbo/socket_ffi.lua turbo/syscall.lua)

set(MYCFLAGS "${CFLAGS} -I${STAGING_DIR}/include")
string(REPLACE "${CFLAGS}" "" MYLDFLAGS "${DYNLIB_LDFLAGS} ${STAGING_DIR}/lib/libcrypto${LIB_EXT} ${STAGING_DIR}/lib/libssl${LIB_EXT}")

list(APPEND BUILD_CMD COMMAND
    make
    CC=${CC}
    MYCFLAGS=${MYCFLAGS}
    MYLDFLAGS=${MYLDFLAGS}
    all
)

append_binary_install_command(INSTALL_CMD libtffi_wrap${LIB_EXT} DESTINATION common)
append_install_commands(INSTALL_CMD turbo.lua turbovisor.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD turbo common/turbo)

external_project(
    DOWNLOAD GIT v2.1.3
    https://github.com/kernelsauce/turbo
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
