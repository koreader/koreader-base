project(fribidi LANGUAGES)

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib
    --disable-static --enable-shared
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

# Disable building docs, as it requires c2man
list(APPEND CFG_CMD COMMAND ${ISED} "s|SUBDIRS = gen.tab lib bin doc test|SUBDIRS = gen.tab lib bin test|g" Makefile)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib fribidi-unicode-version.h)
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

set(LIB_SPEC fribidi VERSION 0)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD lib/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/lib/*.h"
    "${SOURCE_DIR}/lib/*.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/fribidi/fribidi.git
    tags/v1.0.12
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libfribidi${LIB_EXT}
)
