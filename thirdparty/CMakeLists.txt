add_custom_target(download-all)
add_custom_target(download)
add_custom_target(patch)

macro(add_project NAME)
    if(NOT ${NAME} IN_LIST PROJECTS)
        message(FATAL_ERROR "trying to setup undeclared project: ${NAME}")
    endif()
    if(NOT ${NAME}_SETUP)
        # Project is not already setup.
        set(${NAME}_SETUP TRUE)
        # Dependencies must be setup first.
        foreach(PRJ IN LISTS ${NAME}_DEPENDS)
            add_project(${PRJ})
            list(APPEND ${NAME}_BUILD_DEPENDS ${${PRJ}_BYPRODUCTS})
        endforeach()
        # Setup project variables.
        set(PROJECT_NAME "${NAME}")
        set(BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")
        set(SOURCE_DIR "${BASE_DIR}/source")
        set(BINARY_DIR "${BASE_DIR}/build")
        set(INSTALL_DIR "${STAGING_DIR}")
        # Add project directory.
        add_subdirectory(${NAME} ${${NAME}_EXCLUDE_FROM_ALL})
        get_property(${NAME}_BYPRODUCTS DIRECTORY ${NAME} PROPERTY ${NAME}_BYPRODUCTS)
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

function(declare_project NAME)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "" "DEPENDS" ${ARGN})
    # Handle optional EXCLUDE_FROM_ALL argument.
    if(_EXCLUDE_FROM_ALL)
        set(_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
    else()
        set(_EXCLUDE_FROM_ALL "")
    endif()
    set(PROJECTS ${PROJECTS} ${NAME} PARENT_SCOPE)
    set(${NAME}_DEPENDS ${_DEPENDS} PARENT_SCOPE)
    set(${NAME}_EXCLUDE_FROM_ALL ${_EXCLUDE_FROM_ALL} PARENT_SCOPE)
endfunction()

function(declare_dependency NAME)
    cmake_parse_arguments("" "" "" "INCLUDES;SHARED;STATIC;LIBRARIES" ${ARGN})
    string(REPLACE ":" "_" TGT _${NAME})
    add_library(${TGT} INTERFACE)
    string(REGEX MATCH "^([^:]+)::([^:])+$" MATCHES ${NAME})
    add_dependencies(${TGT} ${CMAKE_MATCH_1})
    set(INCS)
    if(DEFINED _INCLUDES)
        foreach(DIR IN LISTS _INCLUDES)
            list(APPEND INCS "${STAGING_DIR}/include/${DIR}")
        endforeach()
    else()
        list(APPEND INCS "${STAGING_DIR}/include")
    endif()
    set(LIBS)
    foreach(SUBDEP IN LISTS _SHARED)
        list(APPEND LIBS "${STAGING_DIR}/lib/lib${SUBDEP}${LIB_EXT}")
    endforeach()
    foreach(SUBDEP IN LISTS _STATIC)
        list(APPEND LIBS "${STAGING_DIR}/lib/lib${SUBDEP}.a")
    endforeach()
    list(APPEND LIBS ${_LIBRARIES})
    target_include_directories(${TGT} INTERFACE "${INCS}")
    target_link_libraries(${TGT} INTERFACE "${LIBS}")
    add_library(${NAME} ALIAS ${TGT})
endfunction()

# crengine
add_subdirectory(kpvcrlib)

# curl
declare_project(curl DEPENDS openssl zlib EXCLUDE_FROM_ALL)

# czmq
if(NOT WIN32)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(czmq DEPENDS libzmq ${EXCLUDE_FROM_ALL})

# djvulibre
declare_project(djvulibre)
declare_dependency(djvulibre::djvulibre SHARED djvulibre)

# dropbear
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(dropbear DEPENDS zlib ${EXCLUDE_FROM_ALL})

# fbink
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(fbink ${EXCLUDE_FROM_ALL})

# freetype
declare_project(freetype2)
declare_dependency(freetype2::freetype INCLUDES freetype2 SHARED freetype)

# fribidi
declare_project(fribidi)
declare_dependency(fribidi::fribidi SHARED fribidi)

# giflib
declare_project(giflib)

# glib
set(DEPENDS)
if(ANDROID OR DARWIN)
    list(APPEND DEPENDS libiconv proxy-libintl)
endif()
declare_project(glib DEPENDS ${DEPENDS} EXCLUDE_FROM_ALL)

# harfbuzz
declare_project(harfbuzz DEPENDS freetype2)
declare_dependency(harfbuzz::harfbuzz SHARED harfbuzz INCLUDES freetype)

# kobo-usbms
if(KOBO)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(kobo-usbms ${EXCLUDE_FROM_ALL})

# leptonica
declare_project(leptonica DEPENDS libpng)

# libiconv
declare_project(libiconv EXCLUDE_FROM_ALL)

# libjpeg-turbo
declare_project(libjpeg-turbo)
declare_dependency(libjpeg-turbo::jpeg SHARED jpeg)

# libk2pdfopt
declare_project(libk2pdfopt DEPENDS leptonica libpng tesseract zlib)
declare_dependency(libk2pdfopt::k2pdfopt INCLUDES leptonica SHARED k2pdfopt)

# libpng
declare_project(libpng DEPENDS zlib)
declare_dependency(libpng::png16 SHARED png16)

# libunibreak
declare_project(libunibreak)
declare_dependency(libunibreak::unibreak SHARED unibreak)

# libwebp
declare_project(libwebp)
declare_dependency(libwebp::webpdemux SHARED webp webpdemux)

# libzmq
if(NOT WIN32)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(libzmq ${EXCLUDE_FROM_ALL})

# lj-wpaclient
if(USE_LJ_WPACLIENT)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(lj-wpaclient ${EXCLUDE_FROM_ALL})

# lodepng
declare_project(lodepng)

# lpeg
declare_project(lpeg DEPENDS luajit)

# lua-htmlparser
declare_project(lua-htmlparser)

# lua-ljsqlite3
add_subdirectory(lua-ljsqlite3)

# lua-rapidjson
declare_project(lua-rapidjson DEPENDS luajit)

# lua-Spore
declare_project(lua-Spore)

# luajit
declare_project(luajit)
if(USE_LUAJIT_LIB)
    declare_dependency(luajit::luajit luajit SHARED luajit)
else()
    declare_dependency(luajit::luajit luajit)
endif()

# luajson
declare_project(luajson)

# luasec
declare_project(luasec DEPENDS luajit openssl)

# luasocket
declare_project(luasocket DEPENDS luajit)

# lunasvg
declare_project(lunasvg)
declare_dependency(lunasvg::lunasvg SHARED lunasvg)

# minizip
declare_project(minizip)

# mupdf
declare_project(mupdf DEPENDS freetype2 harfbuzz libjpeg-turbo libwebp minizip zlib)
declare_dependency(mupdf::mupdf SHARED mupdf)

# nanosvg
declare_project(nanosvg)
declare_dependency(nanosvg::nanosvg LIBRARIES m)

# openssh
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(openssh ${EXCLUDE_FROM_ALL} DEPENDS openssl zlib)

# openssl
declare_project(openssl)

# popen-noshell
declare_project(popen-noshell EXCLUDE_FROM_ALL)
declare_dependency(popen-noshell::popen-noshell STATIC popen_noshell)

# proxy-libintl
declare_project(proxy-libintl EXCLUDE_FROM_ALL)

# sdcv
declare_project(sdcv DEPENDS glib zlib)

# sdl2
if(MACOS)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(sdl2 ${EXCLUDE_FROM_ALL})

# sqlite
declare_project(sqlite)

# srell
add_library(srell INTERFACE)
target_include_directories(srell INTERFACE srell)
add_library(srell::srell ALIAS srell)

# tar
if(NOT ANDROID AND NOT DARWIN AND NOT WIN32)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(tar ${EXCLUDE_FROM_ALL})

# tesseract
declare_project(tesseract DEPENDS leptonica)

# turbo
declare_project(turbo DEPENDS luajit openssl)

# utf8proc
declare_project(utf8proc)
declare_dependency(utf8proc::utf8proc SHARED utf8proc)

# zlib
declare_project(zlib)
declare_dependency(zlib::z SHARED z)

# zstd
declare_project(zstd)
declare_dependency(zstd::zstd SHARED zstd)

# zsync2
if (CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_project(zsync2 DEPENDS curl openssl zlib ${EXCLUDE_FROM_ALL})

# And now for the real setup.
foreach(PRJ IN LISTS PROJECTS)
    add_project(${PRJ})
endforeach()
