# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# NOTE: 53a657318af1fccc4bac7ed230729302b2391d1d is the tip of the 1.2 branch. The fcrypt API we need is gone in master.
# FIXME: Even then, something in said branch seems to upset MuPDF with our custom patch as-is, so keep using the old code...
# list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/minizip-libaes-makefile.patch)

list(APPEND PATCH_CMD COMMAND ${ISED} "s|\\.\\./libaes.a|libaes.a|" aes/Makefile)

# Fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12.
string(APPEND CFLAGS " -Wno-error=implicit-function-declaration")
string(APPEND CFLAGS " -DHAVE_AES")
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C aes)
append_autotools_vars(BUILD_CMD)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD BYPRODUCTS "${SOURCE_DIR}/aes/libaes.a" aes)

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR aes
    FROM "${SOURCE_DIR}/aes"
    aes.h aes_via_ace.h aesopt.h aestab.h
    brg_endian.h brg_types.h entropy.h fileenc.h
    hmac.h prng.h pwd2key.h sha1.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/nmoinvaz/minizip
    0b46a2b4ca317b80bc53594688883f7188ac4d08
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
