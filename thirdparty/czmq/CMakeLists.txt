project(czmq LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

if(NOT DARWIN)
    # patch: ignore limited broadcast address
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zbeacon.patch)
    # patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/czmq_default_source_define.patch)
endif()

list(APPEND PATCH_CMD COMMAND ./autogen.sh)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    # -Wno-error so we can build on glibc 2.24 in spite of readdir_r
    "CPPFLAGS=-Wno-error"
    czmq_have_asciidoc=no
    czmq_have_xmlto=no
    "ZeroMQ_CFLAGS=-I${STAGING_DIR}/libzmq/include"
    "ZeroMQ_LIBS=-L${STAGING_DIR}/libzmq/shared"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

# Hack to remove hardcoded rpath
list(APPEND CFG_CMD COMMAND ${ISED} "s|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=\"\"|g" libtool)
list(APPEND CFG_CMD COMMAND ${ISED} "s|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g" libtool)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C src)

set(LIB_SPEC czmq VERSION 1)
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
    https://github.com/zeromq/czmq.git
    2a0ddbc4b2dde623220d7f4980ddd60e910cfa78
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
