# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Drop duplicate cdefs, make sure turbo find its libtffi_wrap library, and pull in upstream fixes
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch)
# Don't recreate `libtffi_wrap.so` every time.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_phony_business.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/d7a8a247a4a2689b0f207162eb804141c87c4899.patch)
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
    "CC=${CC}"
    "MYCFLAGS=${MYCFLAGS}"
    "MYLDFLAGS=${MYLDFLAGS}"
    all
)

# Install shared library.
append_binary_install_command(INSTALL_CMD BYPRODUCTS libtffi_wrap${LIB_EXT} common/)

# Install LUA code.
append_install_commands(INSTALL_CMD BYPRODUCTS turbo.lua turbovisor.lua DESTINATION common/)
append_tree_install_commands(INSTALL_CMD BYPRODUCTS turbo common/turbo)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/kernelsauce/turbo
    tags/v2.1.3
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
