project(lpeg LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

# Official version.
set(LPEG_VER "1.0.2")

# Custom rockspec.
set(LPEG_ROCKSPEC "lpeg-${LPEG_VER}-2.rockspec")

# Rewrite Makefile to behave sensibly w/ LuaRocks, and optionally allow linking to the lua lib...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lpeg-${LPEG_VER}-standard-makefile.patch)

# Move our custom rockspec to the build dir to fullfil build deps
list(APPEND PATCH_CMD COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${LPEG_ROCKSPEC} ${LPEG_ROCKSPEC})

append_luarocks_install_command(BUILD_CMD ${LPEG_ROCKSPEC})

append_tree_install_command(INSTALL_CMD "${INSTALL_DIR}/rocks" rocks)

thirdparty_project(
    URL http://distcache.FreeBSD.org/ports-distfiles/lpeg-${LPEG_VER}.tar.gz
    URL_MD5 d342571886f1abcb7afe6a83d024d583
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
