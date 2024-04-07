cmake_minimum_required(VERSION 3.5.1)
project(djvulibre LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

ep_get_source_dir(SOURCE_DIR)

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# Never *ever* call setlocale, for any reason.
# Most of our target platforms have custom/broken/incomplete locales, don't screw with it.
# And this runs in our main thread, so this is Very Bad(TM).
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/djvulibre-no-locale-mangling.patch)

if(DEFINED ENV{ANDROID})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/android.patch)
endif()

# fix build error due to -Werror under Fedora 26 (and potentially other systems)
set(CFLAGS "${CFLAGS} -Wno-error")

# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
set(CXXFLAGS "${CXXFLAGS} -Wno-register -Wno-error=register")

set(CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --disable-desktopfiles --disable-static --enable-shared --disable-xmltools --disable-largefile --without-jpeg --without-tiff -host=${CHOST})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

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

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
