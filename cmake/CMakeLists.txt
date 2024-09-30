cmake_minimum_required(VERSION 3.15)
project(koreader-base LANGUAGES C CXX)

include(CheckFunctionExists)
include(CheckSymbolExists)

include(${CMAKE_KOVARS})
include(koreader_external_project)
include(koreader_thirdparty_common)
include(koreader_targets)

add_custom_target(download-all)
add_custom_target(download)

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

function(setup_project NAME)
    if(NOT ${NAME} IN_LIST PROJECTS)
        message(FATAL_ERROR "trying to setup undeclared project: ${NAME}")
    endif()
    # Is project already setup?
    if(NOT TARGET ${NAME})
        # Dependencies must be setup first.
        set(BUILD_DEPENDS)
        set(CONFIGURE_TRIGGERS)
        foreach(PRJ IN LISTS ${NAME}_DEPENDS)
            setup_project(${PRJ})
            get_property(BYPRODUCTS TARGET ${PRJ} PROPERTY BYPRODUCTS)
            list(APPEND BUILD_DEPENDS ${BYPRODUCTS})
            get_property(HASH TARGET ${PRJ} PROPERTY HASH)
            if(NOT HASH STREQUAL "")
                string(PREPEND HASH ":")
            endif()
            list(APPEND CONFIGURE_TRIGGERS "${PRJ}${HASH}")
        endforeach()
        # Setup project variables.
        set(PROJECT_NAME ${NAME})
        set(DOWNLOAD_DIR ${${NAME}_DOWNLOAD_DIR})
        set(SOURCE_DIR ${${NAME}_SOURCE_DIR})
        set(BINARY_DIR ${${NAME}_BINARY_DIR})
        # Add project directory.
        add_subdirectory(${${NAME}_CMAKE_SOURCE_DIR} ${${NAME}_CMAKE_BINARY_DIR} ${${NAME}_EXCLUDE_FROM_ALL})
        # Update dependencies.
        set_property(TARGET ${NAME}-build APPEND PROPERTY DEPENDS "${BUILD_DEPENDS}")
        if(${NAME}_DEPENDS)
            add_dependencies(${NAME}-deps ${${NAME}_DEPENDS})
        endif()
        # Update triggers.
        set_property(TARGET ${NAME}-configure APPEND PROPERTY TRIGGERS "${CONFIGURE_TRIGGERS}")
    endif()
endfunction()

function(find_executable VAR NAME BINARY VERSION_ARG)
    cmake_parse_arguments("" "REQUIRED" "" "" ${ARGN})
    if(_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "unparsed arguments: ${_UNPARSED_ARGUMENTS}")
    endif()
    if(DEFINED CACHE{${VAR}} AND ${VAR})
        return()
    endif()
    find_program(${VAR} ${BINARY})
    if(NOT ${VAR})
        if(_REQUIRED)
            message(FATAL_ERROR "Could not find ${NAME} using the following names: ${BINARY}")
        endif()
        return()
    endif()
    execute_process(COMMAND ${${VAR}} ${VERSION_ARG} OUTPUT_VARIABLE VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCH "(^|[ \n])([0-9][.0-9]*)([\n ]|$)" VERSION "${VERSION}")
    message(STATUS "Found ${NAME}: ${${VAR}} (found version \"${CMAKE_MATCH_2}\")")
endfunction()

# }}}.

# Git. {{{

find_package(Git REQUIRED)

# }}}

# Meson. {{{

find_executable(MESON Meson meson --version REQUIRED)

set(MESON_SETUP
    ${MESON} setup ${MESON_TOOLCHAINS}
    --auto-features=disabled
    --bindir=
    --libdir=lib
    --prefix=${STAGING_DIR}
    --wrap-mode=nodownload
)

set(MESON_INSTALL ${MESON} install --no-rebuild)

# }}}

# Detect if libc provides iconv support.
check_symbol_exists(iconv iconv.h HAS_ICONV)
if(HAS_ICONV)
    check_function_exists(iconv HAS_ICONV)
endif()

# Detect if libc provides gettext support.
check_symbol_exists(ngettext libintl.h HAS_GETTEXT)
if(HAS_GETTEXT)
    check_function_exists(ngettext HAS_GETTEXT)
endif()

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

# ffi-cdecl
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(DEPENDS)
    if(EMULATE_READER)
        list(APPEND DEPENDS luajit)
    endif()
    declare_project(thirdparty/ffi-cdecl DEPENDS ${DEPENDS} EXCLUDE_FROM_ALL)
endif()

# freetype
declare_project(thirdparty/freetype2)

# fribidi
declare_project(thirdparty/fribidi EXCLUDE_FROM_ALL)

# giflib
declare_project(thirdparty/giflib)

# glib
set(DEPENDS pcre2)
if(NOT HAS_GETTEXT)
    list(APPEND DEPENDS proxy-libintl)
endif()
if(NOT HAS_ICONV)
    list(APPEND DEPENDS libiconv)
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
declare_project(thirdparty/luasec DEPENDS luajit luasocket openssl)

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

# openlipclua
if(KINDLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/openlipclua ${EXCLUDE_FROM_ALL} DEPENDS luajit)

# openssh
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/openssh ${EXCLUDE_FROM_ALL} DEPENDS openssl zlib)

# openssl
declare_project(thirdparty/openssl)

# pcre2
declare_project(thirdparty/pcre2 EXCLUDE_FROM_ALL)

# popen-noshell
declare_project(thirdparty/popen-noshell EXCLUDE_FROM_ALL)

# proxy-libintl
declare_project(thirdparty/proxy-libintl EXCLUDE_FROM_ALL)

# sdcv
declare_project(thirdparty/sdcv DEPENDS glib zlib)

# sdl2
if(APPIMAGE OR MACOS)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/sdl2 ${EXCLUDE_FROM_ALL})

# sqlite
declare_project(thirdparty/sqlite)

# tar
if(NOT ANDROID AND NOT APPLE AND NOT WIN32)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/tar ${EXCLUDE_FROM_ALL})

# tesseract
set(DEPENDS leptonica)
if(ANDROID)
    list(APPEND DEPENDS cpu_features)
endif()
declare_project(thirdparty/tesseract DEPENDS ${DEPENDS})

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
set(DOWNLOAD_PROJECTS)
foreach(PRJ IN LISTS PROJECTS)
    setup_project(${PRJ} FALSE)
    if(NOT ${PRJ}_EXCLUDE_FROM_ALL)
        list(APPEND DOWNLOAD_PROJECTS ${PRJ})
    endif()
    add_dependencies(download-all ${PRJ}-download)
endforeach()
# We want `download` to download all projects build by default,
# **including** their dependencies and transitive dependencies.
while(DOWNLOAD_PROJECTS)
    list(POP_FRONT DOWNLOAD_PROJECTS PRJ)
    list(APPEND DOWNLOAD_PROJECTS ${${PRJ}_DEPENDS})
    add_dependencies(download ${PRJ}-download)
endwhile()

# Add `rm-install-stamps` target.
set(INSTALL_STAMPS)
foreach(PRJ IN LISTS PROJECTS)
    get_property(STAMP TARGET ${PRJ}-install PROPERTY STAMP)
    list(APPEND INSTALL_STAMPS ${STAMP})
endforeach()
add_custom_target(rm-install-stamps COMMAND rm -f ${INSTALL_STAMPS})

# vim: foldmethod=marker foldlevel=0
