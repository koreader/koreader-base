project(fbink)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Choose your own adventure!
if($ENV{LEGACY})
    set(FBINK_TARGET "legacy")
elseif($ENV{KINDLE})
    set(FBINK_TARGET "kindle")
elseif($ENV{CERVANTES})
    set(FBINK_TARGET "cervantes")
elseif($ENV{KOBO})
    set(FBINK_TARGET "strip")
    set(UTILS_TARGET "utils")
else()
    set(FBINK_TARGET "strip")
endif()

# Minimal, statically linked build, we don't care about extra fonts or image support
set(BUILD_CMD1 sh -c "${KO_MAKE_RECURSIVE} MINIMAL=1 OPENTYPE=1 CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ${FBINK_TARGET}")
if($ENV{KOBO})
    set(BUILD_CMD2 sh -c "${KO_MAKE_RECURSIVE} CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ${UTILS_TARGET}")
else()
    set(BUILD_CMD2 sh -c "true")
    set(INSTALL_CMD3 sh -c "true")
endif()
# We build in-tree...
set(INSTALL_CMD1 ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})
if($ENV{DEBUG})
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/fbink ${BINARY_DIR}/fbink)
    if($ENV{KOBO})
        set(INSTALL_CMD3 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/fbdepth ${BINARY_DIR}/fbdepth)
    endif()
else()
    set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/fbink ${BINARY_DIR}/fbink)
    if($ENV{KOBO})
        set(INSTALL_CMD3 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/fbdepth ${BINARY_DIR}/fbdepth)
    endif()
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    tags/v1.20.2
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND COMMAND ${BUILD_CMD1} COMMAND ${BUILD_CMD2}
    # The buildsystem outputs binaries in a subdirectory...
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2} COMMAND ${INSTALL_CMD3}
)
