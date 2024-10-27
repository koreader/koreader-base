set(TOOL ${PROJECT_NAME})

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Choose your own adventure!
set(FBDEPTH_TARGET fbdepth)
if(LEGACY)
    set(FBINK_TARGET legacy)
    set(INPUT_TARGET inputlib KINDLE=1 LEGACY=1)
elseif(KINDLE)
    set(FBINK_TARGET kindle)
    set(INPUT_TARGET inputlib KINDLE=1)
elseif(CERVANTES)
    set(FBINK_TARGET cervantes)
    set(INPUT_TARGET inputlib CERVANTES=1)
elseif(KOBO)
    set(FBINK_TARGET strip KOBO=1)
    set(FBDEPTH_TARGET fbdepth KOBO=1)
    set(INPUT_TARGET inputlib KOBO=1)
elseif(REMARKABLE)
    set(FBINK_TARGET remarkable)
    set(FBDEPTH_TARGET fbdepth REMARKABLE=1)
    set(INPUT_TARGET inputlib REMARKABLE=1)
elseif(POCKETBOOK)
    set(FBINK_TARGET pocketbook)
    set(FBDEPTH_TARGET fbdepth POCKETBOOK=1)
    set(INPUT_TARGET inputlib POCKETBOOK=1)
else()
    set(FBINK_TARGET strip)
    # Would technically run just fine on plain Linux...
    #set(INPUT_TARGET inputlib LINUX=1)
endif()

list(APPEND BUILD_CMD COMMAND make CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)

if(TOOL STREQUAL "fbdepth")
    list(APPEND BUILD_CMD ${FBDEPTH_TARGET})
    append_binary_install_command(INSTALL_CMD ${CMAKE_BUILD_TYPE}/fbdepth)
elseif(TOOL STREQUAL "fbink")
    list(APPEND BUILD_CMD
        # Minimal-ish, statically linked build,
        # we don't care about image support.
        FONTS=1
        MINIMAL=1
        OPENTYPE=1
        ${FBINK_TARGET}
    )
    append_binary_install_command(INSTALL_CMD ${CMAKE_BUILD_TYPE}/fbink)
elseif(TOOL STREQUAL "libfbink_input")
    list(APPEND BUILD_CMD ${INPUT_TARGET})
    append_binary_install_command(INSTALL_CMD ${CMAKE_BUILD_TYPE}/libfbink_input.so.1 DESTINATION libs)
else()
    message(FATAL_ERROR "TOOL not set or unsupported: '${TOOL}'")
endif()

external_project(
    DOWNLOAD GIT 4404f2e6ae8bfa37c4ab603db0abbe5cd203ce97
    https://github.com/NiLuJe/FBInk.git
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
