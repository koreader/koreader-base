cmake_minimum_required(VERSION 3.5.1)
project(kpvcrlib LANGUAGES C CXX)

include(koreader_thirdparty_common)

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

set(CRE_3RDPARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/crengine/thirdparty)
set(CRE_DIR crengine/crengine)

include(CheckTypeSize)

if(LEGACY)
    set(DISABLE_CLOEXEC 1)
else()
    # Test and Enable LFS Support in glibc, based on zlib
    set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE64_SOURCE=1)
    check_type_size(off64_t OFF64_T)
    set(CMAKE_REQUIRED_DEFINITIONS)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(_DEBUG 1)
endif()

add_subdirectory(${CRE_3RDPARTY_DIR}/chmlib)

add_subdirectory(${CRE_3RDPARTY_DIR}/antiword)

add_library(crengine STATIC
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
    ${CRE_DIR}/src/lvfnt.cpp
    ${CRE_DIR}/src/hyphman.cpp
    ${CRE_DIR}/src/textlang.cpp
    ${CRE_DIR}/src/lvfntman.cpp
    ${CRE_DIR}/src/lvimg.cpp
    ${CRE_DIR}/src/lvdrawbuf.cpp
    ${CRE_DIR}/src/lvdocview.cpp
    ${CRE_DIR}/src/lvpagesplitter.cpp
    ${CRE_DIR}/src/lvtextfm.cpp
    ${CRE_DIR}/src/lvrend.cpp
    ${CRE_DIR}/src/mathml.cpp
    ${CRE_DIR}/src/hist.cpp
    ${CRE_DIR}/src/cri18n.cpp
    ${CRE_DIR}/src/crconcurrent.cpp
)
# Make sure we get full `constexpr` support.
target_compile_features(crengine PRIVATE cxx_std_17)
set_target_properties(crengine PROPERTIES VISIBILITY_INLINES_HIDDEN TRUE)
target_include_directories(crengine PUBLIC
    ${CRE_DIR}/include
    ${FREETYPE_INCLUDE_DIR}
    ${HARFBUZZ_INCLUDE_DIR}
    ${LIBUNIBREAK_INCLUDE_DIR}
)
target_include_directories(crengine PRIVATE
    ${CRE_3RDPARTY_DIR}/antiword
    ${CRE_3RDPARTY_DIR}/chmlib/src
    ${FRIBIDI_INCLUDE_DIR}
    ${JPEGLIB_INCLUDE_DIR}
    ${LIBWEBP_INCLUDE_DIR}
    ${LUNASVG_INCLUDE_DIR}
    ${PNG_INCLUDE_DIR}
    ${SRELL_INCLUDE_DIR}
    ${UTF8PROC_INCLUDE_DIR}
    ${ZLIB_INCLUDE_DIR}
    ${ZSTD_INCLUDE_DIR}
)

configure_file(crsetup.h.cmake crsetup.h)
# Some source files use `#include "crsetup.h"`, others
# `#include "../include/crsetup.h"`, so use the brute
# force approach…
foreach(LIB antiword chmlib crengine)
    target_compile_options(${LIB} PUBLIC -include ${CMAKE_CURRENT_BINARY_DIR}/crsetup.h)
endforeach()
