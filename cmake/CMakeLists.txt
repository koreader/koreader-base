cmake_minimum_required(VERSION 3.17.5)
project(koreader-base LANGUAGES C CXX)

include(CheckFunctionExists)
include(CheckSymbolExists)

include(${CMAKE_KOVARS})
include(koreader_external_project)
include(koreader_thirdparty_common)
include(koreader_targets)

add_custom_target(download-all)
add_custom_target(download)
add_custom_target(prepare-all)
add_custom_target(prepare)

# HELPERS. {{{

set(PROJECTS)

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
    else()
        set(${NAME}_EXCLUDE_FROM_ALL PARENT_SCOPE)
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

# }}}.

# Ensure `MACOSX_DEPLOYMENT_TARGET` is set, and `CMAKE_OSX_DEPLOYMENT_TARGET` matches.
if(APPLE)
    if(NOT DEFINED ENV{MACOSX_DEPLOYMENT_TARGET} OR "$ENV{MACOSX_DEPLOYMENT_TARGET}" STREQUAL "")
        message(FATAL_ERROR "$MACOSX_DEPLOYMENT_TARGET is not set")
    endif()
    if(NOT "$ENV{MACOSX_DEPLOYMENT_TARGET}" STREQUAL CMAKE_OSX_DEPLOYMENT_TARGET)
        message(FATAL_ERROR "$MACOSX_DEPLOYMENT_TARGET / CMAKE_OSX_DEPLOYMENT_TARGET discrepancy: \"$ENV{MACOSX_DEPLOYMENT_TARGET}\" != \"${CMAKE_OSX_DEPLOYMENT_TARGET}\"")
    endif()
    message(STATUS "OSX deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()

# Git. {{{

find_package(Git REQUIRED)

# }}}

# Meson. {{{

find_executable(MESON Meson meson --version REQUIRED)

set(MESON_SETUP
    ${MESON} setup ${MESON_TOOLCHAINS}
    --auto-features=disabled
    --bindir=bin
    --libdir=lib
    --prefix=${STAGING_DIR}
    --wrap-mode=nodownload
)

set(MESON_INSTALL ${MESON} install --no-rebuild)

# }}}

# Detect if libc provides iconv support.
check_libc_fn_exists(iconv iconv.h HAS_ICONV)

# Detect if libc provides gettext support.
check_libc_fn_exists(ngettext libintl.h HAS_GETTEXT)

# We'll want to ship the shared STL library on some platforms.
#
# We don't want to rely on `-static-libstdc++`, as it risks breaking the ODR. (Also, it was a pain to deal with because
# of libtool, c.f., https://www.gnu.org/software/libtool/manual/html_node/Stripped-link-flags.html#Stripped-link-flags).
#
if(NOT ((ANDROID AND MONOLIBTIC) OR APPLE OR EMULATE_READER OR SDL))
    if(ANDROID)
        set(STL_NAME libc++_shared.so)
    else()
        set(STL_NAME libstdc++.so.6)
    endif()
    find_compiler_lib_path(STL_PATH ${STL_NAME} REQUIRED)
    append_binary_install_command(CMD_LIST ${STL_PATH} DESTINATION ${OUTPUT_DIR}/libs)
    add_custom_command(
        OUTPUT ${OUTPUT_DIR}/libs/${STL_NAME}
        COMMAND ${CMD_LIST}
        COMMENT "Installing '${STL_NAME}'"
        DEPENDS ${STL_PATH}
        VERBATIM
    )
    add_custom_target(stl-install ALL DEPENDS ${OUTPUT_DIR}/libs/${STL_NAME})
endif()

# THIRDPARTY. {{{

# android-luajit-launcher
if(IS_DIRECTORY "${ANDROID_LAUNCHER_DIR}")
    if(ANDROID)
        set(EXCLUDE_FROM_ALL)
    else()
        set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
    endif()
    declare_project(
        thirdparty/android-luajit-launcher
        DEPENDS libarchive luajit ${EXCLUDE_FROM_ALL}
        SOURCE_DIR ${ANDROID_LAUNCHER_DIR}
    )
endif()

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
    md4c
    nanosvg
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
declare_project(thirdparty/curl DEPENDS libressl zlib EXCLUDE_FROM_ALL)

# czmq
if(NOT WIN32)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/czmq DEPENDS libzmq ${EXCLUDE_FROM_ALL})

