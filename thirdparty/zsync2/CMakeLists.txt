project(zsync2 LANGUAGES)

# Fix build with old TCs (kindle & pocketbook).
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix-old-tc-build.patch)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

string(APPEND CURL_LIBRARIES
    "${STAGING_DIR}/curl/static/libcurl.a"
    $<SEMICOLON>
    "-L${STAGING_DIR}/openssl/shared"
    $<SEMICOLON>
    "-lcrypto"
    $<SEMICOLON>
    "-lssl"
)
if(NOT DARWIN)
    string(APPEND CURL_LIBRARIES $<SEMICOLON> "-pthread")
    if(NOT ANDROID)
        string(APPEND CURL_LIBRARIES $<SEMICOLON> "-lrt")
    endif()
endif()

# And, finally, the actual zsync2 build options
list(APPEND CMAKE_ARGS "-DBUILD_CPR_TESTS=0")
list(APPEND CMAKE_ARGS "-DCURL_INCLUDE_DIR=${STAGING_DIR}/curl/include$<SEMICOLON>${STAGING_DIR}/zlib/include")
list(APPEND CMAKE_ARGS "-DCURL_LIBRARIES=${CURL_LIBRARIES}")
list(APPEND CMAKE_ARGS "-DCURL_LIBRARY=curl")
list(APPEND CMAKE_ARGS "-DUSE_SYSTEM_CURL=1")

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

# Install executable.
append_install_command(INSTALL_CMD src/zsync2)

# NOTE: We're currently using our own fork instead of upstream's (https://github.com/AppImage/zsync2):
## * Enable range requests optimizations on the CLI
## * Re-implement the -u flag for compatibility w/ the old zsync CLI
## * Minor CLI output cleanup
## * Squish all the warnings
## * Prevent passing a malformed referer URL
## * Don't print seven billion progress bars
## * Rebase against zsync master (c.f., rebase-zsync-libs branch)
## * Rebase against zlib 1.2.11 (c.f., rebase-zlib branch)
## * Workaround potential download loops, like what happened w/ the 2019.12 -> 2020.01 update.
## * Mangle logging to play nice w/ FBInk
## * Plug memory leaks
# c.f., https://github.com/NiLuJe/zsync2 for more details.

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/zsync2.git
    e618d18f6a7cbf350cededa17ddfe8f76bdf0b5c
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
