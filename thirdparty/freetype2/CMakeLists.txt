project(freetype LANGUAGES)

list(APPEND PATCH_CMD COMMAND ./autogen.sh)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib
    --disable-static --enable-shared
    --with-brotli=no
    --with-bzip2=no
    --with-harfbuzz=no
    --with-png=no
    --with-zlib=no
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(LIB_SPEC freetype VERSION 6)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD .libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${SOURCE_DIR}/include/ft2build.h"
)
append_headers_install_command(
    INSTALL_CMD SUBDIR freetype
    "${SOURCE_DIR}/include/freetype/*.h"
)
append_headers_install_command(
    INSTALL_CMD SUBDIR freetype/config
    "${SOURCE_DIR}/include/freetype/config/*.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/freetype2.git
    VER-2-13-2
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libfreetype${LIB_EXT}
)