# djvulibre
declare_project(thirdparty/djvulibre DEPENDS libjpeg-turbo EXCLUDE_FROM_ALL)

# dkjson
declare_project(thirdparty/dkjson)

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
set(fbdepth_DOWNLOAD_DIR ${fbink_DOWNLOAD_DIR})
set(fbdepth_CMAKE_SOURCE_DIR ${fbink_CMAKE_SOURCE_DIR})
declare_project(thirdparty/libfbink_input ${EXCLUDE_FROM_ALL})
set(libfbink_input_DOWNLOAD_DIR ${fbink_DOWNLOAD_DIR})
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
set(DEPENDS)
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

# koreader-lfs
declare_project(thirdparty/koreader-lfs DEPENDS luajit)

# leptonica
declare_project(thirdparty/leptonica DEPENDS libpng)

# libarchive
set(DEPENDS zlib zstd)
if(ANDROID)
    list(APPEND DEPENDS xz)
endif()
declare_project(thirdparty/libarchive DEPENDS ${DEPENDS})

# libiconv
declare_project(thirdparty/libiconv EXCLUDE_FROM_ALL)

# libjpeg-turbo
declare_project(thirdparty/libjpeg-turbo)

# libk2pdfopt
declare_project(thirdparty/libk2pdfopt DEPENDS leptonica libpng tesseract zlib)

# libpng
declare_project(thirdparty/libpng DEPENDS zlib EXCLUDE_FROM_ALL)

# libressl
# NOTE: `EXCLUDE_FROM_ALL` is not used because `ffi/crypto` needs `libcrypto`.
declare_project(thirdparty/libressl)

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

# luarocks
declare_project(thirdparty/luarocks DEPENDS luajit EXCLUDE_FROM_ALL)

# luasec
declare_project(thirdparty/luasec DEPENDS luajit luasocket libressl)

# luasocket
declare_project(thirdparty/luasocket DEPENDS luajit)

# lunasvg
declare_project(thirdparty/lunasvg EXCLUDE_FROM_ALL)

# md4c
declare_project(thirdparty/md4c EXCLUDE_FROM_ALL)

# minizip
declare_project(thirdparty/minizip EXCLUDE_FROM_ALL)

# mupdf
declare_project(thirdparty/mupdf DEPENDS freetype2 harfbuzz libarchive libjpeg-turbo libwebp minizip zlib)

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
declare_project(thirdparty/openssh ${EXCLUDE_FROM_ALL})

# popen-noshell
declare_project(thirdparty/popen-noshell EXCLUDE_FROM_ALL)

# proxy-libintl
declare_project(thirdparty/proxy-libintl EXCLUDE_FROM_ALL)

# sdcv
declare_project(thirdparty/sdcv DEPENDS glib zlib)

