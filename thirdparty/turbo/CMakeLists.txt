project(turbo)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)

set(BUILD_CMD sh -c "${KO_MAKE_RECURSIVE} CC=\"${CC}\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" all")

set(PATCH_CMD "${ISED} 's|CC=|CC:=|' ${SOURCE_DIR}/Makefile")
if (APPLE AND DEFINED ENV{ANDROID})
    # makefile of turbo hardcodes the shared library filename on darwin
    set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|libtffi_wrap.dylib|libtffi_wrap.so|' ${SOURCE_DIR}/Makefile")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/kernelsauce/turbo
    1023f02f787bdd15c752a6d8d46fbe7addc0b6bc
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    # patch turbo to specify path of libssl and libcrypto and to remove -Werror flag from turbo/deps/http_parser/Makefile
    PATCH_COMMAND COMMAND sh -c "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/turbo.patch"
    CONFIGURE_COMMAND COMMAND sh -c ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
