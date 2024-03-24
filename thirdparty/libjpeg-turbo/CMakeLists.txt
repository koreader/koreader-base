list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/no_cmake_rpath_shenanigans.patch)

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

# And, finally, the actual libjpeg-turbo build options.
list(APPEND CMAKE_ARGS "-DENABLE_STATIC=OFF")
list(APPEND CMAKE_ARGS "-DENABLE_SHARED=ON")
list(APPEND CMAKE_ARGS "-DWITH_JAVA=OFF")
list(APPEND CMAKE_ARGS "-DWITH_JPEG8=ON")
# Reproducible builds: use release date.
list(APPEND CMAKE_ARGS "-DBUILD=20240124")

# Make sure we disable ASM if we don't support SIMD.
if(NOT WANT_SIMD)
    list(APPEND CMAKE_ARGS "-DREQUIRE_SIMD=OFF")
    list(APPEND CMAKE_ARGS "-DWITH_SIMD=OFF")
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

set(JPEG_LIB_SPEC jpeg VERSION 8)
set_libname(JPEG_LIB ${JPEG_LIB_SPEC})
set(TURBOJPEG_LIB_SPEC turbojpeg)
set_libname(TURBOJPEG_LIB ${TURBOJPEG_LIB_SPEC})

# Install shared libs.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${JPEG_LIB} ${JPEG_LIB_SPEC})
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${TURBOJPEG_LIB} ${TURBOJPEG_LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${BINARY_DIR}"
    jconfig.h jconfigint.h
    FROM "${SOURCE_DIR}"
    jerror.h jmorecfg.h jpegint.h jpeglib.h turbojpeg.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/libjpeg-turbo/libjpeg-turbo.git
    3.0.2
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
