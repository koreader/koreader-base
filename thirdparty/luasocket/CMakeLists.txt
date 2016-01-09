PROJECT(luasocket)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C ASM)

assert_var_defined(CC)
assert_var_defined(PLAT)
assert_var_defined(LUAINC)
assert_var_defined(INSTALL_DIR)

ep_get_source_dir(SOURCE_DIR)

set(PATCH_CMD_STR "sed -i 's|socket\\.core|socket\\.score|' src/*")
set(PATCH_CMD_STR "${PATCH_CMD_STR} && sed -i 's|socket_core|socket_score|' src/*")
set(PATCH_CMD_STR "${PATCH_CMD_STR} && sed -i 's|mime\\.core|mime\\.mcore|' src/*")
set(PATCH_CMD_STR "${PATCH_CMD_STR} && sed -i 's|mime_core|mime_mcore|' src/*")
set(PATCH_CMD_STR "${PATCH_CMD_STR} && sed -i 's|SOCKET_CDIR)/core|SOCKET_CDIR)/score|' src/*")
set(PATCH_CMD_STR "${PATCH_CMD_STR} && sed -i 's|MIME_CDIR)/core|MIME_CDIR)/mcore|' src/*")

set(BUILD_CMD_STR "$(MAKE) PLAT=${PLAT} CC=\"${CC}\" LD=\"${CC}\"")
if(DEFINED MYLDFLAGS)
    set(BUILD_CMD_STR "${BUILD_CMD_STR} MYLDFLAGS=\"${MYLDFLAGS}\"")
endif()
if(DEFINED LUALIB_mingw)
    set(BUILD_CMD_STR "${BUILD_CMD_STR} LUALIB_mingw=\"${LUALIB_mingw}\"")
endif()
set(BUILD_CMD_STR "${BUILD_CMD_STR} LUAINC=\"${LUAINC}\" -j${PARALLEL_JOBS} --silent all")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/diegonehab/luasocket
    321c0c9b1f7b6b83cd83b58e7e259f53eca69373
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND sh -c ${PATCH_CMD_STR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND sh -c ${BUILD_CMD_STR}
    # skip install
    INSTALL_COMMAND $(MAKE) INSTALL_TOP_LDIR=${INSTALL_DIR} INSTALL_TOP_CDIR=${INSTALL_DIR} install
)
