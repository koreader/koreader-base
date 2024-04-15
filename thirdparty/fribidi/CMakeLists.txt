cmake_minimum_required(VERSION 3.5.1)
project(fribidi LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

list(APPEND CFG_CMD env
    CC=${CC}
    CFLAGS=${CFLAGS}
    LDFLAGS=${LDFLAGS}
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib install)

external_project(
    URL https://github.com/fribidi/fribidi/releases/download/v1.0.13/fribidi-1.0.13.tar.xz
    URL_MD5 49b17442e0d8fa2e97b5c898078f6f51
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
