project(proxy-libintl LANGUAGES)

list(APPEND CFG_CMD COMMAND env
    ${MESON_SETUP} --default-library=static
    "${SOURCE_DIR}"
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

# Install static lib.
append_static_lib_install_command(BUILD_CMD BYPRODUCTS libintl.a intl)

# Install headers.
append_headers_install_command(
    BUILD_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}"
    libintl.h
)

thirdparty_project(
    URL https://github.com/frida/proxy-libintl/archive/refs/tags/0.4.tar.gz
    URL_MD5 7cc93d2fec98a5b9820888135d2e8844
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
