cmake_minimum_required(VERSION 3.5.1)
project(kobo-usbms LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} "CROSS_TC=${CHOST}" "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" kobo)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    24a8bf42243c78c6c5ed90bb6cbd7f3ff4b03616
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
)
