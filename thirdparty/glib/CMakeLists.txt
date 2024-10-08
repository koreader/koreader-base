list(APPEND PATCH_FILES
    # We only care about `libglib-2.0.a`.
    libglib-only.patch
)
if(LEGACY OR POCKETBOOK)
    # Avoid pulling-in `__sched_cpucount@GLIBC_2.6`, `eventfd@GLIBC_2.7`,
    # `pipe2@GLIBC_2.9` or `mkostemp@GLIBC_2.7`.
    list(APPEND PATCH_FILES no_glibc_2.6_or_above_symbols.patch)
endif()

if(ANDROID OR APPLE)
    set(ICONV gnu)
else()
    set(ICONV libc)
endif()

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=static
    -Dglib_assert=false
    -Dglib_debug=disabled
    -Dtests=false
    -Dxattr=false
    ${SOURCE_DIR}
)

list(APPEND BUILD_CMD COMMAND ninja glib/libglib-2.0.a)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL} --tags devel)
# Don't install the pkg-config entry:
# - sdcv is the only user, and needs to be manually coaxed into using our GLib anyway.
# - when building SDL2 for the AppImage, IBus headers include some GObject headers,
#   which our patched version does not include.
list(APPEND INSTALL_CMD COMMAND rm -f ${STAGING_DIR}/lib/pkgconfig/glib-2.0.pc)

external_project(
    DOWNLOAD URL d101f1acab6805d4d6d3104e9634b8e3
    https://download.gnome.org/sources/glib/2.82/glib-2.82.1.tar.xz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
