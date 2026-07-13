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
    DOWNLOAD GIT d1d916655b1406780f12ba0c2442b6a901e75929
    https://github.com/koreader/KoboUSBMS.git
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
