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

set(PATCH_CMD "${ISED} 's|-lz||' configure.ac && ${ISED} 's|-lz||' configure")
set(PATCH_CMD sh -c "${PATCH_CMD}")

set(CFG_OPTS "--host=\"${HOST}\" PKG_CONFIG_PATH=\"${PKG_CONFIG_PATH}\" CXX=\"${CXX}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${LIBS}\"")
set(CFG_CMD sh -c "${SOURCE_DIR}/configure ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    git://github.com/koreader/sdcv.git
    fdf7da2cbf52f40724c0146b9bd31de376901708
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
    # skip install
    INSTALL_COMMAND ""
)
