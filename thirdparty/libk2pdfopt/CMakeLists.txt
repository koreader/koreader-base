project(k2pdfopt LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-without-libwebp.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/slightly-less-fuglyness.patch)

list(APPEND PATCH_CMD COMMAND mv tesseract_mod/tesscapi.cpp tesscapi.cpp)
list(APPEND PATCH_CMD COMMAND mv include_mod/tesseract.h tesseract.h)
list(APPEND PATCH_CMD COMMAND sh -c "printf '#pragma once\\n#include <allheaders.h>' >leptonica.h")

if (DARWIN)
    #fix build error due to implicit declarations of function being invalid in C99 under macOS/XCode 12
    set(CFLAGS "${CFLAGS} -Wno-error=implicit-function-declaration")
endif()

set(CPPFLAGS "-I${STAGING_DIR}/leptonica/include -I${STAGING_DIR}/tesseract/include -I.")
set(CFLAGS "${CFLAGS} ${CPPFLAGS}")
set(CXXFLAGS "${CXXFLAGS} ${CPPFLAGS}")

# NOTE: This may be dangerously close to being too long (and as such, is at risk of random failure if your base path is even halfway long-ish)...
# FIXME: Horrible nastiness on *native* builds happens if we set LDFLAGS here...
#        (Namely, one of the libtool linking stage for tesseract fails to pickup the -L flags necessary to find liblept. Cross builds work fine. Yay, libtool).
list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD
    "ANDROID=${ANDROID}" "DARWIN=${DARWIN}" "MOD_INC=." "TESSERACT_MOD=." "TESSCAPI_CFLAGS="
    "LIBS=-L${STAGING_DIR}/leptonica/shared -L${STAGING_DIR}/tesseract/shared -llept -ltesseract"
)

set(LIB_SPEC k2pdfopt VERSION 2)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM "${SOURCE_DIR}"
    *.h k2pdfoptlib/k2pdfopt.h willuslib/willus.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    09f1e011a618c8ec06b4caa67079682119d2aaa7
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libk2pdfopt${LIB_EXT}
)
