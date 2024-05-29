# Make sure we use the old fmemopen symbol on ARM Linux when building against
# glibc >= 2.22 (c.f. base#421 & #2188).
#
# NOTE: Technically, provided we're targeting ARM, we could probably apply the patch unilaterally,
# and not only when glibc >= 2.22, but since we now have the code to make the check, keep it,
# that ensures a vanilla build with sane TCs ;).
if(NOT ANDROID AND NOT DARWIN AND NOT WIN32 AND NOT EMULATE_READER)
    enable_language(C)
    include(CheckCSourceCompiles)
    check_c_source_compiles([==[
        #include <limits.h>
        #if __GNUC_PREREQ (2, 22)
            __asm__(".symver fmemopen,fmemopen@GLIBC_2.4");
        #else
            #error glibc < 2.22
        #endif
        char fmemopen(void);
        int main(void) {
            return fmemopen();
        }
        ]==] HAS_FMEMOPEN_2_4)
    if(HAS_FMEMOPEN_2_4)
        list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-1.74.1-fmemopen-arm-compat-symbol.patch)
    endif()
endif()
list(APPEND PATCH_CMD COMMAND ${KO_PATCH}
    ${CMAKE_CURRENT_SOURCE_DIR}/k2pdfopt.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch
    ${CMAKE_CURRENT_SOURCE_DIR}/fix-uninitialized-memory-access.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DBUILD_PROG=FALSE
    -DCMAKE_DISABLE_FIND_PACKAGE_GIF=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_JPEG=TRUE
    # This takes care of disabling JP2K and WebP support.
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_TIFF=TRUE
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD lept VERSION 5)

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
