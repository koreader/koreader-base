list(APPEND PATCH_FILES cmake_tweaks.patch)
if(ANDROID)
    list(APPEND PATCH_FILES android.patch)
endif()

# Pre-emptively remove `src/platform.h`: this is normaly done by
# `CMakeLists.txt` at configure time, and wreaks havoc with `build.d`
# generation. Since the later is done before configuring, a missing
# `src/platform.h` would endlessly trigger a new czmq build.
list(APPEND PATCH_CMD COMMAND rm src/platform.h)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DCZMQ_BUILD_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DCZMQ_BUILD_STATIC=$<BOOL:${MONOLIBTIC}>
    -DENABLE_DRAFTS=FALSE
    # Disable some dependencies (which will automatically
    # disable the corresponding project optional features).
    -DCMAKE_DISABLE_FIND_PACKAGE_libcurl=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_libmicrohttpd=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_lz4=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_nss=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_systemd=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_uuid=TRUE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD czmq VERSION 4)
endif()

external_project(
    DOWNLOAD URL 471e9ec120fc66a2fe2aae14359e3cfa
    https://github.com/zeromq/czmq/releases/download/v4.2.1/czmq-4.2.1.tar.gz
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
