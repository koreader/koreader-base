list(APPEND PATCH_FILES cmake_tweaks.patch)
if(LEGACY OR POCKETBOOK)
    list(APPEND PATCH_FILES disable_eventfd.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DBUILD_SHARED=$<NOT:$<BOOL:${MONOLIBTIC}>>
    -DBUILD_STATIC=$<BOOL:${MONOLIBTIC}>
    -DENABLE_DRAFTS=FALSE
    -DWITH_DOC=FALSE
    -DWITH_LIBBSD=FALSE
    -DZMQ_BUILD_FRAMEWORK=FALSE
    -DZMQ_BUILD_TESTS=FALSE
    # Disable some dependencies (which will automatically
    # disable the corresponding project optional features).
    -DCMAKE_DISABLE_FIND_PACKAGE_AsciiDoc=TRUE
)
if(LEGACY OR POCKETBOOK)
    list(APPEND CMAKE_ARGS -DPOLLER=epoll)
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD zmq VERSION 5)
endif()

external_project(
    DOWNLOAD URL ae933b1e98411fd7cb8309f9502d2737
    https://github.com/zeromq/libzmq/releases/download/v4.3.5/zeromq-4.3.5.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
