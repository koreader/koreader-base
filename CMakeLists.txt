cmake_minimum_required(VERSION 3.19)
project(koreader-base LANGUAGES C CXX)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_DIR}/libs")

add_subdirectory(thirdparty)

function(add_koreader_library NAME)
    cmake_parse_arguments("" "" "" "DEPENDS" ${ARGN})
    add_library(${NAME} SHARED ${_UNPARSED_ARGUMENTS})
    foreach(DEP IN LISTS _DEPENDS)
        target_link_libraries(${NAME} ${DEP}_dep)
    endforeach()
    set_target_properties(${NAME} PROPERTIES VISIBILITY_INLINES_HIDDEN TRUE)
endfunction()

function(declare_dependency NAME)
    cmake_parse_arguments("" "" "" "INCLUDES;SHARED;STATIC" ${ARGN})
    set(DEP ${NAME}_dep)
    add_library(${DEP} INTERFACE)
    add_dependencies(${DEP} ${NAME})
    target_include_directories(${DEP} INTERFACE "${STAGING_DIR}/${NAME}/include")
    foreach(SUBDEP IN LISTS _INCLUDES)
        add_dependencies(${DEP} ${SUBDEP})
        target_include_directories(${DEP} INTERFACE "${STAGING_DIR}/${SUBDEP}/include")
    endforeach()
    foreach(SUBDEP IN LISTS _SHARED)
        add_dependencies(${DEP} ${SUBDEP})
        set_libname(LIB "${SUBDEP}")
        target_link_libraries(${DEP} INTERFACE "${STAGING_DIR}/${NAME}/shared/${LIB}")
    endforeach()
    foreach(SUBDEP IN LISTS _STATIC)
        add_dependencies(${DEP} ${SUBDEP})
        set(LIB "lib${SUBDEP}.a")
        target_link_libraries(${DEP} INTERFACE "${STAGING_DIR}/${NAME}/static/${LIB}")
    endforeach()
endfunction()

# DEPENDENCIES. {{{

# crengine
add_library(crengine_dep ALIAS crengine)
target_link_libraries(crengine
    antiword
    chmlib
    fribidi_dep
    harfbuzz_dep
    libjpeg_dep
    libpng_dep
    libunibreak_dep
    libwebp_dep
    lunasvg_dep
    utf8proc_dep
    zlib_dep
    zstd_dep
)

# djvulibre
declare_dependency(djvulibre SHARED djvulibre)

# freetype
declare_dependency(freetype SHARED freetype)

# fribidi
declare_dependency(fribidi SHARED fribidi)

# harfbuzz
declare_dependency(harfbuzz SHARED harfbuzz INCLUDES freetype)

# k2pdfopt
declare_dependency(k2pdfopt INCLUDES leptonica SHARED k2pdfopt)

# libjpeg
declare_dependency(libjpeg INCLUDE libturbo-jpeg SHARED jpeg)

# libpng
declare_dependency(libpng SHARED png16)

# libunibreak
declare_dependency(libunibreak SHARED unibreak)

# libwebp
declare_dependency(libwebp SHARED webp webpdemux)

# luajit
declare_dependency(luajit)
if(USE_LUAJIT_LIB)
    target_link_libraries(luajit_dep INTERFACE "${STAGING_DIR}/luajit/shared/libluajit.so")
endif()

# lunasvg
declare_dependency(lunasvg SHARED lunasvg)

# mupdf
declare_dependency(mupdf SHARED mupdf)

# nanosvg
declare_dependency(nanosvg)

# popen-noshell
declare_dependency(popen-noshell STATIC popen_noshell)

# utf8proc
declare_dependency(utf8proc SHARED utf8proc)

# zlib
declare_dependency(zlib SHARED z)

# zstd
declare_dependency(zstd SHARED zstd)

# }}}

# KOREADER LIBRARIES. {{{

# blitbuffer
if(ANDROID OR CERVANTES OR KINDLE OR POCKETBOOK OR REMARKABLE OR SDL OR SONY_PRSTUX)
    add_koreader_library(blitbuffer blitbuffer.c DEPENDS luajit)
endif()

# koreade-cre
add_koreader_library(koreader-cre cre.cpp DEPENDS crengine luajit)

# koreader-djvu
add_koreader_library(koreader-djvu djvu.c DEPENDS djvulibre k2pdfopt luajit)
if(NOT ANDROID)
    target_link_libraries(koreader-djvu pthread)
endif()

# kodeader-input
if(NOT SDL AND NOT ANDROID)
    add_koreader_library(koreader-input SHARED input/input.c)
    target_include_directories(koreader-input PRIVATE input)
    set(LEGACY 1)
    foreach(PLATFORM CERVANTES KOBO KINDLE LEGACY POCKETBOOK REMARKABLE SONY_PRSTUX)
        if(${PLATFORM})
            if(PLATFORM STREQUAL "LEGACY")
                set(PLATFORM "KINDLE_LEGACY")
            endif()
            target_compile_definitions(koreader-input PRIVATE "-D${PLATFORM}")
            break()
        endif()
    endforeach()
    target_link_libraries(koreader-input luajit_dep)
    if(KINDLE OR REMARKABLE)
        target_link_libraries(koreader-input popen-noshell_dep)
    elseif(POCKETBOOK)
        target_link_libraries(koreader-input inkview)
    endif()
endif()

# koreader-lfs
add_custom_command(
    COMMAND
    patch -p1
    "--directory=${CMAKE_SOURCE_DIR}/luafilesystem"
    # Avoid precision loss on 32-bit arches (LFS is always built w/ LARGEFILE
    # support, but lua_Integer is always a ptrdiff_t, which is not wide enough).
    "--input=${CMAKE_SOURCE_DIR}/patches/lfs-pushnumber-for-wide-types.patch"
    "--output=${CMAKE_BINARY_DIR}/lfs.c"
    OUTPUT lfs.c
    DEPENDS patches/lfs-pushnumber-for-wide-types.patch
    MAIN_DEPENDENCY luafilesystem/src/lfs.c
)
add_koreader_library(koreader-lfs lfs.c DEPENDS luajit)
target_include_directories(koreader-lfs PRIVATE luafilesystem/src)

# koreader-nnsvg
add_koreader_library(koreader-nnsvg nnsvg.c DEPENDS nanosvg luajit)

# koreader-xtext
add_koreader_library(koreader-xtext xtext.cpp DEPENDS fribidi harfbuzz libunibreak luajit)

# wrap-mupdf
add_koreader_library(wrap-mupdf wrap-mupdf.c DEPENDS mupdf)

# }}}

# MISCELLANY. {{{

add_executable(extr EXCLUDE_FROM_ALL extr.c)
target_link_libraries(extr mupdf_dep)

if(APPIMAGE)
    add_library(Xss SHARED libxss-dummy.c)
    set_target_properties(Xss PROPERTIES SOVERSION 1)
endif()

if(DARWIN)
    add_executable(koreader osx_loader.c)
    add_dependencies(koreader luajit)
    target_include_directories(koreader PRIVATE "${STAGING_DIR}/luajit/include")
    target_link_libraries(koreader "${STAGING_DIR}/luajit/static/libluajit.a" m)
endif()

if(POCKETBOOK)
    add_library(inkview-compat SHARED input/inkview-compat.c)
    target_link_libraries(inkview-compat inkview)
endif()

if(REMARKABLE)
    add_executable(button-listen button-listen.c)
endif()

# }}}

# vim: foldmethod=marker foldlevel=0
