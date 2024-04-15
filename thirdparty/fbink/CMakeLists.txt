cmake_minimum_required(VERSION 3.5.1)
project(${TOOL} LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(AR)
assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(RANLIB)
assert_var_defined(STRIP)
assert_var_defined(TOOL)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/fix_toolchain_vars_forwarding.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/fix_make_-n.patch
)

# Choose your own adventure!
set(FBDEPTH_TARGET fbdepth)
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

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE} -C ${SOURCE_DIR}
    CROSS_TC=${CHOST}
    AR=${AR}
    CC=${CC}
    CFLAGS=${CFLAGS}
    CXX=${CXX}
    CXXFLAGS=${CXXFLAGS}
    LDFLAGS=${LDFLAGS}
    RANLIB=${RANLIB}
    STRIP=${STRIP}
)

if(TOOL STREQUAL "fbdepth")
    list(APPEND BUILD_CMD ${FBDEPTH_TARGET})
elseif(TOOL STREQUAL "fbink")
    list(APPEND BUILD_CMD
        # Minimal-ish, statically linked build,
        # we don't care about image support.
        FONTS=1
        MINIMAL=1
        OPENTYPE=1
        ${FBINK_TARGET}
    )
else()
    message(FATAL_ERROR "TOOL not set or unsupported: '${TOOL}'")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/NiLuJe/FBInk.git
    1a989b30a195ca240a3cf37f9de61b4b3c7e891c
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
