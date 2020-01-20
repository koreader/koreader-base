project(lodepng)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(SONAME)
assert_var_defined(OUTPUT_PATH)

ep_get_source_dir(SOURCE_DIR)

if (APPLE)
    set(BUILD_CMD sh -c "${CC} -shared ${CFLAGS} ${LDFLAGS} lodepng.c -o ${OUTPUT_PATH}/${SONAME}")
else()
    set(BUILD_CMD sh -c "${CC} -shared ${CFLAGS} ${LDFLAGS} -Wl,-E -Wl,-soname=${SONAME} lodepng.c -o ${OUTPUT_PATH}/${SONAME}")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lvandeve/lodepng.git
    5a0dba103893e6b8084be13945a826663917d00a
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy lodepng.cpp lodepng.c
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
