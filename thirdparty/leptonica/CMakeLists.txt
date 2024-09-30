# Make sure we use the old fmemopen symbol on ARM Linux when building against
# glibc >= 2.22 (c.f. base#421 & #2188).
#
# NOTE: Technically, provided we're targeting ARM, we could probably apply the patch unilaterally,
# and not only when glibc >= 2.22, but since we now have the code to make the check, keep it,
# that ensures a vanilla build with sane TCs ;).
if(NOT ANDROID AND NOT APPLE AND NOT WIN32 AND NOT EMULATE_READER)
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
        list(APPEND PATCH_FILES leptonica-1.74.1-fmemopen-arm-compat-symbol.patch)
    endif()
endif()
list(APPEND PATCH_FILES
    k2pdfopt.patch
    cmake_tweaks.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DBUILD_PROG=FALSE
    -DSTRICT_CONF=TRUE
    # Yes please.
    -DENABLE_PNG=TRUE
    -DENABLE_ZLIB=TRUE
    # No thank you.
    -DENABLE_GIF=FALSE
    -DENABLE_JPEG=FALSE
    -DENABLE_OPENJPEG=FALSE
    -DENABLE_TIFF=FALSE
    -DENABLE_WEBP=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)
list(APPEND INSTALL_CMD COMMAND ln -snf lept_$<CONFIG>.pc ${STAGING_DIR}/lib/pkgconfig/lept.pc)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD leptonica VERSION 6)
endif()

external_project(
    # NOTE: Needs to match the version used by whatever version of libk2pdfopt we're currently using...
    #       Probably applies to mupdf & tesseract, too...
    DOWNLOAD URL 58f37c12b1e9473c0c7ac0b1259e6a5c
    https://github.com/DanBloomberg/leptonica/archive/refs/tags/1.84.1.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
