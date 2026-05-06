# Never *ever* call setlocale, for any reason.
# Most of our target platforms have custom/broken/incomplete locales, don't screw with it.
# And this runs in our main thread, so this is Very Bad(TM).
list(APPEND PATCH_FILES no-locale-mangling.patch)
# Remove references to (build specific) install directory in binary.
list(APPEND PATCH_FILES no_references_to_install_dir.patch)

if(ANDROID)
    list(APPEND PATCH_FILES android.patch)
endif()

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD GIT release.3.5.30
    https://gitlab.com/koreader/djvulibre.git
    PATCH_OVERLAY overlay
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
