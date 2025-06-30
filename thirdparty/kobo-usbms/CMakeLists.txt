# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD COMMAND make CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)
# Make sure the binaries in the `KoboUSBMS.tar.gz` archive are stripped.
list(APPEND BUILD_CMD "STRIP=${STRIP} --strip-unneeded")
list(APPEND BUILD_CMD kobo)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND BUILD_CMD DEBUG=1)
endif()

append_install_commands(INSTALL_CMD ${CMAKE_BUILD_TYPE}/KoboUSBMS.tar.gz DESTINATION data)

external_project(
    DOWNLOAD GIT a35a8f639699deaae2e2ee446b5f6c2d2096c1bb
    https://github.com/koreader/KoboUSBMS.git
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
