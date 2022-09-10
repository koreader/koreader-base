project(lunasvg)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${BINARY_DIR}")

# c.f., https://android.googlesource.com/platform/ndk/+/master/build/cmake/android.toolchain.cmake
# and   https://github.com/taka-no-me/android-cmake
# In the meantime, I'll be sitting in the corner, crying hysterically.
if(DEFINED ENV{ANDROID})
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_NAME=Linux")
	# Magical value that inhibits all of CMake's own NDK handling code. (Or shit goes boom.)
	list(APPEND CMAKE_ARGS "-DCMAKE_SYSTEM_VERSION=1")
endif()

list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=ON")

set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/extended.patch")
set(PATCH_CMD2 sh -c "cp -rp -v ${CMAKE_CURRENT_SOURCE_DIR}/xtended ${SOURCE_DIR}/")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/sammycage/lunasvg.git
    637121f89218544ec2f154ae6949ab0ea9b47898
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    lunasvg
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2}
    CMAKE_ARGS "${CMAKE_ARGS}"
    CMAKE_GENERATOR "Unix Makefiles"
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
