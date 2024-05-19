cmake_minimum_required(VERSION 3.5.1)
project(libk2pdfopt LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(AR)
assert_var_defined(LDFLAGS)
assert_var_defined(ZLIB)
assert_var_defined(ZLIB_DIR)
assert_var_defined(PNG_DIR)
assert_var_defined(LEPTONICA_DIR)
assert_var_defined(TESSERACT_DIR)
assert_var_defined(K2PDFOPT_DIR)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

if (DEFINED ENV{DARWIN})
    #fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12
    set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")
endif()

# Fix build error when compiling with -std=gnu++17: ISO
# C++17 does not allow 'register' storage class specifier.
set(CXXFLAGS "${CXXFLAGS} -Wno-register -Wno-error=register")

# NOTE: This may be dangerously close to being too long (and as such, is at risk of random failure if your base path is even halfway long-ish)...
# FIXME: Horrible nastiness on *native* builds happens if we set LDFLAGS here...
#        (Namely, one of the libtool linking stage for tesseract fails to pickup the -L flags necessary to find liblept. Cross builds work fine. Yay, libtool).
set(BUILD_CMD ${KO_MAKE_RECURSIVE} BUILDMODE=shared HOST=${HOST} CC=${CC} "CFLAGS=${CFLAGS}")
set(BUILD_CMD ${BUILD_CMD} CXX=${CXX} "CXXFLAGS=${CXXFLAGS}" AR=${AR} RANLIB=${RANLIB} ZLIB=${ZLIB})
set(BUILD_CMD ${BUILD_CMD} TESSERACT_DIR=${TESSERACT_DIR} LEPTONICA_DIR=${LEPTONICA_DIR} K2PDFOPT_DIR=${K2PDFOPT_DIR})
set(BUILD_CMD ${BUILD_CMD} "LEPT_CFLAGS=-I${ZLIB_DIR}/include -I${PNG_DIR}/include")
set(BUILD_CMD ${BUILD_CMD} "LEPT_LDFLAGS=-L${K2PDFOPT_DIR} -lpng -lz")
set(BUILD_CMD ${BUILD_CMD} "ZLIB_LDFLAGS=-L${ZLIB_DIR}/lib")
set(BUILD_CMD ${BUILD_CMD} "PNG_LDFLAGS=-L${PNG_DIR}/lib" all)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    fe43507c637e348292345a753dbc421c6f14938c
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
)
