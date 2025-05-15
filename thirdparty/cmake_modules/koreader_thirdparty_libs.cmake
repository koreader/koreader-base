include_guard(GLOBAL)

function(declare_dependency NAME)
    cmake_parse_arguments("" "" "" "INCLUDES;MONOLIBTIC;SHARED;STATIC;LIBRARIES" ${ARGN})
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
    if(MONOLIBTIC)
        list(PREPEND _STATIC ${_MONOLIBTIC})
    else()
        list(PREPEND _SHARED ${_MONOLIBTIC})
    endif()
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

# android-luajit-launcher
declare_dependency(android-luajit-launcher::7z MONOLIBTIC 7z LIBRARIES android log)

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
    md4c::html
    srell::srell
    utf8proc::utf8proc
    zlib::z
    zstd::zstd
)
target_compile_options(_crengine__crengine INTERFACE -include ${OUTPUT_DIR}/thirdparty/crengine/build/crsetup.h)
target_include_directories(_crengine__crengine INTERFACE ${THIRDPARTY_DIR}/kpvcrlib/crengine/crengine/include)

# czmq
set(LIBRARIES)
if(NOT APPLE AND NOT ANDROID)
    list(APPEND LIBRARIES rt)
endif()
declare_dependency(czmq::czmq MONOLIBTIC czmq zmq LIBRARIES ${LIBRARIES})

# djvulibre
set(LIBRARIES m pthread stdc++)
if(APPLE)
    list(APPEND LIBRARIES "-framework CoreFoundation")
endif()
declare_dependency(djvulibre::djvulibre MONOLIBTIC jpeg STATIC djvulibre LIBRARIES ${LIBRARIES})

# freetype
declare_dependency(freetype2::freetype INCLUDES freetype2 MONOLIBTIC freetype)

# fribidi
declare_dependency(fribidi::fribidi INCLUDES fribidi MONOLIBTIC fribidi)

# giflib
declare_dependency(giflib::gif MONOLIBTIC gif)

# harfbuzz
declare_dependency(harfbuzz::harfbuzz INCLUDES freetype2 harfbuzz MONOLIBTIC harfbuzz)

# libarchive
declare_dependency(libarchive::libarchive MONOLIBTIC archive)

# leptonica
declare_dependency(leptonica::leptonica INCLUDES leptonica MONOLIBTIC leptonica)

# libjpeg-turbo
declare_dependency(libjpeg-turbo::jpeg MONOLIBTIC jpeg)
declare_dependency(libjpeg-turbo::turbojpeg MONOLIBTIC turbojpeg)

# libk2pdfopt
set(LIBRARIES k2pdfopt)
if(MONOLIBTIC)
    if(ANDROID)
        list(APPEND LIBRARIES cpu_features ndk_compat)
    endif()
    list(APPEND LIBRARIES leptonica tesseract)
endif()
declare_dependency(libk2pdfopt::k2pdfopt INCLUDES k2pdfopt leptonica MONOLIBTIC ${LIBRARIES})

# libpng
declare_dependency(libpng::png16 MONOLIBTIC png16)

# libressl
set(CRYPTO_LIBS)
set(SSL_LIBS)
if(MONOLIBTIC)
    list(APPEND CRYPTO_LIBS pthread)
    list(APPEND SSL_LIBS pthread)
    if(NOT ANDROID)
        list(APPEND CRYPTO_LIBS rt)
        list(APPEND SSL_LIBS rt)
    endif()
endif()
declare_dependency(libressl::crypto MONOLIBTIC crypto LIBRARIES ${CRYPTO_LIBS})
declare_dependency(libressl::ssl MONOLIBTIC ssl LIBRARIES ${SSL_LIBS})

# libunibreak
declare_dependency(libunibreak::unibreak MONOLIBTIC unibreak)

# libwebp
declare_dependency(libwebp::webpdemux MONOLIBTIC webp webpdemux)

# libzmq
set(LIBRARIES)
if(NOT APPLE AND NOT ANDROID)
    list(APPEND LIBRARIES rt)
endif()
if(MONOLIBTIC)
    list(APPEND LIBRARIES pthread)
endif()
declare_dependency(libzmq::zmq MONOLIBTIC zmq LIBRARIES ${LIBRARIES})

# lodepng
declare_dependency(lodepng::lodepng MONOLIBTIC lodepng)

# lpeg
if(MONOLIBTIC)
    declare_dependency(lpeg::lpeg LIBRARIES ${STAGING_DIR}/lib/lpeg.a)
endif()

# lua-rapidjson
if(MONOLIBTIC)
    declare_dependency(lua-rapidjson::rapidjson LIBRARIES ${STAGING_DIR}/lib/rapidjson.a)
endif()

# luajit
if(USE_LUAJIT_LIB)
    declare_dependency(luajit::luajit INCLUDES luajit-2.1 SHARED luajit)
    get_target_property(LUAJIT_LIB luajit::luajit INTERFACE_LINK_LIBRARIES)
else()
    declare_dependency(luajit::luajit INCLUDES luajit-2.1)
    set(LUAJIT_LIB)
endif()
get_target_property(LUAJIT_INC luajit::luajit INTERFACE_INCLUDE_DIRECTORIES)

# luasec
if(MONOLIBTIC)
    declare_dependency(luasec::ssl LIBRARIES ${STAGING_DIR}/lib/ssl.a)
endif()

# luasocket
if(MONOLIBTIC)
    declare_dependency(luasocket::luasocket STATIC luasocket)
    declare_dependency(luasocket::mcore LIBRARIES ${STAGING_DIR}/lib/mcore.a)
    declare_dependency(luasocket::score LIBRARIES ${STAGING_DIR}/lib/score.a)
endif()

# lunasvg
declare_dependency(lunasvg::lunasvg MONOLIBTIC lunasvg)

# md4c
declare_dependency(md4c::html STATIC md4c-html md4c)

# mupdf
set(SYS_LIBS m)
if(ANDROID)
    list(APPEND SYS_LIBS log)
endif()
set(MONO_LIBS archive freetype harfbuzz jpeg webp webpdemux z)
if(ANDROID)
    list(APPEND MONO_LIBS lzma)
endif()
declare_dependency(
    mupdf::mupdf
    MONOLIBTIC ${MONO_LIBS}
    STATIC mupdf mupdf-third aes
    LIBRARIES ${SYS_LIBS}
)

# openlipclua
if(MONOLIBTIC)
    declare_dependency(openlipclua::libopenlipclua SHARED lipc STATIC openlipclua)
endif()

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

# sqlite
declare_dependency(sqlite::sqlite3 MONOLIBTIC sqlite3)

# srell
add_library(srell INTERFACE)
target_include_directories(srell INTERFACE ${THIRDPARTY_DIR}/srell)
add_library(srell::srell ALIAS srell)

# turbo
if(MONOLIBTIC)
    declare_dependency(turbo::tffi_wrap STATIC tffi_wrap)
endif()

# utf8proc
declare_dependency(utf8proc::utf8proc MONOLIBTIC utf8proc)

# zlib
declare_dependency(zlib::z MONOLIBTIC z)

# zstd
declare_dependency(zstd::zstd MONOLIBTIC zstd)
