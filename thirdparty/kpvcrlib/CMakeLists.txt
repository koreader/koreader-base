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
assert_var_defined(NANOSVG_INCLUDE_DIR)
assert_var_defined(ZSTD_INCLUDE_DIR)
assert_var_defined(SHARED_STL_LIB)

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
    ${NANOSVG_INCLUDE_DIR}
    ${ZSTD_INCLUDE_DIR}
    ${SRELL_INCLUDE_DIR}
    ${CREGINE_INCLUDE_DIR}
)

if(DEFINED ENV{WIN32})
    add_definitions(-DWIN32=1 -D_WIN32=1 -DQT_GL=1 -DMINGW -DHAVE_BOOLEAN)
else()
    add_definitions(-DLINUX=1 -D_LINUX=1)
endif()

include(CheckTypeSize)

if(DEFINED ENV{LEGACY})
    add_definitions(-DDISABLE_CLOEXEC)
else()
    # Test and Enable LFS Support in glibc, based on zlib
    set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE64_SOURCE=1)
    check_type_size(off64_t OFF64_T)
    if(HAVE_OFF64_T)
        add_definitions(-D_LARGEFILE64_SOURCE=1)
        add_definitions(-DHAVE_STAT64=1)
    endif()
    set(CMAKE_REQUIRED_DEFINITIONS)
endif()

add_definitions(
    -DUSE_FONTCONFIG=0
    -DUSE_FREETYPE=1
    -DUSE_HARFBUZZ=1
    -DUSE_FRIBIDI=1
    -DUSE_LIBUNIBREAK=1
    -DUSE_UTF8PROC=1
    -DUSE_NANOSVG=1
    -DUSE_LIBWEBP=1
    -DUSE_ZSTD=1
    -DUSE_SRELL_REGEX=1
    -DALLOW_KERNING=1
    -DCR3_PATCH=1
    -DMATHML_SUPPORT=1
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
    find_library(ZSTD NAMES "zstd" PATHS $ENV{LIBS_DIR})
    find_library(PNG_LIB NAMES "png16-16" PATHS $ENV{LIBS_DIR})
    find_library(FREETYPE_LIB NAMES "freetype-6" PATHS $ENV{LIBS_DIR})
    find_library(HARFBUZZ_LIB NAMES "harfbuzz-0" PATHS $ENV{LIBS_DIR})
    find_library(FRIBIDI_LIB NAMES "fribidi-0" PATHS $ENV{LIBS_DIR})
    find_library(LIBUNIBREAK_LIB NAMES "libunibreak-3" PATHS $ENV{LIBS_DIR})
    find_library(UTF8PROC_LIB NAMES "utf8proc-2" PATHS $ENV{LIBS_DIR})
    find_library(JPEG_LIB NAMES "jpeg-8" PATHS $ENV{LIBS_DIR})
    find_library(LIBWEBP_LIB NAMES "webp-7" PATHS $ENV{LIBS_DIR})
    find_library(LIBWEBPDEMUX_LIB NAMES "webpdemux-2" PATHS $ENV{LIBS_DIR})
    set(THIRDPARTY_LIBS ${ZLIB} ${ZSTD} ${FREETYPE_LIB} ${HARFBUZZ_LIB} ${FRIBIDI_LIB} ${LIBUNIBREAK_LIB} ${UTF8PROC_LIB} ${JPEG_LIB} ${PNG_LIB} ${LIBWEBP_LIB} ${LIBWEBPDEMUX_LIB})
else()
    add_library(PNG_LIB SHARED IMPORTED)
    set_target_properties(PNG_LIB PROPERTIES IMPORTED_LOCATION $ENV{PNG_LIB})
    add_library(FREETYPE_LIB SHARED IMPORTED)
    set_target_properties(FREETYPE_LIB PROPERTIES IMPORTED_LOCATION $ENV{FREETYPE_LIB})
    add_library(HARFBUZZ_LIB SHARED IMPORTED)
    set_target_properties(HARFBUZZ_LIB PROPERTIES IMPORTED_LOCATION $ENV{HARFBUZZ_LIB})
    add_library(FRIBIDI_LIB SHARED IMPORTED)
    set_target_properties(FRIBIDI_LIB PROPERTIES IMPORTED_LOCATION $ENV{FRIBIDI_LIB})
    add_library(LIBUNIBREAK_LIB SHARED IMPORTED)
    set_target_properties(LIBUNIBREAK_LIB PROPERTIES IMPORTED_LOCATION $ENV{LIBUNIBREAK_LIB})
    add_library(UTF8PROC_LIB SHARED IMPORTED)
    set_target_properties(UTF8PROC_LIB PROPERTIES IMPORTED_LOCATION $ENV{UTF8PROC_LIB})
    add_library(JPEG_LIB SHARED IMPORTED)
    set_target_properties(JPEG_LIB PROPERTIES IMPORTED_LOCATION $ENV{JPEG_LIB})
    add_library(LIBWEBP_LIB SHARED IMPORTED)
    set_target_properties(LIBWEBP_LIB PROPERTIES IMPORTED_LOCATION $ENV{LIBWEBP_LIB})
    add_library(LIBWEBPDEMUX_LIB SHARED IMPORTED)
    set_target_properties(LIBWEBPDEMUX_LIB PROPERTIES IMPORTED_LOCATION $ENV{LIBWEBPDEMUX_LIB})
    add_library(ZLIB SHARED IMPORTED)
    set_target_properties(ZLIB PROPERTIES IMPORTED_LOCATION $ENV{ZLIB})
    add_library(ZSTD SHARED IMPORTED)
    set_target_properties(ZSTD PROPERTIES IMPORTED_LOCATION $ENV{ZSTD_LIB})
    set(THIRDPARTY_LIBS ZLIB ZSTD FREETYPE_LIB HARFBUZZ_LIB FRIBIDI_LIB LIBUNIBREAK_LIB UTF8PROC_LIB JPEG_LIB PNG_LIB LIBWEBP_LIB LIBWEBPDEMUX_LIB)
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
add_library(crengine SHARED ${CRENGINE_SOURCES})
# Make sure we'll get C++11 support
target_compile_features(crengine PRIVATE cxx_constexpr)

target_link_libraries(crengine PRIVATE chmlib antiword)
target_link_libraries(crengine PRIVATE ${THIRDPARTY_LIBS})
if(DEFINED ENV{ANDROID})
    target_link_libraries(crengine PRIVATE ${SHARED_STL_LIB})
endif()
