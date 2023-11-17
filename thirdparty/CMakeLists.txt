add_custom_target(download)
add_custom_target(patch)

function(add_project NAME)
    cmake_parse_arguments("" "INTERNAL" "DIRECTORY" "DEPENDS" ${ARGN})
    # Handle optional DIRECTORY argument.
    if(NOT _DIRECTORY)
        set(_DIRECTORY ${NAME})
    endif()
    # Set global variables for later setup stage (inter-project dependencies).
    set("${NAME}_DEPENDS" ${_DEPENDS} PARENT_SCOPE)
    set("${NAME}_DIR" ${_DIRECTORY} PARENT_SCOPE)
    set("${NAME}_INTERNAL" ${_INTERNAL} PARENT_SCOPE)
    set(PROJECTS ${PROJECTS} ${NAME} PARENT_SCOPE)
    # Setup directory variables.
    set(KO_DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${_DIRECTORY}/build/downloads")
    set(BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/${_DIRECTORY}")
    set(SOURCE_DIR "${BASE_DIR}/source")
    set(BINARY_DIR "${BASE_DIR}/build")
    set(INSTALL_DIR "${BASE_DIR}/install")
    # Add project directory.
    add_subdirectory("${_DIRECTORY}")
    # Add clean target.
    add_custom_target(${NAME}-clean
        # Remove base build directory.
        COMMAND rm -rf "${BASE_DIR}"
        # And trigger regenerating it the next time.
        COMMAND touch "${CMAKE_CURRENT_SOURCE_DIR}/${_DIRECTORY}/CMakeLists.txt"
    )
    # Add dependency to global targets.
    if(NOT _INTERNAL)
        add_dependencies(download ${NAME}-download)
        add_dependencies(patch ${NAME}-patch)
    endif()
endfunction()

# crengine
add_project(crengine DIRECTORY kpvcrlib INTERNAL DEPENDS
    freetype fribidi harfbuzz libunibreak
    utf8proc libjpeg libpng libwebp
    lunasvg zlib zstd)
# curl
if (CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX)
    add_project(curl DEPENDS openssl zlib)
endif()
# czmq
if(NOT WIN32)
    add_project(czmq DEPENDS libzmq)
endif()
# djvulibre
add_project(djvulibre)
# dropbear
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    add_project(dropbear DEPENDS zlib)
endif()
# fbink
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE)
    add_project(fbink)
endif()
# freetype
add_project(freetype DIRECTORY freetype2)
# fribidi
add_project(fribidi)
# gettext
add_project(gettext DEPENDS libiconv)
# giflib
add_project(giflib)
# glib
add_project(glib DEPENDS gettext libiconv)
# harfbuzz
add_project(harfbuzz DEPENDS freetype)
# k2pdfopt
add_project(k2pdfopt DIRECTORY libk2pdfopt DEPENDS leptonica libpng tesseract zlib)
# kobo-usbms
if(KOBO)
    add_project(kobo-usbms)
endif()
# leptonica
add_project(leptonica DEPENDS libpng)
# libaes
add_project(libaes DIRECTORY minizip)
# libiconv
add_project(libiconv)
# libjpeg
add_project(libjpeg DIRECTORY libjpeg-turbo)
# libpng
add_project(libpng DEPENDS zlib)
# libunibreak
add_project(libunibreak)
# libwebp
add_project(libwebp)
# libzmq
if(NOT WIN32)
    add_project(libzmq)
endif()
# lj-wpaclient
if(USE_LJ_WPACLIENT)
    add_project(lj-wpaclient DEPENDS luajit)
endif()
# ljsqlite
add_project(ljsqlite DIRECTORY lua-ljsqlite3 INTERNAL)
# lodepng
add_project(lodepng)
# lpeg
add_project(lpeg DEPENDS luajit)
# lua-htmlparser
add_project(lua-htmlparser DEPENDS luajit)
# lua-rapidjson
add_project(lua-rapidjson DEPENDS luajit)
# lua-Spore
add_project(lua-Spore DEPENDS luajit luajson luasocket)
# luajit
add_project(luajit)
# luajson
add_project(luajson DEPENDS luajit lpeg)
# luasec
add_project(luasec DEPENDS luajit openssl)
# luasocket
add_project(luasocket DEPENDS luajit)
# lunasvg
add_project(lunasvg)
# mupdf
add_project(mupdf DEPENDS freetype harfbuzz libaes libjpeg libwebp zlib)
# nanosvg
add_project(nanosvg)
# openssh
if(CERVANTES OR KINDLE OR KOBO OR POCKETBOOK)
    add_project(openssh DEPENDS openssl zlib)
endif()
# openssl
add_project(openssl)
# popen-noshell
if(KINDLE OR REMARKABLE)
    add_project(popen-noshell)
endif()
# sdcv
add_project(sdcv DEPENDS gettext libiconv glib zlib)
# sdl
if(MACOS)
    add_project(sdl DIRECTORY sdl2)
endif()
# sqlite
add_project(sqlite)
# tar
if(NOT ANDROID AND NOT DARWIN AND NOT WIN32)
    add_project(tar)
endif()
# tesseract
add_project(tesseract DEPENDS leptonica)
# turbo
add_project(turbo DEPENDS luajit openssl)
# utf8proc
add_project(utf8proc)
# zlib
add_project(zlib)
# zstd
add_project(zstd)
# zsync2
if (CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX)
    add_project(zsync2 DEPENDS curl openssl zlib)
endif()

# Setup inter-project dependencies.
foreach(NAME IN LISTS PROJECTS)
    if(NOT ${NAME}_DEPENDS)
        continue()
    endif()
    set(TARGET "${NAME}")
    if(NOT ${NAME}_INTERNAL)
        string(APPEND TARGET "-configure")
    endif()
    message(STATUS "${TARGET} ← ${${NAME}_DEPENDS}")
    add_dependencies("${TARGET}" ${${NAME}_DEPENDS})
endforeach()
