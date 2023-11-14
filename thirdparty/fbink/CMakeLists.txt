project(fbink LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix_toolchain_vars_forwarding.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/better_outdir.patch)

# Choose your own adventure!
if(LEGACY)
    set(FBINK_TARGET legacy)
elseif(KINDLE)
    set(FBINK_TARGET kindle)
elseif(CERVANTES)
    set(FBINK_TARGET cervantes)
elseif(KOBO)
    set(FBINK_TARGET strip KOBO=1)
    set(FBDEPTH_TARGET fbdepth KOBO=1)
elseif(REMARKABLE)
    set(FBINK_TARGET remarkable)
    set(FBDEPTH_TARGET fbdepth REMARKABLE=1)
elseif(POCKETBOOK)
    set(FBINK_TARGET pocketbook)
    set(FBDEPTH_TARGET fbdepth POCKETBOOK=1)
else()
    set(FBINK_TARGET strip)
endif()

# FBDepth can afford to link to a very minimal library, so we need to start from scratch...
if(FBDEPTH_TARGET)
    list(APPEND BUILD_CMD COMMAND env)
    append_autotools_vars(BUILD_CMD)
    list(APPEND BUILD_CMD ${KO_MAKE_RECURSIVE} -C "${SOURCE_DIR}"
        "OUT_DIR=${BINARY_DIR}/fbdepth" ${FBDEPTH_TARGET})
endif()

# Minimal-ish, statically linked build, we don't care about image support
list(APPEND BUILD_CMD COMMAND env)
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD ${KO_MAKE_RECURSIVE} -C "${SOURCE_DIR}"
    "OUT_DIR=${BINARY_DIR}/fbink" MINIMAL=1 FONTS=1 OPENTYPE=1 ${FBINK_TARGET})

# Install executables.
append_install_command(INSTALL_CMD "fbink/fbink")
if(FBDEPTH_TARGET)
    append_install_command(INSTALL_CMD "fbdepth/fbdepth")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    ae9dd275de369b1b34e1b566bca29573f06f38a2
    ${SOURCE_DIR}
)

thirdparty_project(
    # Not with that horrible Makefile we don't…
    # BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
