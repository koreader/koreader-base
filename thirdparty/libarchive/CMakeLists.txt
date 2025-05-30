if(ANDROID)
    list(APPEND PATCH_FILES android.patch)
    list(APPEND PATCH_CMD COMMAND mv contrib/android/include/android_lf.h libarchive/)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DENABLE_ACL=FALSE
    -DENABLE_BZip2=FALSE
    -DENABLE_CAT=FALSE
    -DENABLE_CNG=FALSE
    -DENABLE_CPIO=FALSE
    -DENABLE_EXPAT=FALSE
    -DENABLE_ICONV=FALSE
    -DENABLE_LIBB2=FALSE
    -DENABLE_LIBXML2=FALSE
    -DENABLE_LZ4=FALSE
    -DENABLE_LZMA=$<BOOL:${ANDROID}>
    -DENABLE_OPENSSL=FALSE
    -DENABLE_PCRE2POSIX=FALSE
    -DENABLE_PCREPOSIX=FALSE
    -DENABLE_TAR=FALSE
    -DENABLE_TEST=FALSE
    -DENABLE_UNZIP=FALSE
    -DENABLE_WERROR=FALSE
    -DENABLE_XATTR=FALSE
    # Prevent md library fallback because OpenSSL is not used.
    -DLIBMD_FOUND=FALSE
)
# Avoid pulling > GLIBC_2.4 symbols on crappy platforms.
if(LEGACY OR POCKETBOOK)
    list(APPEND CMAKE_ARGS
        -DHAVE_FUTIMENS=FALSE
        -DHAVE_UTIMENSAT=FALSE
    )
endif()

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD archive VERSION 13)
endif()

external_project(
    DOWNLOAD URL e378aeb163d8c81745665dddd81116ef
    https://github.com/libarchive/libarchive/releases/download/v3.7.9/libarchive-3.7.9.tar.xz
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
