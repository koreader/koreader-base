list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND CMAKE_ARGS "-DLUA_INCLUDE_DIR=${STAGING_DIR}/include")
if(USE_LUAJIT_LIB)
    list(APPEND CMAKE_ARGS "-DLUA_LIBRARIES=${STAGING_DIR}/lib/libluajit${LIB_EXT}")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

append_binary_install_command(INSTALL_CMD BYPRODUCTS rapidjson.so common/)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/xpol/lua-rapidjson
    242b40c8eaceb0cc43bcab88309736461cac1234
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
