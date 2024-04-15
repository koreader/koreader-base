cmake_minimum_required(VERSION 3.5.1)
project(lodepng LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(SONAME)
assert_var_defined(OUTPUT_PATH)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

if (APPLE)
    set(BUILD_CMD sh -c "${CC} -shared ${CFLAGS} ${LDFLAGS} lodepng.c -o ${OUTPUT_PATH}/${SONAME}")
else()
    set(BUILD_CMD sh -c "${CC} -shared ${CFLAGS} ${LDFLAGS} -Wl,-E -Wl,-soname=${SONAME} lodepng.c -o ${OUTPUT_PATH}/${SONAME}")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lvandeve/lodepng.git
    d398e0f10d152a5d17fa30463474dc9f56523f9c
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${CMAKE_COMMAND} -E copy lodepng.cpp lodepng.c
    BUILD_COMMAND ${BUILD_CMD}
)
