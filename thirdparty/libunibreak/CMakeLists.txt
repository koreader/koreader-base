list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --disable-static --enable-shared
    --enable-silent-rules
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(LIB_SPEC unibreak VERSION 6)
set_libname(LIB ${LIB_SPEC})

if(DARWIN)
    list(APPEND BUILD_CMD COMMAND install_name_tool -id "@rpath/${LIB}" "src/.libs/${LIB}")
endif()

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS src/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/src"
    eastasianwidthdef.h
    graphemebreak.h
    linebreak.h linebreakdef.h
    unibreakbase.h unibreakdef.h
    wordbreak.h
)

thirdparty_project(
    URL https://github.com/adah1972/libunibreak/releases/download/libunibreak_6_1/libunibreak-6.1.tar.gz
    URL_MD5 8df410d010e03de1a339a400a920335e
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
