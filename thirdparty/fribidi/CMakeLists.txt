list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "${SOURCE_DIR}/configure" --host=${CHOST}
    --disable-static --enable-shared
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C lib)

set(LIB_SPEC fribidi VERSION 0)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS lib/.libs/${LIB} ${LIB_SPEC} DARWIN_SONAME_FIX)

# Install headers.
# NOTE: to get an updated list of source headers, use something like:
# ```
# make -C […]/build/lib --silent --eval $'dumpheaders:\n\t$(info $(filter-out fribidi-unicode-version.h,$(pkginclude_HEADERS)))' dumpheaders
# ```
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${BINARY_DIR}/lib"
    fribidi-config.h
    FROM "${SOURCE_DIR}/lib"
    fribidi-arabic.h fribidi-begindecls.h fribidi-bidi.h fribidi-bidi-types.h
    fribidi-bidi-types-list.h fribidi-common.h fribidi-char-sets.h
    fribidi-char-sets-list.h fribidi-deprecated.h fribidi-enddecls.h
    fribidi-flags.h fribidi-joining.h fribidi-joining-types.h
    fribidi-joining-types-list.h fribidi-mirroring.h fribidi-brackets.h
    fribidi-shape.h fribidi-types.h fribidi-unicode-version.h fribidi-unicode.h
    fribidi.h
)

thirdparty_project(
    URL https://github.com/fribidi/fribidi/releases/download/v1.0.13/fribidi-1.0.13.tar.xz
    URL_MD5 49b17442e0d8fa2e97b5c898078f6f51
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
