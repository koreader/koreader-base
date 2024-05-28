cmake_minimum_required(VERSION 3.5.1)
project(sqlite LANGUAGES)

include("koreader_thirdparty_common")

assert_var_defined(CC)
assert_var_defined(CPPFLAGS)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(CHOST)

set(CFG_CMD env "CC=${CC}")
set(CFG_CMD ${CFG_CMD} "CPPFLAGS=${CPPFLAGS} -DNDEBUG -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_DECLTYPE -DSQLITE_OMIT_DEPRECATED -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA")
# Explicitly disable zlib, because it's only optionally used by the shell & extensions, and we disable both of those.
# This should hopefully prevent Android from picking it up...
set(CFG_CMD ${CFG_CMD} ac_cv_header_zlib_h=no)
set(CFG_CMD ${CFG_CMD} "CFLAGS=${CFLAGS} -fno-fast-math")
set(CFG_CMD ${CFG_CMD} "LDFLAGS=${LDFLAGS}")
set(CFG_CMD ${CFG_CMD} ${SOURCE_DIR}/configure)
set(CFG_CMD ${CFG_CMD} --host=${CHOST} --prefix=${INSTALL_DIR})
# set(CFG_CMD ${CFG_CMD} --enable-static)
set(CFG_CMD ${CFG_CMD} --disable-static)
set(CFG_CMD ${CFG_CMD} --enable-shared)
set(CFG_CMD ${CFG_CMD} --enable-threadsafe)
set(CFG_CMD ${CFG_CMD} --disable-dynamic-extensions)
set(CFG_CMD ${CFG_CMD} --disable-editline)
set(CFG_CMD ${CFG_CMD} --disable-readline)
set(CFG_CMD ${CFG_CMD} --disable-static-shell)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

set(SQLITE_VER "3450000")

external_project(
    URL https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_VER}.tar.gz
    URL_MD5 d6150f5dc837ae94b7d735f1b611b634
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
