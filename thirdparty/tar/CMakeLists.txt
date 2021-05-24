project(tar)
cmake_minimum_required(VERSION 3.10.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
#include("koreader_thirdparty_git")
enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBS)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# O_PATH may be defined in our ToolChains, but older devices actually run kernels where it's not entirely usable...
# (Usage in tar via gnulib's https://git.savannah.gnu.org/cgit/gnulib.git/log/lib/fchmodat.c)
if(NOT DEFINED ENV{EMULATE_READER})
    set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.33-remove-o_path-usage.patch")
endif()

# The wordsplit changes introduced in 1.31 require glob.h, which is not present on Androdi before ABI 28 (c.f., #787)
if(DEFINED ENV{ANDROID})
    set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.31-revert-wordsplit-for-android-glob.patch")
endif()

#set(PATCH_CMD3 sh -c "touch ABOUT-NLS po/Makevars.template")
#set(PATCH_CMD4 sh -c "AUTOPOINT=true ./bootstrap --skip-po")

# Avoid pulling > GLIBC_2.4 symbols on crappy platforms
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    set(CFG_ENV_VAR "ac_cv_func_utimensat=no ac_cv_func_futimens=no")
endif()

set(CFG_ENV_VAR "${CFG_ENV_VAR} CC=\"${CC} -DHAVE_MKFIFO=1\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"")
set(CFG_OPTS "-q LIBS=\"${LIBS}\" --host=\"${CHOST}\"")

if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    set(CFG_OPTS "${CFG_OPTS} --disable-largefile")
endif()
set(CFG_CMD "${CFG_ENV_VAR} ${SOURCE_DIR}/configure --disable-nls --disable-gcc-warnings --disable-acl --without-xattrs --without-posix-acls ${CFG_OPTS}")

if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
    # Forcibly disable FORTIFY on legacy devices...
    set(CFG_CMD "${CFG_CMD} && ${ISED} 's/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/' config.h")
endif()
set(CFG_CMD sh -c "${CFG_CMD}")

# We build in-tree...
set(INSTALL_CMD1 ${CMAKE_COMMAND} -E rename ${BINARY_DIR}/src/tar ${BINARY_DIR}/tar)
#set(INSTALL_CMD1 ${CMAKE_COMMAND} -E make_directory ${BINARY_DIR})
#set(INSTALL_CMD2 ${CMAKE_COMMAND} -E rename ${SOURCE_DIR}/src/tar ${BINARY_DIR}/tar)

#ko_write_gitclone_script(
#    GIT_CLONE_SCRIPT_FILENAME
#    https://git.savannah.gnu.org/git/tar.git
#    release_1_32
#    ${SOURCE_DIR}
#)

include(ExternalProject)
set(TAR_VER "1.34")
ExternalProject_Add(
    ${PROJECT_NAME}
    URL http://ftpmirror.gnu.org/tar/tar-${TAR_VER}.tar.gz
    URL_MD5 9d5949e4c2d9665546ac65dafc0e726a
    DOWNLOAD_DIR ${KO_DOWNLOAD_DIR}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2}
    #DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    #BUILD_IN_SOURCE 1
    #PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3} COMMAND ${PATCH_CMD4}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    # The buildsystem outputs binaries in a subdirectory...
    INSTALL_COMMAND COMMAND ${INSTALL_CMD1}
    #INSTALL_COMMAND COMMAND ${INSTALL_CMD1} COMMAND ${INSTALL_CMD2}
)