# sdl2
if(APPIMAGE OR APPLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(thirdparty/sdl2 ${EXCLUDE_FROM_ALL})

# sqlite
declare_project(thirdparty/sqlite)

# tar
if(NOT (ANDROID OR APPLE OR EMULATE_READER OR WIN32))
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
declare_project(thirdparty/turbo DEPENDS libressl)

# utf8proc
declare_project(thirdparty/utf8proc)

# xz
declare_project(thirdparty/xz EXCLUDE_FROM_ALL)

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
declare_project(thirdparty/zsync2 DEPENDS curl libressl zlib ${EXCLUDE_FROM_ALL})

# }}}

# TESTSUITE DEPENDENCIES. {{{

if(EMULATE_READER)
    add_custom_target(spec-rocks)
    foreach(PRJ
            busted
            cluacov
            lua-term
            lua_cliargs
            luacov
            luafilesystem
            luassert
            luasystem
            mediator_lua
            penlight
            say
        )
        declare_project(thirdparty/spec/${PRJ} DEPENDS luarocks)
        add_dependencies(spec-rocks ${PRJ})
    endforeach()
endif()

# }}}

# Koreader executables and libs (except koreader-lfs, see above).
# NOTE: thirdparty dependencies are manually handled later
# for finer control (see `cmake/koreader/CMakeLists.txt`
# and `thirdparty/cmake_modules/koreader_targets.cmake`).
declare_project(cmake/koreader SOURCE_DIR .)

# And now for the real setup.
set(BUILD_PROJECTS)
foreach(PRJ IN LISTS PROJECTS)
    setup_project(${PRJ} FALSE)
    if(NOT ${PRJ}_EXCLUDE_FROM_ALL)
        list(APPEND BUILD_PROJECTS ${PRJ})
    endif()
    add_dependencies(download-all ${PRJ}-download)
    add_dependencies(prepare-all ${PRJ}-prepare)
endforeach()
# We want `download` & `prepare` to download / prepare all projects built
# by default, **including** their dependencies and transitive dependencies.
while(BUILD_PROJECTS)
    list(POP_FRONT BUILD_PROJECTS PRJ)
    list(APPEND BUILD_PROJECTS ${${PRJ}_DEPENDS})
    add_dependencies(download ${PRJ}-download)
    add_dependencies(prepare ${PRJ}-prepare)
endwhile()

# Add `rm-install-stamps` target.
set(INSTALL_STAMPS)
foreach(PRJ IN LISTS PROJECTS)
    get_property(STAMP TARGET ${PRJ}-install PROPERTY STAMP)
    list(APPEND INSTALL_STAMPS ${STAMP})
endforeach()
add_custom_target(rm-install-stamps COMMAND rm -f ${INSTALL_STAMPS})

# FFI cdecls generation. {{{

add_custom_target(ffi)

function(ffi_target NAME OUTPUT INPUT)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "" "DEPENDS;ARGS" ${ARGN})
    list(PREPEND _DEPENDS ffi-cdecl)
    if(TARGET ${NAME})
        list(PREPEND _DEPENDS ${NAME})
    endif()
    if(NOT INPUT MATCHES ".*/.*")
        set(INPUT ffi-cdecl/${INPUT})
    endif()
    get_filename_component(INPUT_PATH ${INPUT} ABSOLUTE BASE_DIR ${BASE_DIR})
    add_custom_target(
        ${OUTPUT}
        BYPRODUCTS ${BASE_DIR}/ffi/${OUTPUT}
        DEPENDS ${_DEPENDS}
        COMMAND ${STAGING_DIR}/bin/ffi-cdecl -o ffi/${OUTPUT} ${_ARGS} ${INPUT}
        COMMENT "Generating 'ffi/${OUTPUT}'"
        VERBATIM
        WORKING_DIRECTORY ${BASE_DIR}
    )
    if(NOT TARGET ${NAME}-ffi)
        add_custom_target(${NAME}-ffi)
        if(NOT ${_EXCLUDE_FROM_ALL} AND NOT ${NAME}_EXCLUDE_FROM_ALL)
            add_dependencies(ffi ${NAME}-ffi)
        endif()
    endif()
    add_dependencies(${NAME}-ffi ${OUTPUT})
endfunction()

# cervantes
if(CERVANTES)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
ffi_target(cervantes mxcfb_cervantes_h.lua mxcfb_cervantes_decl.c ${EXCLUDE_FROM_ALL})

# czmq
ffi_target(czmq zeromq_h.lua zeromq_cdecl.c ARGS -d libczmq)

