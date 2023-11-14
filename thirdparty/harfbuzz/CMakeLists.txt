project(harfbuzz LANGUAGES)

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# No build rpath
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)

# We've apparently hit a weird corner-case w/ XText where GCC/STL atomics *sometimes* horribly blow up on an ARM1136JF-S CPU w/ GCC 7.5...
# c.f., https://github.com/koreader/koreader/issues/5780 & https://github.com/koreader/koreader/issues/6024
# NOTE: Our initial approach was to only disable atomics in a very dirty manner, which only helped with the first issue.
#       This, on the other hand, appears to help with both.
if(LEGACY OR POCKETBOOK)
	# NOTE: This ends up in CPPFLAGS!
	set(HB_CUSTOM_CFG "-DHB_NO_MT")
endif()

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=${HB_CUSTOM_CFG}"
    "FREETYPE_CFLAGS=-I${STAGING_DIR}/freetype/include"
    "FREETYPE_LIBS=-L${STAGING_DIR}/freetype/shared -lfreetype"
    ${SOURCE_DIR}/configure --host=${CHOST}
    --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib
    --enable-shared --disable-static
    --with-freetype
    --without-cairo
    --without-coretext
    --without-directwrite
    --without-glib
    --without-gobject
    --without-graphite2
    --without-icu
    --without-uniscribe
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C src libs)

set(LIB_SPEC harfbuzz VERSION 0)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(
    INSTALL_CMD
    src/.libs/${LIB} ${LIB_SPEC}
)

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM "${SOURCE_DIR}/src"
    *.h hb-cplusplus.hh
)

set(HB_VER 8.3.0)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/harfbuzz/harfbuzz.git
    ${HB_VER}
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libharfbuzz${LIB_EXT}
)
