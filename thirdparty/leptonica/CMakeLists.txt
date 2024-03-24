cmake_minimum_required(VERSION 3.5.1)
project(leptonica LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(PNG_DIR)
assert_var_defined(PNG_LIB)
assert_var_defined(ZLIB_DIR)
assert_var_defined(ZLIB)

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
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND CMAKE_ARGS "-DBUILD_PROG=FALSE")
list(APPEND CMAKE_ARGS "-DCMAKE_DISABLE_FIND_PACKAGE_GIF=TRUE")
list(APPEND CMAKE_ARGS "-DCMAKE_DISABLE_FIND_PACKAGE_JPEG=TRUE")
# This takes care of disabling JP2K and WebP support.
list(APPEND CMAKE_ARGS "-DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE")
list(APPEND CMAKE_ARGS "-DCMAKE_DISABLE_FIND_PACKAGE_TIFF=TRUE")
# PNG.
list(APPEND CMAKE_ARGS "-DPNG_LIBRARY=${PNG_LIB}")
list(APPEND CMAKE_ARGS "-DPNG_PNG_INCLUDE_DIR=${PNG_DIR}/include")
# ZLIB.
list(APPEND CMAKE_ARGS "-DZLIB_INCLUDE_DIR=${ZLIB_DIR}/include")
list(APPEND CMAKE_ARGS "-DZLIB_LIBRARY=${ZLIB}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND mkdir -p "${INSTALL_DIR}/include/leptonica" "${INSTALL_DIR}/lib")
list(APPEND INSTALL_CMD COMMAND sh -c "cd \"$1\" && shift && cp \"$@\"" -- "${SOURCE_DIR}/src"
    "${BINARY_DIR}/src/endianness.h"
    allheaders.h alltypes.h array.h arrayaccess.h bbuffer.h bilateral.h bmf.h
    bmfdata.h bmp.h ccbord.h dewarp.h environ.h gplot.h heap.h imageio.h
    jbclass.h leptwin.h list.h morph.h pix.h ptra.h queue.h rbtree.h
    readbarcode.h recog.h regutils.h stack.h stringcode.h sudoku.h watershed.h
    "${INSTALL_DIR}/include/leptonica/"
)
list(APPEND INSTALL_CMD COMMAND sh -c "cp src/liblept${LIB_EXT}* \"$1\"" -- "${INSTALL_DIR}/lib/")

thirdparty_project(
    # NOTE: Needs to match the version used by whatever version of libk2pdfopt we're currently using...
    #       Probably applies to mupdf & tesseract, too...
    URL https://github.com/DanBloomberg/leptonica/archive/refs/tags/1.74.1.tar.gz
    URL_MD5 b3de9ae35976fd4fc3f6dae5a4368bca
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
