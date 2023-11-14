project(libzmq LANGUAGES)

list(APPEND PATCH_CMD COMMAND ./autogen.sh)
# Force dynamic lib version.
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-avoid-version||g" src/Makefile.am)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    # Ignore sodium_init() warning.
    "CPPFLAGS=-Wno-unused-result"
    libzmq_have_xmlto=no libzmq_have_asciidoc=no
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
    --without-documentation
)
if(LEGACY OR POCKETBOOK)
    list(APPEND CFG_CMD --disable-eventfd)
endif()

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C src)

set(LIB_SPEC zmq VERSION 4)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD "src/.libs/${LIB}" ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${SOURCE_DIR}/include/*.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/libzmq
    883e95b22e0bffffa72312ea1fec76199afbe458
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
