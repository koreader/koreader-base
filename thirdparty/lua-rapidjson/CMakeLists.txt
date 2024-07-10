list(APPEND PATCH_FILES cmake_tweaks.patch)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DLUA_INCLUDE_DIR=${LUAJIT_INC}
    -DLUA_LIBRARIES=${LUAJIT_LIB}
)

list(APPEND BUILD_CMD COMMAND ninja)

append_binary_install_command(INSTALL_CMD rapidjson.so DESTINATION common)

external_project(
    DOWNLOAD GIT e84973356255bde06a70ce6263a3a0ef5c8f4ad4
    https://github.com/NiLuJe/lua-rapidjson
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
