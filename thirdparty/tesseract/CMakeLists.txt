cmake_minimum_required(VERSION 3.5.1)
project(tesseract LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(LEPTONICA_DIR)
assert_var_defined(LEPTONICA_LIB)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/k2pdfopt.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    # Project options.
    -DANDROID=$ENV{ANDROID}
    -DLeptonica_INCLUDE_DIRS=${LEPTONICA_DIR}/include/leptonica
    -DLeptonica_LIBRARIES=${LEPTONICA_LIB}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install . --verbose)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/tesseract-ocr/tesseract.git
    60176fc5ae5e7f6bdef60c926a4b5ea03de2bfa7
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
