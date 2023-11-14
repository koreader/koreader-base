project(kobo-usbms LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

set(PATCH_CMD git -C FBInk submodule update --init --depth=1)

list(APPEND BUILD_CMD COMMAND env "CROSS_TC=${CHOST}")
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD ${KO_MAKE_RECURSIVE} kobo)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(BUILD_DIR Debug)
else()
    set(BUILD_DIR Release)
endif()

append_install_command(INSTALL_CMD "${BUILD_DIR}/KoboUSBMS.tar.gz" DESTINATION data/)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    3daab316d3aff2b43ced9c0b18e6ecdeec953e4a
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
