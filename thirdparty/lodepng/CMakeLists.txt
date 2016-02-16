PROJECT(lodepng)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(SONAME)
assert_var_defined(OUTPUT_PATH)

ep_get_source_dir(SOURCE_DIR)

set(BUILD_CMD_STR "${CC} -shared ${CFLAGS} -Wl,-E -Wl,-rpath,'$ORIGIN' -Wl,-soname=${SONAME} lodepng.c -o ${OUTPUT_PATH}/${SONAME}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lvandeve/lodepng.git
    4a02c6f8c55839c08521c538a36284ce9400c3a5
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy lodepng.cpp lodepng.c
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND ""
)
