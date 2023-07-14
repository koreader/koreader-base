project(luasocket)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C ASM)

assert_var_defined(CC)
assert_var_defined(PLAT)
assert_var_defined(LUAINC)
assert_var_defined(INSTALL_DIR)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD sh -c "${ISED} 's|socket\\.core|socket\\.score|' src/*")
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|socket_core|socket_score|' src/*")
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|mime\\.core|mime\\.mcore|' src/*")
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|mime_core|mime_mcore|' src/*")
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|SOCKET_CDIR)/core|SOCKET_CDIR)/score|' src/*")
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|MIME_CDIR)/core|MIME_CDIR)/mcore|' src/*")
# Don't enforce CFLAGS
set(PATCH_CMD "${PATCH_CMD} && ${ISED} 's|-O2 -ggdb3 ||g' src/makefile")

set(BUILD_CMD_STR ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} PLAT=${PLAT} CC="${CC}" LD="${CC}")
if(DEFINED MYLDFLAGS)
    set(BUILD_CMD_STR ${BUILD_CMD_STR} MYLDFLAGS="${MYLDFLAGS}")
endif()
if(DEFINED LUALIB_mingw)
    set(BUILD_CMD_STR ${BUILD_CMD_STR} LUALIB_mingw="${LUALIB_mingw}")
endif()
set(BUILD_CMD ${BUILD_CMD_STR} LUAINC="${LUAINC}" -j${PARALLEL_JOBS} all)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/lunarmodules/luasocket
    8c2ff7217e2a205eb107a6f48b04ff1b2b3090a1
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