# fbdepth / fbink / libfbink_input
get_relative_path(${libfbink_input_SOURCE_DIR} ${BASE_DIR} FBINK_INPUT_SRC)
ffi_target(libfbink_input fbink_input_h.lua ${FBINK_INPUT_SRC}/ffi/fbink_input_decl.c ARGS -I ${FBINK_INPUT_SRC})

# freetype
ffi_target(freetype2 freetype_h.lua freetype2_decl.c ARGS -d freetype2)

# giflib
ffi_target(giflib giflib_h.lua giflib_decl.c)

# harfbuzz
ffi_target(harfbuzz harfbuzz_h.lua harfbuzz_cdecl.c ARGS -d harfbuzz)

# kindle
if(KINDLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
ffi_target(kindle mxcfb_kindle_h.lua mxcfb_kindle_decl.c ${EXCLUDE_FROM_ALL})

# kobo
if(KINDLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
foreach(TGT ion mxcfb sunxi)
    ffi_target(kobo ${TGT}_kobo_h.lua ${TGT}_kobo_decl.c ${EXCLUDE_FROM_ALL})
endforeach()

# leptonica
ffi_target(leptonica leptonica_h.lua leptonica_cdecl.c ARGS -d lept)

# libarchive
ffi_target(libarchive libarchive_h.lua libarchive_cdecl.c ARGS -d libarchive)

# libjpeg-turbo
ffi_target(libjpeg-turbo turbojpeg_h.lua turbojpeg_decl.c ARGS -d libturbojpeg)

# libk2pdfopt
get_relative_path(${STAGING_DIR}/include/k2pdfopt ${BASE_DIR} K2PDFOPT_INC)
ffi_target(libk2pdfopt koptcontext_h.lua koptcontext_cdecl.c ARGS -d lept -I ${K2PDFOPT_INC})

# libressl
ffi_target(libressl crypto_h.lua crypto_decl.c ARGS -d libcrypto)

# libwebp
ffi_target(libwebp libwebp_h.lua libwebp_decl.c ARGS -d libwebp)

# linux
if(LINUX AND EMULATE_READER)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
ffi_target(linux einkfb_h.lua einkfb_decl.c ${EXCLUDE_FROM_ALL})
ffi_target(linux inotify_h.lua inotify_decl.c ${EXCLUDE_FROM_ALL})
ffi_target(linux linux_fb_h.lua linux_fb_decl.c ${EXCLUDE_FROM_ALL})
ffi_target(linux linux_input_h.lua linux_input_decl.c ${EXCLUDE_FROM_ALL})
ffi_target(linux rtc_h.lua rtc_cdecl.c ${EXCLUDE_FROM_ALL})

# lodepng
ffi_target(lodepng lodepng_h.lua lodepng_decl.c)

# mupdf
ffi_target(mupdf mupdf_h.lua wrap-mupdf_cdecl.c ARGS -I . -f -std=gnu11)

# pocketbook
if(POCKETBOOK)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
ffi_target(pocketbook mxcfb_pocketbook_h.lua mxcfb_pb_decl.c ${EXCLUDE_FROM_ALL})

# remarkable
if(REMARKABLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
ffi_target(remarkable mxcfb_remarkable_h.lua mxcfb_remarkable_decl.c ${EXCLUDE_FROM_ALL})

# sdl2
ffi_target(sdl2 SDL2_0_h.lua SDL2_0_decl.c ARGS -d sdl2)

# utf8proc
ffi_target(utf8proc utf8proc_h.lua utf8proc_decl.c ARGS -d libutf8proc)

# zlib
ffi_target(zlib zlib_h.lua zlib_decl.c ARGS -d zlib)

# zstd
ffi_target(zstd zstd_h.lua zstd_decl.c ARGS -d libzstd)

# }}}

# vim: foldmethod=marker foldlevel=0
