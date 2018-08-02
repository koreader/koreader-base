PROJECT(libjpeg-turbo)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# CMake hell.
set(CFG_OPTS "-DCMAKE_INSTALL_PREFIX=${BINARY_DIR}")

# Actual libjpeg-turbo build options
set(CFG_OPTS "${CFG_OPTS} -DENABLE_STATIC=OFF -DENABLE_SHARED=ON -DWITH_JAVA=OFF -DWITH_JPEG8=ON")
if(${WITHOUT_SIMD})
    set(CFG_OPTS "${CFG_OPTS} -DWITH_SIMD=OFF")
endif(${WITHOUT_SIMD})
set(CFG_CMD sh -c "${CMAKE_COMMAND} ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    2.0.0
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    libjpeg-turbo
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS}
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} install
)
