project(tesseract LANGUAGES)

if (ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tesseract-android.patch)
endif()
list(APPEND PATCH_CMD COMMAND ./autogen.sh)
# No stupid build rpaths
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)

if(ANDROID)
    set(CPPFLAGS "-DANDROID=1")
endif()

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "LIBS=-L${STAGING_DIR}/leptonica/shared"
    "LIBLEPT_HEADERSDIR=${STAGING_DIR}/leptonica/include"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
    --disable-graphics
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(LIB_SPEC tesseract VERSION 3)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD api/.libs/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/config_auto.h"
    FROM "${SOURCE_DIR}/api"
    apitypes.h baseapi.h capi.h
    FROM "${SOURCE_DIR}/ccmain"
    ltrresultiterator.h pageiterator.h resultiterator.h thresholder.h
    FROM "${SOURCE_DIR}/ccstruct"
    publictypes.h
    FROM "${SOURCE_DIR}/ccutil"
    host.h platform.h tesscallback.h unichar.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/tesseract-ocr/tesseract.git
    60176fc5ae5e7f6bdef60c926a4b5ea03de2bfa7
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
