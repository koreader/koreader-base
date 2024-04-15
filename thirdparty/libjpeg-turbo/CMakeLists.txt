cmake_minimum_required(VERSION 3.5.1)
project(libjpeg-turbo LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Make sure the daisy-chain once again picks up our toolchain file...
if(DEFINED ENV{CMAKE_TCF})
	list(APPEND CMAKE_ARGS "$ENV{CMAKE_TCF}")
endif()

# CMake hell.
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=${INSTALL_DIR}/lib")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_INCLUDEDIR=${INSTALL_DIR}/include")
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_RPATH=TRUE")

# c.f., https://android.googlesource.com/platform/ndk/+/master/build/cmake/android.toolchain.cmake
# and   https://github.com/taka-no-me/android-cmake
# In the meantime, I'll be sitting in the corner, crying hysterically.
if(DEFINED ENV{ANDROID})
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_NAME=Linux")
	# Magical value that inhibits all of CMake's own NDK handling code. (Or shit goes boom.)
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_VERSION=1")
endif()

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

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    3.0.2
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
