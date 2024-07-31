list(APPEND PATCH_FILES
    # We only care about `libglib-2.0.a`.
    glib-libglib-only.patch
    # Android makes Linux syscalls hard to get to... Fix pilfered from Python.
    glib-2.58.2-android-linux-syscalls.patch
    # So we can install development files only.
    fix-install-tags.patch
)
if(LEGACY OR POCKETBOOK)
    # Avoid pulling-in `eventfd@GLIBC_2.7`, `pipe2@GLIBC_2.9` or `mkostemp@GLIBC_2.7`.
    list(APPEND PATCH_FILES no_glibc_2.7_or_above_symbols.patch)
endif()

if(ANDROID OR APPLE)
    set(ICONV gnu)
else()
    set(ICONV libc)
endif()

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=static
    -Dforce_posix_threads=true
    -Diconv=${ICONV}
    -Dinternal_pcre=true
    -Dlibmount=false
    -Dselinux=false
    ${SOURCE_DIR}
)

list(APPEND BUILD_CMD COMMAND ninja glib/libglib-2.0.a)

list(APPEND INSTALL_CMD COMMAND ${MESON_INSTALL} --tags devel)

external_project(
    DOWNLOAD URL 8058c7bde846dcffe5fa453eca366d73
    https://download.gnome.org/sources/glib/2.58/glib-2.58.3.tar.xz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
