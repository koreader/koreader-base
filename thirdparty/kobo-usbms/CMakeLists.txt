# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

list(APPEND BUILD_CMD COMMAND env "CROSS_TC=${CHOST}")
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD ${KO_MAKE_RECURSIVE} kobo)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(BUILD_DIR Debug)
else()
    set(BUILD_DIR Release)
endif()

append_install_commands(INSTALL_CMD BYPRODUCTS "${BUILD_DIR}/KoboUSBMS.tar.gz" DESTINATION data/)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    v1.3.9
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
