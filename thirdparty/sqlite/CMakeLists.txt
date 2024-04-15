cmake_minimum_required(VERSION 3.15)
project(sqlite LANGUAGES)

include(koreader_thirdparty_common)

string(APPEND CFLAGS " -fno-fast-math")
string(APPEND CPPFLAGS " -DNDEBUG -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_DECLTYPE -DSQLITE_OMIT_DEPRECATED -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA")

list(APPEND CFG_CMD env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    # Explicitly disable zlib, because it's only optionally used by the shell & extensions, and we disable both of those.
    # This should hopefully prevent Android from picking it up...
    ac_cv_header_zlib_h=no
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${STAGING_DIR}
    --disable-static --enable-shared
    --disable-dynamic-extensions
    --disable-editline
    --disable-readline
    --disable-static-shell
    --enable-silent-rules
    --enable-threadsafe
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

external_project(
    URL https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz
    URL_MD5 d6150f5dc837ae94b7d735f1b611b634
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
