cmake_minimum_required(VERSION 3.15)
project(luasocket LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(LUAPATH)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

# Rename modules:
# `mime.core` → `mime.mcore`
# `socket.core` → `socket.score`
list(APPEND PATCH_CMD COMMAND sh -c "\"\$@\" src/*" --
    ${ISED} " "
    -e "s|socket\\.core|socket.score|g"
    -e "s|socket_core|socket_score|g"
    -e "s|mime\\.core|mime.mcore|g"
    -e "s|mime_core|mime_mcore|g"
    -e "s|SOCKET_CDIR)/core|SOCKET_CDIR)/score|"
    -e "s|MIME_CDIR)/core|MIME_CDIR)/mcore|"
)

# Don't enforce CFLAGS.
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-O2 -ggdb3 ||g" src/makefile)

if(DARWIN)
    set(PLAT macosx)
elseif(WIN32)
    set(PLAT mingw)
else()
    set(PLAT linux)
endif()

string(JOIN " " MYLDFLAGS ${LDFLAGS} ${LUAJIT_LIB})

list(APPEND BUILD_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    "CC=${CC} ${CFLAGS}"
    "LD=${CC} ${CFLAGS}"
    LUAINC=${LUAJIT_INC}
    MYLDFLAGS=${MYLDFLAGS}
    PLAT=${PLAT}
)

list(APPEND INSTALL_CMD COMMAND
    ${KO_MAKE_RECURSIVE}
    INSTALL_TOP_LDIR=${LUAPATH}
    INSTALL_TOP_CDIR=${LUAPATH}
    install
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    fa69770e52ba869feb8339d49e7c3c536953fbde
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
