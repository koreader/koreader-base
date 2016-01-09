PROJECT(lua-serialize)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(LDFLAGS)
assert_var_defined(OUTPUT_DIR)

ep_get_source_dir(SOURCE_DIR)

set(BUILD_CMD_STR "$(MAKE) -j${PARALLEL_JOBS} CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" OUTPUT_DIR=${OUTPUT_DIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/chrox/lua-serialize
    aabebaf6560ff54cb34eb558c7f85f78a948f80b
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND ""
)
