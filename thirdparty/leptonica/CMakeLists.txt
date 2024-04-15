cmake_minimum_required(VERSION 3.5.1)
project(leptonica LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

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
list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/k2pdfopt.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/fix-uninitialized-memory-access.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    # Project options.
    -DBUILD_PROG=FALSE
    -DCMAKE_DISABLE_FIND_PACKAGE_GIF=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_JPEG=TRUE
    # This takes care of disabling JP2K and WebP support.
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_TIFF=TRUE
    # PNG.
    -DPNG_LIBRARY=${PNG_LIB}
    -DPNG_PNG_INCLUDE_DIR=${PNG_DIR}/include
    # ZLIB.
    -DZLIB_INCLUDE_DIR=${ZLIB_DIR}/include
    -DZLIB_LIBRARY=${ZLIB}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    # NOTE: Needs to match the version used by whatever version of libk2pdfopt we're currently using...
    #       Probably applies to mupdf & tesseract, too...
    URL https://github.com/DanBloomberg/leptonica/archive/refs/tags/1.74.1.tar.gz
    URL_MD5 b3de9ae35976fd4fc3f6dae5a4368bca
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
