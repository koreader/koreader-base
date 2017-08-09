PROJECT(sdcv)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(PKG_CONFIG_PATH)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBS)
assert_var_defined(HOST)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(DESTDIR "${BINARY_DIR}")

set(CFG_CMD cmake -DENABLE_NLS:BOOL=False -DWITH_READLINE:BOOL=False "${SOURCE_DIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    git://github.com/Dushistov/sdcv.git
    8f16ceae593461b22c85f5f3e060e5a07b043549
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS}
    INSTALL_COMMAND DESTDIR=${DESTDIR} $(MAKE) -j${PARALLEL_JOBS} install
)
