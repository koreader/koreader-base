cmake_minimum_required(VERSION 3.5.1)
project(libwebp LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")

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

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_PROGRAM} install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/webmproject/libwebp.git
    v1.3.2
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
