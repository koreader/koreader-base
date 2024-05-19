cmake_minimum_required(VERSION 3.5.1)
project(fbink LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Choose your own adventure!
if(DEFINED ENV{LEGACY})
    set(FBINK_TARGET legacy)
    set(INPUT_TARGET inputlib KINDLE=1 LEGACY=1)
elseif(DEFINED ENV{KINDLE})
    set(FBINK_TARGET kindle)
    set(INPUT_TARGET inputlib KINDLE=1)
elseif(DEFINED ENV{CERVANTES})
    set(FBINK_TARGET cervantes)
    set(INPUT_TARGET inputlib CERVANTES=1)
elseif(DEFINED ENV{KOBO})
    set(FBINK_TARGET strip KOBO=1)
    set(FBDEPTH_TARGET fbdepth KOBO=1)
    set(INPUT_TARGET inputlib KOBO=1)
elseif(DEFINED ENV{REMARKABLE})
    set(FBINK_TARGET remarkable)
    set(FBDEPTH_TARGET fbdepth REMARKABLE=1)
    set(INPUT_TARGET inputlib REMARKABLE=1)
elseif(DEFINED ENV{POCKETBOOK})
    set(FBINK_TARGET pocketbook)
    set(FBDEPTH_TARGET fbdepth POCKETBOOK=1)
    set(INPUT_TARGET inputlib POCKETBOOK=1)
else()
    set(FBINK_TARGET strip)
    # Would technically run just fine on plain Linux...
    #set(INPUT_TARGET inputlib LINUX=1)
endif()

# The input lib can be built standalone, so start with that
if(INPUT_TARGET)
    list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} clean)
    list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" ${INPUT_TARGET})

    # That does mean we need to stash it somewhere a clean won't scrap it, though...
    if(DEFINED ENV{DEBUG})
        list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/libfbink_input.so.1.0.0 ${INSTALL_DIR}/libfbink_input.so.1)
    else()
        list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/libfbink_input.so.1.0.0 ${INSTALL_DIR}/libfbink_input.so.1)
    endif()
endif()

# FBDepth can afford to link to a very minimal library, so we need to start from scratch...
if(FBDEPTH_TARGET)
    list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} clean)
    list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} "CROSS_TC=${CHOST}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" ${FBDEPTH_TARGET})

    # That does mean we need to stash the binary somewhere a clean won't scrap it, though...
    if(DEFINED ENV{DEBUG})
        list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/fbdepth ${INSTALL_DIR}/fbdepth)
    else()
        list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/fbdepth ${INSTALL_DIR}/fbdepth)
    endif()
endif()

# Minimal-ish, statically linked build, we don't care about image support
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} clean)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} MINIMAL=1 FONTS=1 OPENTYPE=1 "CROSS_TC=${CHOST}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" ${FBINK_TARGET})

# We build in-tree...
if(DEFINED ENV{DEBUG})
    list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Debug/fbink ${INSTALL_DIR}/fbink)
else()
    list(APPEND BUILD_CMD COMMAND ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/Release/fbink ${INSTALL_DIR}/fbink)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    012dd73784969a05095400137b358ef43522aed5
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
)
