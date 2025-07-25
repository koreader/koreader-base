list(APPEND PATCH_FILES
    # Fix inline shenanigans.
    fix_debug_build.patch
    # Allow compiling with `-fvisibility=hidden`.
    visibility.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DANDROID=${ANDROID}
)

list(APPEND BUILD_CMD COMMAND ninja)

append_install_commands(INSTALL_CMD ${SOURCE_DIR}/src/lanes.lua DESTINATION common)
if(MONOLIBTIC)
    append_install_commands(INSTALL_CMD core.a DESTINATION ${STAGING_DIR}/lib/lanes)
else()
    append_binary_install_command(INSTALL_CMD core.so DESTINATION common/lanes)
endif()

external_project(
    DOWNLOAD GIT v3.17.1
    https://github.com/LuaLanes/lanes.git
    PATCH_FILES ${PATCH_FILES}
    PATCH_OVERLAY overlay
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
