cmake_minimum_required(VERSION 3.15)
project(${TOOL} LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Choose your own adventure!
set(FBDEPTH_TARGET fbdepth)
if(LEGACY)
    set(FBINK_TARGET legacy)
    set(INPUT_TARGET inputlib KINDLE=1 LEGACY=1)
elseif(KINDLE)
    set(FBINK_TARGET kindle)
    set(INPUT_TARGET inputlib KINDLE=1)
elseif(CERVANTES)
    set(FBINK_TARGET cervantes)
    set(INPUT_TARGET inputlib CERVANTES=1)
elseif(KOBO)
    set(FBINK_TARGET strip KOBO=1)
    set(FBDEPTH_TARGET fbdepth KOBO=1)
    set(INPUT_TARGET inputlib KOBO=1)
elseif(REMARKABLE)
    set(FBINK_TARGET remarkable)
    set(FBDEPTH_TARGET fbdepth REMARKABLE=1)
    set(INPUT_TARGET inputlib REMARKABLE=1)
elseif(POCKETBOOK)
    set(FBINK_TARGET pocketbook)
    set(FBDEPTH_TARGET fbdepth POCKETBOOK=1)
    set(INPUT_TARGET inputlib POCKETBOOK=1)
else()
    set(FBINK_TARGET strip)
    # Would technically run just fine on plain Linux...
    #set(INPUT_TARGET inputlib LINUX=1)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)

if(TOOL STREQUAL "fbdepth")
    list(APPEND BUILD_CMD ${FBDEPTH_TARGET})
elseif(TOOL STREQUAL "fbink")
    list(APPEND BUILD_CMD
        # Minimal-ish, statically linked build,
        # we don't care about image support.
        FONTS=1
        MINIMAL=1
        OPENTYPE=1
        ${FBINK_TARGET}
    )
elseif(TOOL STREQUAL "libfbink_input")
    list(APPEND BUILD_CMD ${INPUT_TARGET})
else()
    message(FATAL_ERROR "TOOL not set or unsupported: '${TOOL}'")
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
