project(kpvcrlib)
cmake_minimum_required(VERSION 3.5.1)
enable_language(C CXX ASM)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

set(CMAKE_ASM_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_ASM_COMPILER_ARG1 ${CMAKE_CXX_COMPILER_ARG1})
set(CMAKE_ASM_FLAGS ${CMAKE_CXX_FLAGS})
set(CMAKE_ASM_FLAGS_RELEASE "")

set (CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set (CMAKE_INSTALL_RPATH "$ORIGIN")

set(CR_3RDPARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/crengine/thirdparty)
set(CRE_DIR crengine/crengine)

set(ANTIWORD_INCLUDE_DIR ${CR_3RDPARTY_DIR}/antiword)
set(CHM_INCLUDE_DIRS ${CR_3RDPARTY_DIR}/chmlib/src)
set(CREGINE_INCLUDE_DIR ${CRE_DIR}/include)

assert_var_defined(FREETYPE_INCLUDE_DIR)
assert_var_defined(HARFBUZZ_INCLUDE_DIR)
assert_var_defined(FRIBIDI_INCLUDE_DIR)
assert_var_defined(UTF8PROC_INCLUDE_DIR)
assert_var_defined(JPEGLIB_INCLUDE_DIR)
assert_var_defined(PNG_INCLUDE_DIR)
assert_var_defined(ZLIB_INCLUDE_DIR)
assert_var_defined(JCONFIG_INCLUDE_DIR)

include_directories(
    ${JCONFIG_INCLUDE_DIR}
    ${FREETYPE_INCLUDE_DIR}
    ${HARFBUZZ_INCLUDE_DIR}
    ${FRIBIDI_INCLUDE_DIR}
    ${UTF8PROC_INCLUDE_DIR}
    ${ANTIWORD_INCLUDE_DIR}
    ${CHM_INCLUDE_DIRS}
    ${PNG_INCLUDE_DIR}
    ${ZLIB_INCLUDE_DIR}
    ${JPEGLIB_INCLUDE_DIR}
    ${NANOSVG_INCLUDE_DIR}
    ${CREGINE_INCLUDE_DIR}
)

if(DEFINED ENV{WIN32})
    add_definitions(-DWIN32=1 -D_WIN32=1 -DQT_GL=1 -DMINGW -DHAVE_BOOLEAN)
else()
    add_definitions(-DLINUX=1 -D_LINUX=1)
endif()

add_definitions(
    -DUSE_FONTCONFIG=0
    -DUSE_FREETYPE=1
    -DUSE_HARFBUZZ=1
    -DUSE_FRIBIDI=1
    -DUSE_UTF8PROC=1
    -DALLOW_KERNING=1
    -DCR3_PATCH=1
)

if(${CMAKE_BUILD_TYPE} STREQUAL Debug)
    add_definitions(
        -D_DEBUG=1
        -DDEBUG=1
    )
else()
    add_definitions(
        -DNDEBUG=1
    )
endif()

if(DEFINED ENV{WIN32})
    find_library(ZLIB NAMES "zlib1" PATHS $ENV{LIBS_DIR})
    find_library(PNG_LIB NAMES "png16-16" PATHS $ENV{LIBS_DIR})
    find_library(FREETYPE_LIB NAMES "freetype-6" PATHS $ENV{LIBS_DIR})
    find_library(HARFBUZZ_LIB NAMES "harfbuzz-0" PATHS $ENV{LIBS_DIR})
    find_library(FRIBIDI_LIB NAMES "fribidi-0" PATHS $ENV{LIBS_DIR})
    find_library(UTF8PROC_LIB NAMES "utf8proc-2" PATHS $ENV{LIBS_DIR})
    find_library(JPEG_LIB NAMES "jpeg-8" PATHS $ENV{LIBS_DIR})
    set(THIRDPARTY_LIBS ${ZLIB} ${FREETYPE_LIB} ${HARFBUZZ_LIB} ${FRIBIDI_LIB} ${UTF8PROC_LIB} ${JPEG_LIB} ${PNG_LIB})
else()
    add_library(PNG_LIB SHARED IMPORTED)
    set_target_properties(PNG_LIB PROPERTIES IMPORTED_LOCATION $ENV{PNG_LIB})
    add_library(FREETYPE_LIB SHARED IMPORTED)
    set_target_properties(FREETYPE_LIB PROPERTIES IMPORTED_LOCATION $ENV{FREETYPE_LIB})
    add_library(HARFBUZZ_LIB SHARED IMPORTED)
    set_target_properties(HARFBUZZ_LIB PROPERTIES IMPORTED_LOCATION $ENV{HARFBUZZ_LIB})
    add_library(FRIBIDI_LIB SHARED IMPORTED)
    set_target_properties(FRIBIDI_LIB PROPERTIES IMPORTED_LOCATION $ENV{FRIBIDI_LIB})
    add_library(UTF8PROC_LIB SHARED IMPORTED)
    set_target_properties(UTF8PROC_LIB PROPERTIES IMPORTED_LOCATION $ENV{UTF8PROC_LIB})
    add_library(JPEG_LIB SHARED IMPORTED)
    set_target_properties(JPEG_LIB PROPERTIES IMPORTED_LOCATION $ENV{JPEG_LIB})
    add_library(ZLIB SHARED IMPORTED)
    set_target_properties(ZLIB PROPERTIES IMPORTED_LOCATION $ENV{ZLIB})
    set(THIRDPARTY_LIBS ZLIB FREETYPE_LIB HARFBUZZ_LIB FRIBIDI_LIB UTF8PROC_LIB JPEG_LIB PNG_LIB)
endif()

message("Will build LIBCHM library")
add_definitions(-DCHM_SUPPORT_ENABLED=1)
add_subdirectory(${CR_3RDPARTY_DIR}/chmlib)

message("Will build ANTIWORD library")
add_definitions(-DENABLE_ANTIWORD=1)
add_definitions(-DCR3_ANTIWORD_PATCH=1)
add_subdirectory(${CR_3RDPARTY_DIR}/antiword)

message("Will build crengine library")
add_definitions(-DHAVE_PROTOTYPES)
add_definitions(-DHAVE_UNSIGNED_CHAR)
add_definitions(-DCR_EMULATE_GETTEXT)
# c.f., https://github.com/koreader/crengine/pull/275
add_definitions(-DCR_RENDER_32BPP_RGB_PXFMT)
add_definitions(-Dmain=xxxmain)
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
    ${CRE_DIR}/src/lvstsheet.cpp
    ${CRE_DIR}/src/txtselector.cpp
    ${CRE_DIR}/src/crtest.cpp
    ${CRE_DIR}/src/lvbmpbuf.cpp
    ${CRE_DIR}/src/lvfnt.cpp
    ${CRE_DIR}/src/hyphman.cpp
    ${CRE_DIR}/src/lvfntman.cpp
    ${CRE_DIR}/src/lvimg.cpp
    ${CRE_DIR}/src/crskin.cpp
    ${CRE_DIR}/src/lvdrawbuf.cpp
    ${CRE_DIR}/src/lvdocview.cpp
    ${CRE_DIR}/src/lvpagesplitter.cpp
    ${CRE_DIR}/src/lvtextfm.cpp
    ${CRE_DIR}/src/lvrend.cpp
    ${CRE_DIR}/src/wolutil.cpp
    ${CRE_DIR}/src/hist.cpp
    ${CRE_DIR}/src/cri18n.cpp
    ${CRE_DIR}/src/crconcurrent.cpp
    ${CRE_DIR}/src/xxhash.c
)
add_library(crengine SHARED ${CRENGINE_SOURCES})

target_link_libraries(crengine chmlib antiword ${THIRDPARTY_LIBS})
