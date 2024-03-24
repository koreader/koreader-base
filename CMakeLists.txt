cmake_minimum_required(VERSION 3.15)
project(koreader-base LANGUAGES C CXX)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Binaries go there.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_DIR}")
# And libraries here.
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_DIR}/libs")

add_subdirectory(thirdparty "${OUTPUT_DIR}/thirdparty")

function(add_koreader_library NAME)
    cmake_parse_arguments("" "" "" "DEPENDS" ${ARGN})
    add_library(${NAME} SHARED ${_UNPARSED_ARGUMENTS})
    foreach(DEP IN LISTS _DEPENDS)
        target_link_libraries(${NAME} ${DEP})
    endforeach()
    set_target_properties(${NAME} PROPERTIES C_VISIBILITY_PRESET hidden)
    set_target_properties(${NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
    if(DO_STRIP)
        set(STRIP_CMD "")
        append_strip_command(STRIP_CMD)
        list(APPEND STRIP_CMD "$<TARGET_FILE:${NAME}>")
        add_custom_command(TARGET ${NAME} POST_BUILD COMMAND ${STRIP_CMD})
    endif()
endfunction()

# KOREADER LIBRARIES. {{{

# blitbuffer
if(ANDROID OR CERVANTES OR KINDLE OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX OR USE_SDL)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_koreader_library(blitbuffer ${EXCLUDE_FROM_ALL} blitbuffer.c)
target_compile_options(blitbuffer PRIVATE "SHELL:${VECTO_CFLAGS}")

# koreade-cre
add_koreader_library(koreader-cre cre.cpp DEPENDS crengine luajit::luajit)

# koreader-djvu
add_koreader_library(koreader-djvu djvu.c DEPENDS djvulibre::djvulibre libk2pdfopt::k2pdfopt luajit::luajit)

# kodeader-input
if(NOT ANDROID AND NOT USE_SDL)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_koreader_library(koreader-input ${EXCLUDE_FROM_ALL} input/input.c)
target_include_directories(koreader-input PRIVATE input)
foreach(PLATFORM CERVANTES KOBO KINDLE LEGACY POCKETBOOK REMARKABLE SONY_PRSTUX)
    if(${PLATFORM})
        if(PLATFORM STREQUAL "LEGACY")
            set(PLATFORM "KINDLE_LEGACY")
        endif()
        target_compile_definitions(koreader-input PRIVATE "-D${PLATFORM}")
    endif()
endforeach()
target_link_libraries(koreader-input luajit::luajit)
if(KINDLE OR REMARKABLE)
    target_link_libraries(koreader-input popen-noshell::popen-noshell)
elseif(POCKETBOOK)
    target_link_libraries(koreader-input inkview)
endif()

# koreader-lfs
add_custom_command(
    COMMAND
    ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/luafilesystem/src/lfs.h" lfs.h
    OUTPUT lfs.h
    MAIN_DEPENDENCY luafilesystem/src/lfs.h
)
# Avoid precision loss on 32-bit arches (LFS is always built w/ LARGEFILE
# support, but lua_Integer is always a ptrdiff_t, which is not wide enough).
add_custom_command(
    COMMAND
    patch -p1
    "--directory=${CMAKE_SOURCE_DIR}/luafilesystem"
    "--input=${CMAKE_SOURCE_DIR}/patches/lfs-pushnumber-for-wide-types.patch"
    "--output=${CMAKE_BINARY_DIR}/lfs.c"
    OUTPUT lfs.c
    DEPENDS patches/lfs-pushnumber-for-wide-types.patch
    MAIN_DEPENDENCY luafilesystem/src/lfs.c
)
add_koreader_library(koreader-lfs lfs.c lfs.h DEPENDS luajit::luajit)
set_target_properties(koreader-lfs PROPERTIES SUFFIX .so)
set_target_properties(koreader-lfs PROPERTIES C_VISIBILITY_PRESET default)

# koreader-nnsvg
add_koreader_library(koreader-nnsvg nnsvg.c DEPENDS luajit::luajit nanosvg::nanosvg)

# koreader-xtext
add_koreader_library(koreader-xtext xtext.cpp DEPENDS freetype2::freetype fribidi::fribidi harfbuzz::harfbuzz luajit::luajit libunibreak::unibreak)

# wrap-mupdf
add_koreader_library(wrap-mupdf wrap-mupdf.c DEPENDS mupdf::mupdf)

# }}}

# MISCELLANY. {{{

# extr
add_executable(extr EXCLUDE_FROM_ALL extr.c)
target_link_libraries(extr mupdf::mupdf)

# libXss
if(APPIMAGE)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_library(Xss SHARED ${EXCLUDE_FROM_ALL} libxss-dummy.c)
set_target_properties(Xss PROPERTIES SOVERSION 1)

# koreader
if(DARWIN)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_executable(koreader ${EXCLUDE_FROM_ALL} osx_loader.c)
target_link_libraries(koreader luajit::luajit)

# inkview-compat
if(POCKETBOOK)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_library(inkview-compat SHARED ${EXCLUDE_FROM_ALL} input/inkview-compat.c)
target_link_libraries(inkview-compat inkview)

# button-listen
if(REMARKABLE)
    set(EXCLUDE_FROM_ALL "")
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
add_executable(button-listen ${EXCLUDE_FROM_ALL} button-listen.c)

# }}}

# vim: foldmethod=marker foldlevel=0
