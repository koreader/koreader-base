project(evernote-sdk-lua)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
assert_var_defined(CC)
assert_var_defined(OUTPUT_DIR)
assert_var_defined(LDFLAGS)

set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} -j1 -C thrift CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" DYNLIB_CFLAGS=\"${DYNLIB_CFLAGS}\" OUTPUT_DIR=${OUTPUT_DIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/evernote-sdk-lua
    b6d8bed1fecb95b062f719dcad3cd720048c623a
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
