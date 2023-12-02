cmake_minimum_required(VERSION 3.5.1)
project(kobo-usbms LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(PREPARE_CMD sh -c "cd FBInk && git submodule init && git submodule update && cd -")
set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" kobo)

# We build in-tree...
set(INSTALL_CMD1 ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})
if(DEFINED ENV{DEBUG})
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/KoboUSBMS.tar.gz ${BINARY_DIR}/KoboUSBMS.tar.gz)
else()
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/KoboUSBMS.tar.gz ${BINARY_DIR}/KoboUSBMS.tar.gz)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    3daab316d3aff2b43ced9c0b18e6ecdeec953e4a
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND COMMAND ${PREPARE_CMD} COMMAND ${BUILD_CMD}
    # The buildsystem outputs binaries in a subdirectory...
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2}
)
