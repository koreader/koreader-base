project(leptonica LANGUAGES)

# Make sure we use the old fmemopen symbol on ARM Linux when building against
# glibc >= 2.22 (c.f. base#421 & #2188).
#
# NOTE: Technically, provided we're targeting ARM, we could probably apply the patch unilaterally,
# and not only when glibc >= 2.22, but since we now have the code to make the check, keep it,
# that ensures a vanilla build with sane TCs ;).
if((${ARM_GLIBC_GTE_2_22}) AND (NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$"))
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-1.74.1-fmemopen-arm-compat-symbol.patch)
endif()

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix-uninitialized-memory-access.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/k2pdfopt.patch)
# Use `-lpng16`, not `-lpng`.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/libpng16.patch)

# We apparently need a rebuild of the configure on macOS (https://github.com/koreader/koreader/issues/4448#issuecomment-522363325)
list(APPEND PATCH_CMD COMMAND autoreconf -fi)
# No stupid build rpaths
list(APPEND PATCH_CMD COMMAND ${ISED} "s/\\(hardcode_into_libs\\)=.*$/\\1=no/" configure)
# Fix "permission denied" error on OSX
list(APPEND PATCH_CMD COMMAND chmod +x config/install-sh)

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/libpng/include -I${STAGING_DIR}/zlib/include"
    "LIBS=-L${STAGING_DIR}/libpng/shared -L${STAGING_DIR}/zlib/shared"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-static --enable-shared
    --with-libpng
    --with-zlib
    --without-giflib
    --without-jpeg
    --without-libopenjpeg
    --without-libtiff
    --without-libwebp
)

if(ANDROID)
    list(APPEND CFG_CMD COMMAND ${ANDROID_LIBTOOL_FIX_CMD})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C src)

set(LIB_SPEC lept VERSION 5)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD src/.libs/${LIB} ${LIB_SPEC})

# Install headers.
#
# To dump the list of headers, use something like:
# ```
# make -C src --silent --eval $'dumpheaders:\n\t$(info $(pkginclude_HEADERS))' dumpheaders
# ```
# And no, we can't do it in the install command:
# https://gitlab.kitware.com/cmake/cmake/-/issues/16395
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/src/endianness.h"
    FROM "${SOURCE_DIR}/src"
    allheaders.h alltypes.h array.h arrayaccess.h bbuffer.h bilateral.h bmf.h
    bmfdata.h bmp.h ccbord.h dewarp.h environ.h gplot.h heap.h imageio.h
    jbclass.h leptwin.h list.h morph.h pix.h ptra.h queue.h rbtree.h
    readbarcode.h recog.h regutils.h stack.h stringcode.h sudoku.h watershed.h
)

# NOTE: Needs to match the version used by whatever version of libk2pdfopt we're currently using...
#       Probably applies to mupdf & tesseract, too...
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/DanBloomberg/leptonica.git
    1.74.1
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
