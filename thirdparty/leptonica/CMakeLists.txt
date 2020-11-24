project(leptonica)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

ep_get_source_dir(SOURCE_DIR)

# NOTE: Needs to match the version used by whatever version of libk2pdfopt we're currently using...
#       Probably applies to mupdf & tesseract, too...
ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/DanBloomberg/leptonica.git
    1.74.1
    ${SOURCE_DIR}
)

# Make sure we use the old fmemopen symbol on ARM Linux when building against
# glibc >= 2.22 (c.f. base#421 & #2188).
#
# NOTE: Technically, provided we're targeting ARM, we could probably apply the patch unilaterally,
# and not only when glibc >= 2.22, but since we now have the code to make the check, keep it,
# that ensures a vanilla build with sane TCs ;).
#
# NOTE: The patch will be much simpler w/ the upcoming leptonica version,
# there's a 1.74 version of the patch already in our tree for when that time
# comes ;).
if((${ARM_GLIBC_GTE_2_22}) AND (NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$"))
    set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/leptonica-1.74.1-fmemopen-arm-compat-symbol.patch")
endif()

# We apparently need a rebuild of the configure on macOS (https://github.com/koreader/koreader/issues/4448#issuecomment-522363325)
set(RECONF_CMD sh -c "autoreconf -fi")

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD} COMMAND ${RECONF_CMD}
    CONFIGURE_COMMAND ""
    # skip build and install, libk2pdfopt will build it
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
