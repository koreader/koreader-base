include_guard(GLOBAL)

function(declare_dependency NAME)
    cmake_parse_arguments("" "" "" "INCLUDES;SHARED;STATIC;LIBRARIES" ${ARGN})
    string(REPLACE ":" "_" TGT _${NAME})
    add_library(${TGT} INTERFACE)
    set(INCS)
    if(DEFINED _INCLUDES)
        foreach(DIR IN LISTS _INCLUDES)
            list(APPEND INCS ${STAGING_DIR}/include/${DIR})
        endforeach()
    else()
        list(APPEND INCS ${STAGING_DIR}/include)
    endif()
    set(LIBS)
    foreach(SUBDEP IN LISTS _STATIC)
        list(APPEND LIBS ${STAGING_DIR}/lib/lib${SUBDEP}.a)
    endforeach()
    foreach(SUBDEP IN LISTS _SHARED)
        list(APPEND LIBS ${STAGING_DIR}/lib/lib${SUBDEP}${LIB_EXT})
    endforeach()
    list(APPEND LIBS ${_LIBRARIES})
    target_include_directories(${TGT} INTERFACE ${INCS})
    target_link_libraries(${TGT} INTERFACE ${LIBS})
    add_library(${NAME} ALIAS ${TGT})
endfunction()

# crengine
declare_dependency(crengine::crengine)
target_link_libraries(
    _crengine__crengine
    INTERFACE
    ${OUTPUT_DIR}/thirdparty/crengine/build/libcrengine.a
    ${OUTPUT_DIR}/thirdparty/crengine/build/crengine/thirdparty/antiword/libantiword.a
    ${OUTPUT_DIR}/thirdparty/crengine/build/crengine/thirdparty/chmlib/libchmlib.a
    freetype2::freetype
    harfbuzz::harfbuzz
    libunibreak::unibreak
    fribidi::fribidi
    libjpeg-turbo::jpeg
    libpng::png16
    libwebp::webpdemux
    lunasvg::lunasvg
    srell::srell
    utf8proc::utf8proc
    zlib::z
    zstd::zstd
)
target_compile_options(_crengine__crengine INTERFACE -include ${OUTPUT_DIR}/thirdparty/crengine/build/crsetup.h)
target_include_directories(_crengine__crengine INTERFACE ${THIRDPARTY_DIR}/kpvcrlib/crengine/crengine/include)

# djvulibre
declare_dependency(djvulibre::djvulibre SHARED jpeg STATIC djvulibre LIBRARIES m)

# freetype
declare_dependency(freetype2::freetype INCLUDES freetype2 SHARED freetype)

# fribidi
declare_dependency(fribidi::fribidi INCLUDES fribidi SHARED fribidi)

# harfbuzz
declare_dependency(harfbuzz::harfbuzz INCLUDES freetype2 harfbuzz SHARED harfbuzz)

# libjpeg-turbo
declare_dependency(libjpeg-turbo::jpeg SHARED jpeg)

# libk2pdfopt
declare_dependency(libk2pdfopt::k2pdfopt INCLUDES k2pdfopt leptonica SHARED k2pdfopt)

# libpng
declare_dependency(libpng::png16 SHARED png16)

# libunibreak
declare_dependency(libunibreak::unibreak SHARED unibreak)

# libwebp
declare_dependency(libwebp::webpdemux SHARED webp webpdemux)

# luajit
if(USE_LUAJIT_LIB)
    declare_dependency(luajit::luajit INCLUDES luajit-2.1 SHARED luajit)
    get_target_property(LUAJIT_LIB luajit::luajit INTERFACE_LINK_LIBRARIES)
else()
    declare_dependency(luajit::luajit INCLUDES luajit-2.1)
    set(LUAJIT_LIB)
endif()
get_target_property(LUAJIT_INC luajit::luajit INTERFACE_INCLUDE_DIRECTORIES)

# lunasvg
declare_dependency(lunasvg::lunasvg SHARED lunasvg)

# mupdf
set(LIBRARIES m)
if(ANDROID)
    list(APPEND LIBRARIES log)
endif()
declare_dependency(
    mupdf::mupdf
    SHARED freetype harfbuzz jpeg webp webpdemux z
    STATIC mupdf mupdf-third aes
    LIBRARIES ${LIBRARIES}
)

# nanosvg
declare_dependency(nanosvg::nanosvg LIBRARIES m)

# popen-noshell
declare_dependency(popen-noshell::popen-noshell STATIC popen_noshell)

# pthread
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)
if(NOT Threads_FOUND OR NOT CMAKE_USE_PTHREADS_INIT)
    message(FATAL_ERROR "pthread library not found!")
endif()
add_library(pthread INTERFACE)
target_link_libraries(pthread INTERFACE Threads::Threads)

# srell
add_library(srell INTERFACE)
target_include_directories(srell INTERFACE ${THIRDPARTY_DIR}/srell)
add_library(srell::srell ALIAS srell)

# utf8proc
declare_dependency(utf8proc::utf8proc SHARED utf8proc)

# zlib
declare_dependency(zlib::z SHARED z)

# zstd
declare_dependency(zstd::zstd SHARED zstd)
