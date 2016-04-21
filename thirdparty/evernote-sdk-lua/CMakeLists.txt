PROJECT(evernote-sdk-lua)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
assert_var_defined(CC)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LDFLAGS)

set(BUILD_CMD sh -c "$(MAKE) -C thrift CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" OUTPUT_DIR=${OUTPUT_DIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/evernote-sdk-lua
    cfe65376a5ee04ca8f1f10993f5ff9cceaad2857
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
