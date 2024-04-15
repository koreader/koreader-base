cmake_minimum_required(VERSION 3.7)
project(tar LANGUAGES)

include("koreader_thirdparty_common")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(LIBS)

# O_PATH may be defined in our ToolChains, but older devices actually run kernels where it's not entirely usable...
# (Usage in tar via gnulib's https://git.savannah.gnu.org/cgit/gnulib.git/log/lib/fchmodat.c)
if(NOT EMULATE_READER)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.33-remove-o_path-usage.patch)
endif()

# The wordsplit changes introduced in 1.31 require glob.h, which is not present on Androdi before ABI 28 (c.f., #787)
if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.31-revert-wordsplit-for-android-glob.patch)
endif()

# list(APPEND PATCH_CMD COMMAND touch ABOUT-NLS po/Makevars.template)
# list(APPEND PATCH_CMD COMMAND env AUTOPOINT=true ./bootstrap --skip-po)

# Avoid pulling > GLIBC_2.4 symbols on crappy platforms
if(LEGACY OR POCKETBOOK)
    set(CFG_ENV_VAR ac_cv_func_utimensat=no ac_cv_func_futimens=no)
endif()

set(CFG_ENV_VAR ${CFG_ENV_VAR} "CC=${CC} -DHAVE_MKFIFO=1" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" "LIBS=${LIBS}")
set(CFG_OPTS --host=${CHOST})

if(LEGACY OR POCKETBOOK)
    set(CFG_OPTS ${CFG_OPTS} --disable-largefile)
endif()
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure --disable-nls --disable-gcc-warnings --disable-acl --without-xattrs --without-posix-acls ${CFG_OPTS})

if(LEGACY OR POCKETBOOK)
    # Forcibly disable FORTIFY on legacy devices...
    list(APPEND CFG_CMD COMMAND ${ISED} "s/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/" config.h)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

external_project(
    URL http://ftpmirror.gnu.org/tar/tar-1.34.tar.gz
    http://ftp.gnu.org/pub/gnu/tar/tar-1.34.tar.gz
    URL_MD5 9d5949e4c2d9665546ac65dafc0e726a
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
