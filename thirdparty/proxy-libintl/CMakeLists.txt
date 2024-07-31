project(proxy-libintl LANGUAGES)

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=static
    "${SOURCE_DIR}"
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND BUILD_CMD COMMAND ${MESON_INSTALL})

external_project(
    DOWNLOAD URL 7cc93d2fec98a5b9820888135d2e8844
    https://github.com/frida/proxy-libintl/archive/refs/tags/0.4.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
