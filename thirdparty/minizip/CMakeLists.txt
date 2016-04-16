PROJECT(minizip)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_asm")
include("koreader_thirdparty_git")

enable_language(C ASM)

assert_var_defined(CC)
assert_var_defined(AR)
assert_var_defined(LDFLAGS)
assert_var_defined(RANLIB)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD_STR "sed -ie 's|^CC=|#CC=|g' aes/Makefile && sed -ie 's|^CFLAGS=|#CFLAGS=|g' aes/Makefile")
set(BUILD_CMD_STR "$(MAKE) -j${PARALLEL_JOBS} -C aes CC=\"${CC}\" LDFLAGS=\"${LDFLAGS}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\"")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/nmoinvaz/minizip
    0b46a2b4ca317b80bc53594688883f7188ac4d08
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND sh -c ${PATCH_CMD_STR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND ""
)
