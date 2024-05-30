cmake_minimum_required(VERSION 3.15)
project(koreader-base LANGUAGES C CXX)

include(${CMAKE_KOVARS})
include(koreader_thirdparty_common)
include(koreader_thirdparty_git)
include(koreader_targets)

add_custom_target(download-all)
add_custom_target(download)
add_custom_target(patch)

# HELPERS. {{{

function(declare_project DIR)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "SOURCE_DIR" "DEPENDS" ${ARGN})
    get_filename_component(NAME ${DIR} NAME)
    if(DIR MATCHES "^thirdparty/")
        set(BASE_DIR ${OUTPUT_DIR}/thirdparty/${NAME})
    else()
        set(BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${NAME})
    endif()
    get_filename_component(DIR ${DIR} ABSOLUTE BASE_DIR ${CMAKE_SOURCE_DIR}/..)
    if(NOT _SOURCE_DIR)
        set(_SOURCE_DIR ${BASE_DIR}/source)
    endif()
    get_filename_component(_SOURCE_DIR ${_SOURCE_DIR} ABSOLUTE BASE_DIR ${CMAKE_SOURCE_DIR}/..)
    set(${NAME}_CMAKE_SOURCE_DIR ${DIR} PARENT_SCOPE)
    set(${NAME}_CMAKE_BINARY_DIR ${BASE_DIR} PARENT_SCOPE)
    set(${NAME}_DOWNLOAD_DIR ${DIR}/build/downloads PARENT_SCOPE)
    set(${NAME}_SOURCE_DIR ${_SOURCE_DIR} PARENT_SCOPE)
    set(${NAME}_BINARY_DIR ${BASE_DIR}/build PARENT_SCOPE)
    set(${NAME}_DEPENDS ${_DEPENDS} PARENT_SCOPE)
    if(_EXCLUDE_FROM_ALL)
        set(${NAME}_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL PARENT_SCOPE)
    endif()
    # message(WARNING "
    # ${NAME}:
    # cmake source dir: ${DIR}
    # cmake binary dir: ${BASE_DIR}
    # base dir: ${BASE_DIR}
    # source dir: ${_SOURCE_DIR}
    # dependencies: ${_DEPENDS}
    # exclude from all? ${_EXCLUDE_FROM_ALL}
    # ")
    set(PROJECTS ${PROJECTS} ${NAME} PARENT_SCOPE)
endfunction()

macro(setup_project NAME)
    if(NOT ${NAME} IN_LIST PROJECTS)
        message(FATAL_ERROR "trying to setup undeclared project: ${NAME}")
    endif()
    if(NOT ${NAME}_SETUP)
        # Project is not already setup.
        set(${NAME}_SETUP TRUE)
        # Dependencies must be setup first.
        foreach(PRJ IN LISTS ${NAME}_DEPENDS)
            setup_project(${PRJ})
            list(APPEND ${NAME}_BUILD_DEPENDS ${${PRJ}_BYPRODUCTS})
        endforeach()
        # Setup project variables.
        set(PROJECT_NAME ${NAME})
        set(DOWNLOAD_DIR ${${NAME}_DOWNLOAD_DIR})
        set(SOURCE_DIR ${${NAME}_SOURCE_DIR})
        set(BINARY_DIR ${${NAME}_BINARY_DIR})
        # Add project directory.
        add_subdirectory(${${NAME}_CMAKE_SOURCE_DIR} ${${NAME}_CMAKE_BINARY_DIR} ${${NAME}_EXCLUDE_FROM_ALL})
        get_property(${NAME}_BYPRODUCTS GLOBAL PROPERTY ${NAME}_BYPRODUCTS)
        # Add dependency to global targets.
        if(${NAME}_EXCLUDE_FROM_ALL)
            add_dependencies(download-all ${NAME}-download)
        else()
            add_dependencies(download ${NAME}-download)
            add_dependencies(patch ${NAME}-patch)
        endif()
        # Dependencies.
        if(${NAME}_DEPENDS)
            add_dependencies(${NAME}-configure ${${NAME}_DEPENDS})
            if(NOT POLICY CMP0114)
                # Need to cover all the bases…
                add_dependencies(${NAME}-build ${${NAME}_DEPENDS})
                add_dependencies(${NAME}-install ${${NAME}_DEPENDS})
                add_dependencies(${NAME} ${${NAME}_DEPENDS})
            endif()
        endif()
    endif()
endmacro()

# }}}.

# THIRDPARTY. {{{

# crengine
declare_project(
    cmake/crengine
    DEPENDS
    freetype2
    fribidi
    harfbuzz
    libjpeg-turbo
    libpng
    libunibreak
    libwebp
    lunasvg
    utf8proc
    zlib
    zstd
    SOURCE_DIR thirdparty/kpvcrlib
)
set(crengine_CMAKE_BINARY_DIR ${OUTPUT_DIR}/thirdparty/crengine)
set(crengine_BINARY_DIR ${crengine_CMAKE_BINARY_DIR}/build)

# cpu_features
declare_project(thirdparty/cpu_features EXCLUDE_FROM_ALL)

# curl
declare_project(thirdparty/curl DEPENDS openssl zlib EXCLUDE_FROM_ALL)

# czmq
if(NOT WIN32)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/czmq DEPENDS libzmq ${EXCLUDE_FROM_ALL})

# djvulibre
declare_project(thirdparty/djvulibre DEPENDS libjpeg-turbo EXCLUDE_FROM_ALL)

