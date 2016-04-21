PROJECT(djvulibre)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBS)
assert_var_defined(CHOST)

ep_get_source_dir(SOURCE_DIR)

set(CFG_ENV_VAR "CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" LDFLAGS=\"${LDFLAGS}\" LIBS=\"${LIBS}\"")
set(CFG_OPTS "-q --disable-desktopfiles --disable-static --enable-shared --disable-xmltools --disable-largefile --without-jpeg --without-tiff -host=\"${CHOST}\"")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")
set(PATCH_CMD sh -c "${ISED} \"s|-lstdc++||g\" libtool")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    git://git.code.sf.net/p/djvu/djvulibre-git
    070fef721a8e8fdf68c4b0e3fcf0a179c804d818
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND NOCONFIGURE=1 ./autogen.sh
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${PATCH_CMD}
    BUILD_COMMAND $(MAKE) -j${PARALLEL_JOBS} SUBDIRS_FIRST=libdjvu --silent
    # skip install
    INSTALL_COMMAND ""
)
