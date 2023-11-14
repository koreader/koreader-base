project(sqlite LANGUAGES)

list(APPEND CFG_CMD env
    "CC=${CC}"
    "CPPFLAGS=${CPPFLAGS} -DNDEBUG -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_DECLTYPE -DSQLITE_OMIT_DEPRECATED -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA"
    "CFLAGS=${CFLAGS} -fno-fast-math"
    "LDFLAGS=${LDFLAGS}"
    # Explicitly disable zlib, because it's only optionally used by the shell & extensions, and we disable both of those.
    # This should hopefully prevent Android from picking it up...
    ac_cv_header_zlib_h=no
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
    --disable-dynamic-extensions
    --disable-editline
    --disable-readline
    --disable-static-shell
    --enable-threadsafe
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} libsqlite3.la)

# FIXME: shouldn't the versioned `libsqlit3.so.0` be used?
set(LIB_SPEC sqlite3)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD .libs/${LIB} ${LIB_SPEC})

set(SQLITE_VER "3430200")

thirdparty_project(
    BUILD_ALWAYS
    URL https://www.sqlite.org/2023/sqlite-autoconf-${SQLITE_VER}.tar.gz
    URL_MD5 94fb06bfebc437762e489c355ae63716
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
