cmake_minimum_required(VERSION 3.5.1)
project(libjpeg-turbo LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# CMake hell.
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=${INSTALL_DIR}/lib")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_INCLUDEDIR=${INSTALL_DIR}/include")

# And, finally, the actual libjpeg-turbo build options
list(APPEND CMAKE_ARGS "-DENABLE_STATIC=OFF")
list(APPEND CMAKE_ARGS "-DENABLE_SHARED=ON")
list(APPEND CMAKE_ARGS "-DWITH_JAVA=OFF")
list(APPEND CMAKE_ARGS "-DWITH_JPEG8=ON")

# make sure we disable ASM if we don't support SIMD
if(NOT DEFINED ENV{WANT_SIMD})
    list(APPEND CMAKE_ARGS "-DREQUIRE_SIMD=OFF")
    list(APPEND CMAKE_ARGS "-DWITH_SIMD=OFF")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    3.0.2
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS "${CMAKE_ARGS}"
    CMAKE_GENERATOR "Unix Makefiles"
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
