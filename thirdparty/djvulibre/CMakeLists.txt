project(djvulibre LANGUAGES)

# Never *ever* call setlocale, for any reason.
# Most of our target platforms have custom/broken/incomplete locales, don't screw with it.
# And this runs in our main thread, so this is Very Bad(TM).
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/djvulibre-no-locale-mangling.patch)

if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/android.patch)
endif()

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# fix build error due to -Werror under Fedora 26 (and potentially other systems)
set(CFLAGS "${CFLAGS} -Wno-error")
# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
set(CXXFLAGS "${CXXFLAGS} -Wno-register -Wno-error=register")

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
    --disable-desktopfiles
    --disable-largefile
    --disable-xmltools
    --without-jpeg
    --without-tiff
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
    # Technically we don't need tools on any platform but they only cause issues on Android
    list(APPEND CFG_CMD COMMAND ${ISED} "s|DIST_SUBDIRS = libdjvu.*|DIST_SUBDIRS = libdjvu|g" Makefile)
    list(APPEND CFG_CMD COMMAND ${ISED} "s|SUBDIRS = libdjvu tools share \\$(am__append_1) \\$(am__append_2)|SUBDIRS = libdjvu share \\$(am__append_1) \\$(am__append_2)|g" Makefile)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C libdjvu)

set(LIB_SPEC djvulibre VERSION 21)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD libdjvu/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    SUBDIR libdjvu
    FROM "${SOURCE_DIR}/libdjvu"
    ddjvuapi.h miniexp.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/djvulibre.git
    6a1e5ba1c9ef81c205a4b270c3f121a1e106f4fc
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libdjvulibre${LIB_EXT}
)
