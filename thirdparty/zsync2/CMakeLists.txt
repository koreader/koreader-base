cmake_minimum_required(VERSION 3.5.1)
project(zsync2 LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CURL_DIR)
assert_var_defined(CURL_LIB)
assert_var_defined(OPENSSL_DIR)
assert_var_defined(CRYPTO_LIB)
assert_var_defined(SSL_LIB)

# Fix build with old TCs (kindle & pocketbook).
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix-old-tc-build.patch)

# We don't actually install OpenSSL, meaning we can't use OPENSSL_ROOT_DIR to help find_package,
# so CMake needs a push to look for both SSL & Cyrpto components...
#list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/mangle-cpr-openssl-search.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
if(DEFINED ENV{CMAKE_TCF})
    list(APPEND CMAKE_ARGS "$ENV{CMAKE_TCF}")
endif()

# CMake hell.
# We expect lib later on in Makefile.third, even on multilib systems...
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_LIBDIR=lib")
list(APPEND CMAKE_ARGS "-DCMAKE_INSTALL_INCLUDEDIR=include")
list(APPEND CMAKE_ARGS "-DCMAKE_SKIP_RPATH=TRUE")
#list(APPEND CMAKE_ARGS "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON")

# Honor the env, dammit.
list(APPEND CMAKE_ARGS "-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_MODULE_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
list(APPEND CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")

# And, finally, the actual zsync2 build options
list(APPEND CMAKE_ARGS "-DBUILD_TESTING=0")
list(APPEND CMAKE_ARGS "-DBUILD_CPR_TESTS=0")
list(APPEND CMAKE_ARGS "-DUSE_SYSTEM_CURL=1")
list(APPEND CMAKE_ARGS "-DCURL_INCLUDE_DIR=${CURL_DIR}/include")
list(APPEND CMAKE_ARGS "-DCURL_LIBRARY=${CURL_LIB}")
list(APPEND CMAKE_ARGS "-DOPENSSL_INCLUDE_DIR=${OPENSSL_DIR}/include")
list(APPEND CMAKE_ARGS "-DOPENSSL_CRYPTO_LIBRARY=${CRYPTO_LIB}")
list(APPEND CMAKE_ARGS "-DOPENSSL_SSL_LIBRARY=${SSL_LIB}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

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
    b4953c95611d9507bd6c7b94dd8447ae87ead734
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
)
