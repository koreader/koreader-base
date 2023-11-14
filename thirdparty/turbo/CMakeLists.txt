project(turbo LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Drop duplicate cdefs, make sure turbo find its libtffi_wrap library, and pull in upstream fixes
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch)
# Don't recreate `libtffi_wrap.so` every time.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_phony_business.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/d7a8a247a4a2689b0f207162eb804141c87c4899.patch)
# Remove the 7 years-old copy of a CA bundle that turbo doesn't actually use.
list(APPEND PATCH_CMD COMMAND rm turbo/ca-certificates.crt)
list(APPEND PATCH_CMD COMMAND ${ISED} "s|CC=|CC:=|" Makefile)
if (APPLE AND ANDROID)
    # makefile of turbo hardcodes the shared library filename on darwin
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|libtffi_wrap.dylib|libtffi_wrap.so|" Makefile)
endif()

string(APPEND CFLAGS " -I${STAGING_DIR}/openssl/include")
string(APPEND LDFLAGS " -L${STAGING_DIR}/openssl/shared")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} "CC=${CC}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" all)

list(APPEND INSTALL_CMD COMMAND cd "${SOURCE_DIR}")

# Install shared library.
append_install_command(INSTALL_CMD "libtffi_wrap${LIB_EXT}" DESTINATION common/)

# Install LUA code.
append_install_command(INSTALL_CMD turbo.lua turbovisor.lua DESTINATION common/)
append_tree_install_command(INSTALL_CMD turbo common/turbo)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/kernelsauce/turbo
    tags/v2.1.3
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
