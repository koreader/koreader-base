project(libunibreak LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/add_lb_get_char_class.patch)
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

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(LIB_SPEC unibreak VERSION 5)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD src/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM "${SOURCE_DIR}/src"
    *base.h *break.h *def.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/adah1972/libunibreak.git
    tags/libunibreak_5_1
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libunibreak${LIB_EXT}
)
