cmake_minimum_required(VERSION 3.15)
project(tesseract LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(LEPTONICA_DIR)
assert_var_defined(LEPTONICA_LIB)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

if(ANDROID)
    list(APPEND CMAKE_ARGS "-DANDROID=TRUE")
endif()

list(APPEND CMAKE_ARGS "-DLeptonica_INCLUDE_DIRS=${LEPTONICA_DIR}/include/leptonica")
list(APPEND CMAKE_ARGS "-DLeptonica_LIBRARIES=${LEPTONICA_LIB}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND BUILD_CMD COMMAND mkdir -p "${INSTALL_DIR}/include/tesseract" "${INSTALL_DIR}/lib")
list(APPEND INSTALL_CMD COMMAND sh -c "cp libtesseract.* \"$1\"" -- "${INSTALL_DIR}/lib/")
list(APPEND INSTALL_CMD COMMAND sh -c "cd \"$1\" && shift && cp \"$@\"" -- "${SOURCE_DIR}"
    api/apitypes.h api/baseapi.h api/capi.h
    ccmain/ltrresultiterator.h ccmain/pageiterator.h ccmain/resultiterator.h ccmain/thresholder.h
    ccstruct/publictypes.h
    ccutil/host.h ccutil/platform.h ccutil/tesscallback.h ccutil/unichar.h
    "${INSTALL_DIR}/include/tesseract/"
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
)
