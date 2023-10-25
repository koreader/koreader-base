project(kpvcrlib)
cmake_minimum_required(VERSION 3.5.1)
enable_language(C CXX ASM)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

set(CMAKE_ASM_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_ASM_COMPILER_ARG1 ${CMAKE_CXX_COMPILER_ARG1})
set(CMAKE_ASM_FLAGS ${CMAKE_CXX_FLAGS})
set(CMAKE_ASM_FLAGS_RELEASE "")

set(CMAKE_SKIP_RPATH TRUE)

set(CR_3RDPARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/crengine/thirdparty)
set(CRE_DIR crengine/crengine)

set(ANTIWORD_INCLUDE_DIR ${CR_3RDPARTY_DIR}/antiword)
set(CHM_INCLUDE_DIRS ${CR_3RDPARTY_DIR}/chmlib/src)
set(CREGINE_INCLUDE_DIR ${CRE_DIR}/include)

assert_var_defined(JCONFIG_INCLUDE_DIR)
assert_var_defined(FREETYPE_INCLUDE_DIR)
assert_var_defined(HARFBUZZ_INCLUDE_DIR)
assert_var_defined(FRIBIDI_INCLUDE_DIR)
assert_var_defined(LIBUNIBREAK_INCLUDE_DIR)
assert_var_defined(UTF8PROC_INCLUDE_DIR)
assert_var_defined(PNG_INCLUDE_DIR)
assert_var_defined(ZLIB_INCLUDE_DIR)
assert_var_defined(JPEGLIB_INCLUDE_DIR)
assert_var_defined(LIBWEBP_INCLUDE_DIR)
assert_var_defined(LUNASVG_INCLUDE_DIR)
assert_var_defined(ZSTD_INCLUDE_DIR)

include_directories(
    ${JCONFIG_INCLUDE_DIR}
    ${FREETYPE_INCLUDE_DIR}
    ${HARFBUZZ_INCLUDE_DIR}
    ${FRIBIDI_INCLUDE_DIR}
    ${LIBUNIBREAK_INCLUDE_DIR}
    ${UTF8PROC_INCLUDE_DIR}
    ${ANTIWORD_INCLUDE_DIR}
    ${CHM_INCLUDE_DIRS}
    ${PNG_INCLUDE_DIR}
    ${ZLIB_INCLUDE_DIR}
    ${JPEGLIB_INCLUDE_DIR}
    ${LIBWEBP_INCLUDE_DIR}
    ${LUNASVG_INCLUDE_DIR}
    ${ZSTD_INCLUDE_DIR}
    ${SRELL_INCLUDE_DIR}
    ${CREGINE_INCLUDE_DIR}
)

include(CheckTypeSize)

if(DEFINED ENV{LEGACY})
    set(DISABLE_CLOEXEC 1)
else()
    # Test and Enable LFS Support in glibc, based on zlib
    set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE64_SOURCE=1)
    check_type_size(off64_t OFF64_T)
    set(CMAKE_REQUIRED_DEFINITIONS)
endif()

if(${CMAKE_BUILD_TYPE} STREQUAL Debug)
    set(_DEBUG 1)
endif()

configure_file(crsetup.h.cmake crsetup.h)
# Some source files use `#include "crsetup.h"`, others
# `#include "../include/crsetup.h"`, so use the brute
# force approach…
add_definitions(--include "${CMAKE_CURRENT_BINARY_DIR}/crsetup.h")

message("Will build LIBCHM library")
add_subdirectory(${CR_3RDPARTY_DIR}/chmlib)

message("Will build ANTIWORD library")
add_subdirectory(${CR_3RDPARTY_DIR}/antiword)

message("Will build crengine library")
set (CRENGINE_SOURCES
    ${CRE_DIR}/qimagescale/qimagescale.cpp
    ${CRE_DIR}/src/cp_stats.cpp
    ${CRE_DIR}/src/lvstring.cpp
    ${CRE_DIR}/src/props.cpp
    ${CRE_DIR}/src/lstridmap.cpp
    ${CRE_DIR}/src/rtfimp.cpp
    ${CRE_DIR}/src/lvmemman.cpp
    ${CRE_DIR}/src/lvstyles.cpp
    ${CRE_DIR}/src/crtxtenc.cpp
    ${CRE_DIR}/src/lvtinydom.cpp
    ${CRE_DIR}/src/lvstream.cpp
    ${CRE_DIR}/src/lvxml.cpp
    ${CRE_DIR}/src/chmfmt.cpp
    ${CRE_DIR}/src/epubfmt.cpp
    ${CRE_DIR}/src/pdbfmt.cpp
    ${CRE_DIR}/src/wordfmt.cpp
    ${CRE_DIR}/src/lvopc.cpp
    ${CRE_DIR}/src/docxfmt.cpp
    ${CRE_DIR}/src/odtfmt.cpp
    ${CRE_DIR}/src/odxutil.cpp
    ${CRE_DIR}/src/fb3fmt.cpp
    ${CRE_DIR}/src/lvstsheet.cpp
    ${CRE_DIR}/src/txtselector.cpp
    ${CRE_DIR}/src/crtest.cpp
    ${CRE_DIR}/src/lvbmpbuf.cpp
    ${CRE_DIR}/src/lvfnt.cpp
    ${CRE_DIR}/src/hyphman.cpp
    ${CRE_DIR}/src/textlang.cpp
    ${CRE_DIR}/src/lvfntman.cpp
    ${CRE_DIR}/src/lvimg.cpp
    ${CRE_DIR}/src/crskin.cpp
    ${CRE_DIR}/src/lvdrawbuf.cpp
    ${CRE_DIR}/src/lvdocview.cpp
    ${CRE_DIR}/src/lvpagesplitter.cpp
    ${CRE_DIR}/src/lvtextfm.cpp
    ${CRE_DIR}/src/lvrend.cpp
    ${CRE_DIR}/src/mathml.cpp
    ${CRE_DIR}/src/wolutil.cpp
    ${CRE_DIR}/src/hist.cpp
    ${CRE_DIR}/src/cri18n.cpp
    ${CRE_DIR}/src/crconcurrent.cpp
)
add_library(crengine STATIC ${CRENGINE_SOURCES})
# Make sure we get full `constexpr` support.
target_compile_features(crengine PRIVATE cxx_std_17)
set_target_properties(crengine PROPERTIES VISIBILITY_INLINES_HIDDEN TRUE)
