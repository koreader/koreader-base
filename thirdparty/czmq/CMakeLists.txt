list(APPEND PATCH_FILES cmake_tweaks.patch)
if(NOT APPLE)
    # patch: ignore limited broadcast address
    list(APPEND PATCH_FILES zbeacon.patch)
    # patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
    list(APPEND PATCH_FILES czmq_default_source_define.patch)
endif()

list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ninja czmq)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

append_shared_lib_install_commands(INSTALL_CMD czmq VERSION 1)

external_project(
    DOWNLOAD GIT 2a0ddbc4b2dde623220d7f4980ddd60e910cfa78
    https://github.com/zeromq/czmq.git
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
