# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} CROSS_TC=${CHOST})
append_autotools_vars(BUILD_CMD)
list(APPEND BUILD_CMD kobo)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BUILD_DIR Debug)
else()
    set(BUILD_DIR Release)
endif()

append_install_commands(INSTALL_CMD ${CMAKE_BUILD_TYPE}/KoboUSBMS.tar.gz DESTINATION data)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/koreader/KoboUSBMS.git
    24a8bf42243c78c6c5ed90bb6cbd7f3ff4b03616
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
