# We don't care about tests.
list(APPEND PATCH_CMD COMMAND rm -rf tests)

set(FILTERS lzma1 lzma2 delta)
# if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
#     list(APPEND FILTERS arm64)
# elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
#     list(APPEND FILTERS arm armthumb)
# elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "i686" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
#     list(APPEND FILTERS x86)
# endif()
list(JOIN FILTERS $<SEMICOLON> FILTERS)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DXZ_DOC=FALSE
    # We can't disable the encoder completely,
    # or libarchive' setup will fail to enable
    # LZMA support.
    -DXZ_ENCODERS=${FILTERS}
    -DXZ_MICROLZMA_ENCODER=FALSE
    # Reduce decoder support to the bare minimum
    # needed for use by android-luajit-launcher.
    -DXZ_DECODERS=${FILTERS}
    -DXZ_LZIP_DECODER=FALSE
    -DXZ_MICROLZMA_DECODER=FALSE
    # Disable NLS support.
    -DCMAKE_DISABLE_FIND_PACKAGE_Gettext=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Intl=TRUE
    -DXZ_NLS=FALSE
    # We don't need the tools.
    -DXZ_SANDBOX=no
    -DXZ_TOOL_LZMADEC=FALSE
    -DXZ_TOOL_LZMAINFO=FALSE
    -DXZ_TOOL_XZ=FALSE
    -DXZ_TOOL_XZDEC=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD lzma VERSION 5)
endif()

external_project(
    DOWNLOAD URL cf5e1feb023d22c6bdaa30e84ef3abe3
    https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
