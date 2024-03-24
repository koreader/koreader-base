list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

if(ANDROID)
    list(APPEND CMAKE_ARGS "-DANDROID=TRUE")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC tesseract VERSION 3)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR tesseract
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
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
