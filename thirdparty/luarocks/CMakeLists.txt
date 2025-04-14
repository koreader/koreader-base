# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND CFG_CMD COMMAND
    ./configure
    --prefix=${STAGING_DIR}
    --with-lua=${STAGING_DIR}
)

list(APPEND BUILD_CMD COMMAND make)

list(APPEND INSTALL_CMD COMMAND make install)

# Try to use our compilation flags.
set(LD ${CC})
set(LIBFLAGS ${DYNLIB_LDFLAGS})
foreach(VAR CC CFLAGS LD LIBFLAGS)
    list(APPEND INSTALL_CMD COMMAND ${STAGING_DIR}/bin/luarocks config -- ${VAR} "${${VAR}}")
endforeach()
# Luarocks needs to be told where librt is when building
# luasystem with clang in our Ubuntu based docker image.
if(EMULATE_READER AND NOT APPLE)
    # NOTE: `librt.so.1` may not exists (e.g. on Alpine Linux), in which
    # case `find_compiler_lib_path` will return a false value ("NOTFOUND").
    find_compiler_lib_path(RT_LIB librt.so.1)
    if(RT_LIB)
        get_filename_component(RT_LIBDIR ${RT_LIB} DIRECTORY)
        list(APPEND INSTALL_CMD COMMAND ${STAGING_DIR}/bin/luarocks config -- RT_LIBDIR "${RT_LIBDIR}")
    endif()
endif()

external_project(
    DOWNLOAD URL ab95865ced3c123908bd2f1fe6843606
    https://github.com/luarocks/luarocks/archive/refs/tags/v3.11.1.tar.gz
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
