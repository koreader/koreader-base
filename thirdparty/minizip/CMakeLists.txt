cmake_minimum_required(VERSION 3.5.1)
project(minizip LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(AR)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(RANLIB)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# NOTE: 53a657318af1fccc4bac7ed230729302b2391d1d is the tip of the 1.2 branch. The fcrypt API we need is gone in master.
# FIXME: Even then, something in said branch seems to upset MuPDF with our custom patch as-is, so keep using the old code...
# list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/minizip-libaes-makefile.patch)

list(APPEND PATCH_CMD COMMAND ${ISED} "s|\\.\\./libaes.a|libaes.a|" aes/Makefile)

# Fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12.
string(APPEND CFLAGS " -Wno-error=implicit-function-declaration")
string(APPEND CFLAGS " -DHAVE_AES")
list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    AR=${AR}
    CC=${CC}
    CFLAGS=${CFLAGS}
    LDFLAGS=${LDFLAGS}
    RANLIB=${RANLIB}
    -C aes
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/nmoinvaz/minizip
    0b46a2b4ca317b80bc53594688883f7188ac4d08
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
