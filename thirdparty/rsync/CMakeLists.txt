string(APPEND CPPFLAGS " -I${STAGING_DIR}/include")
string(APPEND LDFLAGS " -L${STAGING_DIR}/lib")
string(APPEND LIBS " ${STAGING_DIR}/lib/libxxhash.a ${STAGING_DIR}/lib/libz.a ${STAGING_DIR}/lib/libzstd.a")

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${STAGING_DIR}
    # Project options.
    --$<IF:$<AND:$<BOOL:${WANT_SIMD}>,$<STREQUAL:${CMAKE_SYSTEM_PROCESSOR},x86_64>>,enable,disable>-md5-asm
    --$<IF:$<BOOL:${WANT_SIMD}>,enable,disable>-roll-asm
    --disable-acl-support
    --disable-iconv
    --disable-iconv-open
    --disable-idn
    --disable-lz4
    --disable-openssl
    --disable-xattr-support
    --enable-xxhash
    --enable-zstd
    --without-included-zlib
)

list(APPEND BUILD_CMD COMMAND make LIBS=${LIBS})

list(APPEND INSTALL_CMD COMMAND make install)

append_binary_install_command(INSTALL_CMD rsync)

external_project(
    DOWNLOAD URL 9b996a86c297a1e9cef0f92725dc825e
    https://github.com/RsyncProject/rsync/releases/download/v3.5.1/rsync-3.5.1.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
