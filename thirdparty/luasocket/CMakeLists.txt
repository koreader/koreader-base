cmake_minimum_required(VERSION 3.5.1)
project(luasocket LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(PLAT)
assert_var_defined(LUAINC)
assert_var_defined(LUAPATH)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND sh -c "\"\$@\" src/*" --
  ${ISED} " "
  -e "s|socket\\.core|socket.score|"
  -e "s|socket_core|socket_score|"
  -e "s|mime\\.core|mime.mcore|"
  -e "s|mime_core|mime_mcore|"
  -e "s|SOCKET_CDIR)/core|SOCKET_CDIR)/score|"
  -e "s|MIME_CDIR)/core|MIME_CDIR)/mcore|"
)
# Don't enforce CFLAGS
list(APPEND PATCH_CMD COMMAND ${ISED} "s|-O2 -ggdb3 ||g" src/makefile)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} "PLAT=${PLAT}" "CC=${CC}" "LD=${CC}")
if(DEFINED MYLDFLAGS)
  list(APPEND BUILD_CMD "MYLDFLAGS=${MYLDFLAGS}")
endif()
if(DEFINED LUALIB_mingw)
  list(APPEND BUILD_CMD "LUALIB_mingw=${LUALIB_mingw}")
endif()
list(APPEND BUILD_CMD "LUAINC=${LUAINC}" all)

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
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} INSTALL_TOP_LDIR=${LUAPATH} INSTALL_TOP_CDIR=${LUAPATH} install
)
