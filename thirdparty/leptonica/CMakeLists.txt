cmake_minimum_required(VERSION 3.15)
project(leptonica LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

assert_var_defined(PNG_DIR)
assert_var_defined(ZLIB_DIR)

# Make sure we use the old fmemopen symbol on ARM Linux when building against
# glibc >= 2.22 (c.f. base#421 & #2188).
#
# NOTE: Technically, provided we're targeting ARM, we could probably apply the patch unilaterally,
# and not only when glibc >= 2.22, but since we now have the code to make the check, keep it,
# that ensures a vanilla build with sane TCs ;).
if(NOT ANDROID AND NOT DARWIN AND NOT WIN32 AND NOT EMULATE_READER)
    execute_process(COMMAND ${CMAKE_C_COMPILER} -print-file-name=libc.so.6 OUTPUT_VARIABLE GLIBC_FILE OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE EXIT_CODE)
    if(EXIT_CODE)
        message(FATAL_ERROR "could not determine GLIBC version: ${EXIT_CODE}")
    endif()
    execute_process(COMMAND ${CMAKE_READELF} --version-info ${GLIBC_FILE} OUTPUT_VARIABLE GLIBC_VERSION_INFO RESULT_VARIABLE EXIT_CODE)
    if(EXIT_CODE)
        message(FATAL_ERROR "could not determine GLIBC version: ${EXIT_CODE}")
    endif()
    string(REPLACE "\n" ";" LINES ${GLIBC_VERSION_INFO})
    set(GLIBC_VERSION)
    foreach(L IN LISTS LINES)
        string(REGEX MATCH " GLIBC_([0-9.]+)$" M "${L}")
        if(M AND NOT GLIBC_VERSION OR GLIBC_VERSION VERSION_LESS CMAKE_MATCH_1)
            set(GLIBC_VERSION ${CMAKE_MATCH_1})
        endif()
    endforeach()
    if(NOT GLIBC_VERSION)
        message(FATAL_ERROR "could not determine GLIBC version!")
    endif()
    message(STATUS "detected GLIBC version: ${GLIBC_VERSION}")
    if(GLIBC_VERSION VERSION_GREATER_EQUAL "2.22")
        list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-1.74.1-fmemopen-arm-compat-symbol.patch)
    endif()
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
    -DPNG_ROOT=${PNG_DIR}
    # ZLIB.
    -DZLIB_ROOT=${ZLIB_DIR}
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
