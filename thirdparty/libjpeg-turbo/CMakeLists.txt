cmake_minimum_required(VERSION 3.5.1)
project(libjpeg-turbo LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_cmake_rpath_shenanigans.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # We expect lib later on in Makefile.third, even on multilib systems...
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DCMAKE_INSTALL_LIBDIR=${INSTALL_DIR}/lib
    -DCMAKE_INSTALL_INCLUDEDIR=${INSTALL_DIR}/include
    # Project options.
    -DENABLE_STATIC=OFF
    -DENABLE_SHARED=ON
    -DWITH_JAVA=OFF
    -DWITH_JPEG8=ON
)
# Make sure we disable ASM if we don't support SIMD.
if(NOT DEFINED ENV{WANT_SIMD})
    list(APPEND CMAKE_ARGS
        -DREQUIRE_SIMD=OFF
        -DWITH_SIMD=OFF
    )
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    3.0.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
