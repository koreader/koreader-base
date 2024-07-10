list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=TRUE
    # Project options.
    # Note: we could build libwebpdecoder.so only, which would be smaller and fine
    # decoding single frame webp images. But it fails on animated webp images, not
    # even rendering the first frame.  We need the regular libraries (`libwebp.so`
    # and `libwebpdemux.so`) to handle them (but we can left out the encoder,
    # `libwebpmux.so`).
    -DWEBP_BUILD_ANIM_UTILS=FALSE
    -DWEBP_BUILD_CWEBP=FALSE
    -DWEBP_BUILD_DWEBP=FALSE
    -DWEBP_BUILD_EXTRAS=FALSE
    -DWEBP_BUILD_GIF2WEBP=FALSE
    -DWEBP_BUILD_IMG2WEBP=FALSE
    -DWEBP_BUILD_LIBWEBPMUX=FALSE
    -DWEBP_BUILD_VWEBP=FALSE
    -DWEBP_BUILD_WEBPINFO=FALSE
    -DWEBP_BUILD_WEBPMUX=FALSE
)

list(APPEND BUILD_CMD COMMAND ${KO_NINJA_RECURSIVE})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD sharpyuv VERSION 0)
append_shared_lib_install_commands(INSTALL_CMD webpdemux VERSION 2)
append_shared_lib_install_commands(INSTALL_CMD webp VERSION 7)

external_project(
    URL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.2.tar.gz
    URL_MD5 34869086761c0e2da6361035f7b64771
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
