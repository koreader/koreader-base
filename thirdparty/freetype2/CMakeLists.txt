list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} --default-library=shared
    -Dmmap=enabled
    -Dzlib=disabled
    "${SOURCE_DIR}"
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(LIB_SPEC freetype VERSION 6)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR freetype2
    "${SOURCE_DIR}/include/ft2build.h"
)
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR freetype2/freetype
    FROM "${SOURCE_DIR}/include/freetype"
    freetype.h ftadvanc.h ftbbox.h ftbdf.h ftbitmap.h ftbzip2.h ftcache.h
    ftchapters.h ftcid.h ftcolor.h ftdriver.h fterrdef.h fterrors.h ftfntfmt.h
    ftgasp.h ftglyph.h ftgxval.h ftgzip.h ftimage.h ftincrem.h ftlcdfil.h
    ftlist.h ftlogging.h ftlzw.h ftmac.h ftmm.h ftmodapi.h ftmoderr.h ftotval.h
    ftoutln.h ftparams.h ftpfr.h ftrender.h ftsizes.h ftsnames.h ftstroke.h
    ftsynth.h ftsystem.h fttrigon.h fttypes.h ftwinfnt.h
    otsvg.h t1tables.h ttnameid.h tttables.h tttags.h
)
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    SUBDIR freetype2/freetype/config
    FROM "${BINARY_DIR}"
    ftconfig.h ftoption.h
    FROM "${SOURCE_DIR}/include/freetype/config"
    ftheader.h ftmodule.h ftstdlib.h integer-types.h
    mac-support.h public-macros.h
)

# Install pkg-config entry.
append_install_commands(INSTALL_CMD BYPRODUCTS meson-private/freetype2.pc DESTINATION "${STAGING_DIR}/lib/pkgconfig/")

thirdparty_project(
    URL https://github.com/freetype/freetype/archive/refs/tags/VER-2-13-2.tar.gz
    URL_MD5 dcd1af080e43fe0c984c34bf3e7d5e16
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
