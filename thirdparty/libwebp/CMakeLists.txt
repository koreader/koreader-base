project(libwebp LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/trim-the-fat.patch)
list(APPEND PATCH_CMD COMMAND ./autogen.sh)

# No build rpath
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)

# Note: with "--disable-libwebpmux --disable-libwebpdemux --enable-libwebpdecoder", we could
# build libwebpdecoder.so only, which would be smaller and fine decoding single frame webp
# images. But it fails on animated webp images, not even rendering the first frame.
# We need the regular libraries (libwebp.so and libwebpdemux.so) to handle them
# (but we can left out the encoder, libwebpmux.so).
list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST}
    --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib
    --disable-static --enable-shared
    --disable-gif
    --disable-gl
    --disable-jpeg
    --disable-libwebpmux
    --disable-png
    --disable-sdl
    --disable-tiff
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(SHARPYUV_LIB_SPEC sharpyuv VERSION 0)
set(WEBPDEMUX_LIB_SPEC webpdemux VERSION 2)
set(WEBP_LIB_SPEC webp VERSION 7)
set_libname(SHARPYUV_LIB ${SHARPYUV_LIB_SPEC})
set_libname(WEBPDEMUX_LIB ${WEBPDEMUX_LIB_SPEC})
set_libname(WEBP_LIB ${WEBP_LIB_SPEC})

# Install shared libs.
append_shared_lib_install_command(INSTALL_CMD sharpyuv/.libs/${SHARPYUV_LIB} ${SHARPYUV_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD src/demux/.libs/${WEBPDEMUX_LIB} ${WEBPDEMUX_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD src/.libs/${WEBP_LIB} ${WEBP_LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    SUBDIR webp
    FROM "${SOURCE_DIR}/src/webp"
    decode.h demux.h mux_types.h types.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/webmproject/libwebp.git
    v1.3.2
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS
    ${STAGING_DIR}/${PROJECT_NAME}/shared/libwebp${LIB_EXT}
    ${STAGING_DIR}/${PROJECT_NAME}/shared/libwebpdemux${LIB_EXT}
)
