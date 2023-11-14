project(lunasvg LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/extended.patch)
list(APPEND PATCH_CMD COMMAND cp -rpv ${CMAKE_CURRENT_SOURCE_DIR}/xtended ${SOURCE_DIR}/)
list(APPEND PATCH_CMD COMMAND mv -v ${SOURCE_DIR}/xtended/xlunasvg.h ${SOURCE_DIR}/include/)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

# Actual LunaSVG build options
list(APPEND CMAKE_ARGS "-DBUILD_SHARED_LIBS=ON")

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

set(LIB_SPEC lunasvg)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM "${SOURCE_DIR}/include"
    lunasvg.h xlunasvg.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/sammycage/lunasvg.git
    59d6f6ba835c1b7c7a0f9d4ea540ec3981777885
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/liblunasvg${LIB_EXT}
)
