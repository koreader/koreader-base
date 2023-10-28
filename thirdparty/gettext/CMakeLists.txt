cmake_minimum_required(VERSION 3.5.1)
project(gettext)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(AR)
assert_var_defined(RANLIB)
assert_var_defined(CPPFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBICONV_PREFIX)
assert_var_defined(CHOST_OPTS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# Android doesn't have a decimal_point member in the lconf struct before API 21
if(DEFINED ENV{ANDROID})
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/gettext-0.21-android-pre21-build.patch)
endif()

set(CFG_ENV_VAR "CC=${CC}" "AR=${AR}" "RANLIB=${RANLIB}" "CPPFLAGS=${CPPFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --enable-silent-rules --with-threads=none --disable-acl --disable-curses --disable-openmp --disable-native-java --disable-java)
set(CFG_OPTS ${CFG_OPTS} --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --with-libiconv-prefix=${LIBICONV_PREFIX} --with-included-libunistring --with-included-libxml --with-included-gettext)
set(CFG_OPTS ${CFG_OPTS} --enable-shared=false --enable-static=true ${CHOST_OPTS})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    # Tools? Where we're going we don't need tools.
    list(APPEND CFG_CMD COMMAND ${ISED} "s/^\\(subdirs\\|SUBDIRS\\)\\( = .*\\) gettext-tools$/\\1\\2/" Makefile)
endif()

set(GETTEXT_VER "0.21")
include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://ftpmirror.gnu.org/gettext/gettext-${GETTEXT_VER}.tar.gz
    URL_MD5 28b1cd4c94a74428723ed966c38cf479
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
