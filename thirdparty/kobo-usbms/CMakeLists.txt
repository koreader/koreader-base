cmake_minimum_required(VERSION 3.15)
project(kobo-usbms LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix_make_-n.patch)
list(APPEND PATCH_CMD COMMAND sh -c "cd FBInk && \"$0\" \"$@\"" ${KO_PATCH}
    ${THIRDPARTY_DIR}/fbink/fix_toolchain_vars_forwarding.patch
    ${THIRDPARTY_DIR}/fbink/fix_make_-n.patch
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD kobo)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    v1.3.9
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
)
