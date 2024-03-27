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

set(MAKE_CMD ${KO_MAKE_RECURSIVE} -C "${SOURCE_DIR}" "CROSS_TC=${CHOST}")
append_autotools_vars(MAKE_CMD)

if(FBDEPTH_TARGET)
    list(APPEND BUILD_CMD COMMAND
        ${MAKE_CMD}
        "OUT_DIR=${BINARY_DIR}/fbdepth"
        ${FBDEPTH_TARGET}
    )
endif()

list(APPEND BUILD_CMD COMMAND
    ${MAKE_CMD}
    "OUT_DIR=${BINARY_DIR}/fbink"
    # Minimal-ish, statically linked build,
    # we don't care about image support.
    "FONTS=1"
    "MINIMAL=1"
    "OPENTYPE=1"
    ${FBINK_TARGET}
)

# Install executables.
append_binary_install_command(INSTALL_CMD BYPRODUCTS fbink/fbink)
if(FBDEPTH_TARGET)
    append_binary_install_command(INSTALL_CMD BYPRODUCTS fbdepth/fbdepth)
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    1a989b30a195ca240a3cf37f9de61b4b3c7e891c
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
