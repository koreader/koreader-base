list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/build.cmake CMakeLists.txt)

if(ANDROID)
    # Use `limits.h` instead of `stdint.h`.
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|stdint.h|limits.h|g" openbsd-reallocarray.c)
endif()

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC gif VERSION 7)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    "${SOURCE_DIR}/gif_lib.h"
)

thirdparty_project(
    URL https://sourceforge.net/projects/giflib/files/giflib-5.2.2.tar.gz
    URL_MD5 913dd251492134e235ee3c9a91987a4d
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
