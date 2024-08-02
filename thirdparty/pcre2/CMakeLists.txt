list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DPCRE2_BUILD_PCRE2GREP=FALSE
    -DPCRE2_BUILD_TESTS=FALSE
    -DPCRE2_DISABLE_PERCENT_ZT=TRUE
    # Disable some dependencies (which will automatically
    # disable the corresponding project optional features).
    -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Readline=TRUE
    -DCMAKE_DISABLE_FIND_PACKAGE_Editline=TRUE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD URL 9d1fe11e2e919c7b395e3e8f0a5c3eec
    https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.bz2
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
