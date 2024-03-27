list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/extended.patch)
list(APPEND PATCH_CMD COMMAND cp -rpv ${CMAKE_CURRENT_SOURCE_DIR}/xtended ${SOURCE_DIR}/)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# Actual LunaSVG build options.
list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=ON")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC lunasvg)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    "${SOURCE_DIR}/include/lunasvg.h"
    "${SOURCE_DIR}/xtended/xlunasvg.h"
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/sammycage/lunasvg.git
    59d6f6ba835c1b7c7a0f9d4ea540ec3981777885
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
