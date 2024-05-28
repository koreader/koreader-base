cmake_minimum_required(VERSION 3.15)
project(zsync2 LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    # CPR need `-pthread`.
    ${CMAKE_CURRENT_SOURCE_DIR}/cpr_need_pthread.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    # Options.
    -DBUILD_CPR_TESTS=FALSE
    -DBUILD_TESTING=FALSE
    -DUSE_SYSTEM_CURL=TRUE
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} zsync2)

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

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/zsync2.git
    d7d6463356fbeb1e97e917d114ff7ea63df2d6df
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)
