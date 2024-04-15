cmake_minimum_required(VERSION 3.5.1)
project(djvulibre LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Never *ever* call setlocale, for any reason.
# Most of our target platforms have custom/broken/incomplete locales, don't screw with it.
# And this runs in our main thread, so this is Very Bad(TM).
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/djvulibre-no-locale-mangling.patch)

if(DEFINED ENV{ANDROID})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/android.patch)
endif()

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# fix build error due to -Werror under Fedora 26 (and potentially other systems)
string(APPEND CFLAGS " -Wno-error")
# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
string(APPEND CXXFLAGS " -Wno-register -Wno-error=register")

list(APPEND CFG_CMD COMMAND env
    CC=${CC}
    CXX=${CXX}
    CFLAGS=${CFLAGS}
    CXXFLAGS=${CXXFLAGS}
    LDFLAGS=${LDFLAGS}
    ./configure --host=${CHOST}
    --disable-static --enable-shared
    --disable-desktopfiles
    --disable-largefile
    --disable-xmltools
    --without-jpeg
    --without-tiff
)

if(DEFINED ENV{ANDROID})
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
    # Technically we don't need tools on any platform but they only cause issues on Android
    list(APPEND CFG_CMD COMMAND ${ISED} "s|DIST_SUBDIRS = libdjvu.*|DIST_SUBDIRS = libdjvu|g" Makefile)
    list(APPEND CFG_CMD COMMAND ${ISED} "s|SUBDIRS = libdjvu tools share \\$(am__append_1) \\$(am__append_2)|SUBDIRS = libdjvu share \\$(am__append_1) \\$(am__append_2)|g" Makefile)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} SUBDIRS_FIRST=libdjvu)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/djvulibre.git
    6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
