string(APPEND CPPFLAGS " -DNDEBUG -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_EXPR_DEPTH=0 -DSQLITE_OMIT_DECLTYPE -DSQLITE_OMIT_DEPRECATED -DSQLITE_OMIT_PROGRESS_CALLBACK -DSQLITE_OMIT_SHARED_CACHE -DSQLITE_USE_ALLOCA")

list(APPEND CFG_CMD env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    # Explicitly disable zlib, because it's only optionally used by the shell & extensions, and we disable both of those.
    # This should hopefully prevent Android from picking it up...
    ac_cv_header_zlib_h=no
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=/
    --disable-$<IF:$<BOOL:${MONOLIBTIC}>,shared,static>
    --disable-dynamic-extensions
    --disable-editline
    --disable-readline
    --disable-static-shell
    --enable-$<IF:$<BOOL:${MONOLIBTIC}>,static,shared>
    --enable-silent-rules
    --enable-threadsafe
)

list(APPEND BUILD_CMD COMMAND make libsqlite3.la)

list(APPEND INSTALL_CMD COMMAND make
    DESTDIR=${STAGING_DIR}
    install-includeHEADERS
    install-libLTLIBRARIES
    install-pkgconfigDATA
)

if(NOT MONOLIBTIC)
    set(LIB_SPEC sqlite3 VERSION 0)
    if(APPLE)
        append_shared_lib_fix_commands(INSTALL_CMD ${LIB_SPEC} ID)
    endif()
    append_shared_lib_install_commands(INSTALL_CMD ${LIB_SPEC})
endif()

external_project(
    DOWNLOAD URL ff687dfc7483196420a4f16a6f53702d
    https://www.sqlite.org/2024/sqlite-autoconf-3460000.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
