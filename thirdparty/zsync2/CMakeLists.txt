list(APPEND PATCH_FILES
    # CPR need `-pthread`.
    cpr_need_pthread.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DOPENSSL_USE_STATIC_LIBS=$<BOOL:${MONOLIBTIC}>
    # Options.
    -DBUILD_CPR_TESTS=FALSE
    -DBUILD_TESTING=FALSE
    -DUSE_SYSTEM_CURL=TRUE
)

list(APPEND BUILD_CMD COMMAND ninja zsync2)

append_binary_install_command(INSTALL_CMD src/zsync2)

# NOTE: We're currently using our own fork instead of upstream's (https://github.com/AppImage/zsync2):
## * Enable range requests optimizations on the CLI
## * Re-implement the -u flag for compatibility w/ the old zsync CLI
## * Minor CLI output cleanup
## * Squish all the warnings
## * Prevent passing a malformed referer URL
## * Don't print seven billion progress bars
## * Rebase against zsync master (c.f., rebase-zsync-libs branch)
## * Rebase against zlib 1.3.0.1 (c.f., rebase-zlib branch)
## * Workaround potential download loops, like what happened w/ the 2019.12 -> 2020.01 update.
## * Mangle logging to play nice w/ FBInk
## * Plug memory leaks
# c.f., https://github.com/NiLuJe/zsync2 for more details.

external_project(
    DOWNLOAD GIT e281e1eb4466ff6b3866c25dbe62a3e150fa5bfd
    https://github.com/NiLuJe/zsync2.git
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
