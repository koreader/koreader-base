list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# Note: we could build libwebpdecoder.so only, which would be smaller and fine
# decoding single frame webp images. But it fails on animated webp images, not
# even rendering the first frame.  We need the regular libraries (`libwebp.so`
# and `libwebpdemux.so`) to handle them (but we can left out the encoder,
# `libwebpmux.so`).
list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=TRUE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_ANIM_UTILS=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_CWEBP=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_DWEBP=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_EXTRAS=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_GIF2WEBP=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_IMG2WEBP=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_LIBWEBPMUX=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_VWEBP=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_WEBPINFO=FALSE")
list(APPEND CMAKE_ARGS "-DWEBP_BUILD_WEBPMUX=FALSE")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(SHARPYUV_LIB_SPEC sharpyuv VERSION 0)
set(WEBPDEMUX_LIB_SPEC webpdemux VERSION 2)
set(WEBP_LIB_SPEC webp VERSION 7)
set_libname(SHARPYUV_LIB ${SHARPYUV_LIB_SPEC})
set_libname(WEBPDEMUX_LIB ${WEBPDEMUX_LIB_SPEC})
set_libname(WEBP_LIB ${WEBP_LIB_SPEC})

# Install shared libs.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${SHARPYUV_LIB} ${SHARPYUV_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${WEBPDEMUX_LIB} ${WEBPDEMUX_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${WEBP_LIB} ${WEBP_LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR webp
    FROM "${SOURCE_DIR}/src/webp"
    decode.h demux.h mux_types.h types.h
)

thirdparty_project(
    URL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.2.tar.gz
    URL_MD5 34869086761c0e2da6361035f7b64771
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
