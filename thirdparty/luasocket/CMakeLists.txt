cmake_minimum_required(VERSION 3.5.1)
project(luasocket LANGUAGES)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(PLAT)
assert_var_defined(LUAINC)
assert_var_defined(INSTALL_DIR)

ep_get_source_dir(SOURCE_DIR)

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

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} "PLAT=${PLAT}" "CC=${CC}" "LD=${CC}")
if(DEFINED MYLDFLAGS)
  list(APPEND BUILD_CMD "MYLDFLAGS=${MYLDFLAGS}")
endif()
if(DEFINED LUALIB_mingw)
  list(APPEND BUILD_CMD "LUALIB_mingw=${LUALIB_mingw}")
endif()
list(APPEND BUILD_CMD "LUAINC=${LUAINC}" -j${PARALLEL_JOBS} all)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    fa69770e52ba869feb8339d49e7c3c536953fbde
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} INSTALL_TOP_LDIR=${INSTALL_DIR} INSTALL_TOP_CDIR=${INSTALL_DIR} install
)
