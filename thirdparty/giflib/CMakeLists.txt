project(giflib LANGUAGES)

if(ANDROID)
    # use limits.h instead of stdint.h
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|stdint.h|limits.h|g" ${SOURCE_DIR}/lib/openbsd-reallocarray.c)
endif()
list(APPEND PATCH_CMD COMMAND ${ISED} "s|\\$srcdir/configure \\$\\*||g" autogen.sh)
list(APPEND PATCH_CMD COMMAND ./autogen.sh)

if(ANDROID)
    set(CPPFLAGS "-DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR")
endif()

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=${CPPFLAGS}"
    ac_cv_prog_have_xmlto=no
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

set(LIB_SPEC gif VERSION 7)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD lib/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${SOURCE_DIR}/lib/gif_lib.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/giflib.git
    5.1.4
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
