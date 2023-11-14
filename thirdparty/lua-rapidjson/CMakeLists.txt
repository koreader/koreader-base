project(lua-rapidjson LANGUAGES)

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-never-native.patch)
if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/lua-rapidjson-android-link-to-lua.patch)
endif()

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

list(APPEND CMAKE_ARGS "-DLUA_INCLUDE_DIR=${LUAJIT_INCDIR}")
if(LUAJIT_LIB)
    list(APPEND CMAKE_ARGS "-DLUA_LIBRARIES=-L${LUAJIT_LIBDIR}/${LUAJIT_LIB}")
endif()

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

append_install_command(INSTALL_CMD "rapidjson.so" DESTINATION rocks/lib/lua/5.1/)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/xpol/lua-rapidjson
    242b40c8eaceb0cc43bcab88309736461cac1234
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS "${CMAKE_ARGS}"
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