# dropbear
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/dropbear DEPENDS zlib ${EXCLUDE_FROM_ALL})

# fbdepth / fbink / libfbink_input
if(KOBO OR POCKETBOOK OR REMARKABLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/fbdepth ${EXCLUDE_FROM_ALL})
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/fbink ${EXCLUDE_FROM_ALL})
set(fbdepth_CMAKE_SOURCE_DIR ${fbink_CMAKE_SOURCE_DIR})
declare_project(thirdparty/libfbink_input ${EXCLUDE_FROM_ALL})
set(libfbink_input_CMAKE_SOURCE_DIR ${fbink_CMAKE_SOURCE_DIR})

# freetype
declare_project(thirdparty/freetype2)

# fribidi
declare_project(thirdparty/fribidi EXCLUDE_FROM_ALL)

# gettext
if(ANDROID OR DARWIN)
    set(DEPENDS libiconv)
else()
    set(DEPENDS)
endif()
declare_project(thirdparty/gettext DEPENDS ${DEPENDS} EXCLUDE_FROM_ALL)

# giflib
declare_project(thirdparty/giflib)

# glib
set(DEPENDS)
if(ANDROID OR DARWIN)
    list(APPEND DEPENDS gettext libiconv)
endif()
declare_project(thirdparty/glib DEPENDS ${DEPENDS} EXCLUDE_FROM_ALL)

# harfbuzz
declare_project(thirdparty/harfbuzz DEPENDS freetype2)

# kobo-usbms
if(KOBO)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/kobo-usbms ${EXCLUDE_FROM_ALL})

# leptonica
declare_project(thirdparty/leptonica DEPENDS libpng)

# libiconv
declare_project(thirdparty/libiconv EXCLUDE_FROM_ALL)

# libjpeg-turbo
declare_project(thirdparty/libjpeg-turbo)

# libk2pdfopt
declare_project(thirdparty/libk2pdfopt DEPENDS leptonica libpng tesseract zlib)

# libpng
declare_project(thirdparty/libpng DEPENDS zlib EXCLUDE_FROM_ALL)

# libunibreak
declare_project(thirdparty/libunibreak EXCLUDE_FROM_ALL)

# libwebp
declare_project(thirdparty/libwebp)

# libzmq
if(NOT WIN32)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/libzmq ${EXCLUDE_FROM_ALL})

# lj-wpaclient
if(USE_LJ_WPACLIENT)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/lj-wpaclient ${EXCLUDE_FROM_ALL})

# lodepng
declare_project(thirdparty/lodepng)

# lpeg
declare_project(thirdparty/lpeg DEPENDS luajit)

# lua-htmlparser
declare_project(thirdparty/lua-htmlparser)

# lua-ljsqlite3
add_subdirectory(${THIRDPARTY_DIR}/lua-ljsqlite3 ${OUTPUT_DIR}/thirdparty/lua-ljsqlite3)

# lua-rapidjson
declare_project(thirdparty/lua-rapidjson DEPENDS luajit)

# lua-Spore
declare_project(thirdparty/lua-Spore)

# luajit
declare_project(thirdparty/luajit)

# luajson
declare_project(thirdparty/luajson)

# luasec
declare_project(thirdparty/luasec DEPENDS luajit openssl)

# luasocket
declare_project(thirdparty/luasocket DEPENDS luajit)

# lunajson
declare_project(thirdparty/lunajson)

# lunasvg
declare_project(thirdparty/lunasvg EXCLUDE_FROM_ALL)

# minizip
declare_project(thirdparty/minizip EXCLUDE_FROM_ALL)

# mupdf
declare_project(thirdparty/mupdf DEPENDS freetype2 harfbuzz libjpeg-turbo libwebp minizip zlib)

# nanosvg
declare_project(thirdparty/nanosvg)

# openssh
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/openssh ${EXCLUDE_FROM_ALL} DEPENDS openssl zlib)

# openssl
declare_project(thirdparty/openssl)

# popen-noshell
declare_project(thirdparty/popen-noshell EXCLUDE_FROM_ALL)

# sdcv
declare_project(thirdparty/sdcv DEPENDS glib zlib)

# sdl2
if(MACOS)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/sdl2 ${EXCLUDE_FROM_ALL})

# sqlite
declare_project(thirdparty/sqlite)

# tar
if(NOT ANDROID AND NOT DARWIN AND NOT WIN32)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/tar ${EXCLUDE_FROM_ALL})

# tesseract
declare_project(thirdparty/tesseract DEPENDS leptonica)

# turbo
declare_project(thirdparty/turbo DEPENDS openssl)

# utf8proc
declare_project(thirdparty/utf8proc)

# zlib
declare_project(thirdparty/zlib)

# zstd
declare_project(thirdparty/zstd)

# zsync2
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/zsync2 DEPENDS curl openssl zlib ${EXCLUDE_FROM_ALL})

# }}}

# Koreader executables and libs.
# NOTE: thirdparty dependencies are manually handled later
# for finer control (see `cmake/koreader/CMakeLists.txt`
# and `thirdparty/cmake_modules/koreader_targets.cmake`).
declare_project(cmake/koreader SOURCE_DIR .)

# And now for the real setup.
foreach(PRJ IN LISTS PROJECTS)
    setup_project(${PRJ})
endforeach()

# vim: foldmethod=marker foldlevel=0
