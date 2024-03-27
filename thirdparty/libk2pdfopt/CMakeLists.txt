list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix_willuslib_platform_checks.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/reproducible-builds.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/slightly-less-fuglyness.patch)
list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/build.cmake CMakeLists.txt)
list(APPEND PATCH_CMD COMMAND mv tesseract_mod/tesscapi.cpp tesscapi.cpp)
list(APPEND PATCH_CMD COMMAND mv include_mod/tesseract.h tesseract.h)
list(APPEND PATCH_CMD COMMAND sh -c "printf '#pragma once\\n#include <allheaders.h>' >leptonica.h")

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC k2pdfopt VERSION 2)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}"
    context.h koptcrop.h koptimize.h koptocr.h koptreflow.h leptonica.h setting.h
    tesseract.h k2pdfoptlib/k2pdfopt.h willuslib/willus.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/libk2pdfopt.git
    47caea57aaf6200fc2b24669b6417fe6919926b7
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
