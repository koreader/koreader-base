if(NOT MONOLIBTIC)
    set(CMAKE_PATCH_FILE ${CMAKE_BINARY_DIR}/k2pdfopt_exports.cmake)
    target_exports(k2pdfopt FILELIST_VAR CDECLS_FILES WRITE_TO_FILE ${CMAKE_PATCH_FILE} CDECLS koptcontext_cdecl)
    list(APPEND PATCH_CMD COMMAND ${ISED} "\$p" -e "\$s|.*|include(${CMAKE_PATCH_FILE})|" lib/CMakeLists.txt)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=$<NOT:$<BOOL:${MONOLIBTIC}>>
    # Project options.
    -DANDROID=${ANDROID}
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

if(NOT MONOLIBTIC)
    append_shared_lib_install_commands(INSTALL_CMD k2pdfopt VERSION 2)
endif()

external_project(
    DOWNLOAD GIT 0be83e5d9d04dfa1c8bd7c7230851d251cf9f429
    https://github.com/koreader/libk2pdfopt.git
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    SOURCE_SUBDIR lib
    BUILD_COMMAND ${BUILD_CMD}
    BUILD_DEPENDS ${CDECLS_FILES}
    INSTALL_COMMAND ${INSTALL_CMD}
)
