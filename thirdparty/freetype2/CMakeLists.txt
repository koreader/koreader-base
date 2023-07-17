project(freetype2)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CXX)
assert_var_defined(CXXFLAGS)
assert_var_defined(LDFLAGS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

set(CFG_ENV_VAR "CC=${CC}" "CXX=${CXX}" "CFLAGS=${CFLAGS}" "CXXFLAGS=${CXXFLAGS}" "LDFLAGS=${LDFLAGS}")
set(CFG_OPTS --prefix=${BINARY_DIR} --libdir=${BINARY_DIR}/lib --disable-static --enable-shared --with-zlib=no --with-bzip2=no --with-brotli=no --with-png=no --with-harfbuzz=no --host=${CHOST})
set(CFG_CMD env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

if(DEFINED ENV{ANDROID})
    set(SED_CMD sh -c "${ISED} 's|version_type=none|version_type=linux|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_lib_prefix=no|need_lib_prefix=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|need_version=no|need_version=yes|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|library_names_spec=.*|library_names_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$versuffix \\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major \\\\\$libname\\\\\$shared_ext\"|' libtool")
    set(SED_CMD "${SED_CMD} && ${ISED} 's|soname_spec=.*|soname_spec=\"\\\\\$libname\\\\\$release\\\\\$shared_ext\\\\\$major\"|' libtool")
endif()

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://gitlab.com/koreader/freetype2.git
    VER-2-13-1
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ./autogen.sh
    CONFIGURE_COMMAND COMMAND ${CFG_CMD} COMMAND ${SED_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
