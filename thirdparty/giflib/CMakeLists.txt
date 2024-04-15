cmake_minimum_required(VERSION 3.5.1)
project(giflib LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/build.cmake CMakeLists.txt)

if(ANDROID)
    # Use `limits.h` instead of `stdint.h`.
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|stdint.h|limits.h|g" lib/openbsd-reallocarray.c)
endif()

list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

external_project(
    URL https://gitlab.com/koreader/giflib/-/archive/5.1.4/giflib-5.1.4.tar.gz
    URL_MD5 f0011445f6c261aa78df502e6825896a
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)
