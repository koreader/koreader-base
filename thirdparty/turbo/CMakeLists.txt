list(APPEND PATCH_FILES
    # Backport upstream fixes.
    d7a8a247a4a2689b0f207162eb804141c87c4899.patch
    # Make sure turbo use our SSL library.
    fix_ssl_load.patch
    # Make sure turbo find its libtffi_wrap library.
    fix_tffi_wrap_load.patch
    # Drop unused code.
    no_web_api.patch
    no_websocket_api.patch
    no_httpserver_api.patch
    no_tcpserver_api.patch
    no_signal_handler_api.patch
    no_linux_only_apis.patch
    # Only declare the cdefs we need and use our `ffi.posix_h` module.
    fix_cdefs.patch
)

# Drop unused stuff, including the 7 years-old copy of a CA bundle that turbo doesn't actually use..
list(APPEND PATCH_CMD COMMAND rm
    turbo/ca-certificates.crt
    turbo/crypto_linux.lua
    turbo/epoll_ffi.lua
    turbo/fs.lua
    turbo/httpserver.lua
    turbo/inotify.lua
    turbo/mustache.lua
    turbo/signal.lua
    turbo/syscall.lua
    turbo/tcpserver.lua
    turbo/thread.lua
    turbo/web.lua
    turbo/websocket.lua
)
# Some of the LUA files are executables for no good reason.
list(APPEND PATCH_CMD COMMAND sh -c "chmod a-x turbo/*.lua")

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
)

list(APPEND BUILD_CMD COMMAND ninja)

if(MONOLIBTIC)
    append_install_commands(INSTALL_CMD libtffi_wrap.a DESTINATION ${STAGING_DIR}/lib)
else()
    append_binary_install_command(INSTALL_CMD libtffi_wrap${LIB_EXT} DESTINATION libs)
endif()
append_install_commands(INSTALL_CMD ${SOURCE_DIR}/turbo.lua DESTINATION common)
append_tree_install_commands(INSTALL_CMD ${SOURCE_DIR}/turbo common/turbo)

external_project(
    DOWNLOAD GIT v2.1.3
    https://github.com/kernelsauce/turbo
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
