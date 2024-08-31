# Never *ever* call setlocale, for any reason.
# Most of our target platforms have custom/broken/incomplete locales, don't screw with it.
# And this runs in our main thread, so this is Very Bad(TM).
list(APPEND PATCH_FILES djvulibre-no-locale-mangling.patch)
# Remove references to (build specific) install directory in binary.
list(APPEND PATCH_FILES no_references_to_install_dir.patch)

if(ANDROID)
    list(APPEND PATCH_FILES android.patch)
endif()

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# fix build error due to -Werror under Fedora 26 (and potentially other systems)
string(APPEND CFLAGS " -Wno-error")
# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
string(APPEND CXXFLAGS " -Wno-register -Wno-error=register")
# Fix symbols visibility.
string(APPEND CFLAGS " -fvisibility=hidden")
string(APPEND CXXFLAGS " -fvisibility=hidden -fvisibility-inlines-hidden")

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=/
    --disable-shared --enable-static
    --disable-desktopfiles
    --disable-largefile
    --disable-xmltools
    --with-jpeg=${STAGING_DIR}
    --without-tiff
)

list(APPEND BUILD_CMD COMMAND make -C libdjvu)

list(APPEND INSTALL_CMD COMMAND make -C libdjvu DESTDIR=${STAGING_DIR} install)

external_project(
    DOWNLOAD GIT 6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc
    https://gitlab.com/koreader/djvulibre.git
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
