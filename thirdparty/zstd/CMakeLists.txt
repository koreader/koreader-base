project(zstd LANGUAGES)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

list(APPEND CMAKE_ARGS "-DZSTD_BUILD_PROGRAMS=FALSE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_SHARED=TRUE")
list(APPEND CMAKE_ARGS "-DZSTD_BUILD_STATIC=FALSE")

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

set(LIB_SPEC zstd VERSION 1)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD lib/${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM "${SOURCE_DIR}/lib"
    zdict.h zstd.h zstd_errors.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/facebook/zstd.git
    tags/v1.5.5
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${STAGING_DIR}/${PROJECT_NAME}/shared/libzstd${LIB_EXT}
)
