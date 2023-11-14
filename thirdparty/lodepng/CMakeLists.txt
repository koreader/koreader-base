project(lodepng LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E copy lodepng.cpp lodepng.c)

set(LIB_SPEC lodepng)
set_libname(LIB ${LIB_SPEC})

if (NOT APPLE)
    set(LDFLAGS "${LDFLAGS} -Wl,-E -Wl,-soname=${LIB}")
endif()

list(APPEND BUILD_CMD COMMAND sh -c "test lodepng.c -ot ${LIB} || ${CC} -shared ${CFLAGS} ${LDFLAGS} ${DYN_LDFLAGS} lodepng.c -o ${LIB}")

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD ${LIB} ${LIB_SPEC})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lvandeve/lodepng.git
    c18b949b71f45e78b1f9a28c5d458bce0da505d6
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
