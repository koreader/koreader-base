# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD COMMAND make CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD kobo)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BUILD_DIR Debug)
else()
    set(BUILD_DIR Release)
endif()

append_install_commands(INSTALL_CMD ${CMAKE_BUILD_TYPE}/KoboUSBMS.tar.gz DESTINATION data)

external_project(
    DOWNLOAD GIT 3c14b5421968ecd688715ff258d43197817d29a1
    https://github.com/koreader/KoboUSBMS.git
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
