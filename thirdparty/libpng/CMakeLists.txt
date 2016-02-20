PROJECT(libpng)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CPPFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CPPFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ")
set(CFG_OPTS "-q --prefix=${BINARY_DIR} --disable-static --enable-shared --host=\"${CHOST}\"")
set(CFG_CMD_STR "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/glennrp/libpng.git
    v1.6.21
    ${SOURCE_DIR}
)

set(LIBPNG_VER "1.6.19")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND sh autogen.sh
    CONFIGURE_COMMAND sh -c ${CFG_CMD_STR}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent
    INSTALL_COMMAND $(MAKE) -j${PARALLEL_JOBS} --silent install
)
