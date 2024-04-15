cmake_minimum_required(VERSION 3.15)
project(luajit LANGUAGES)

include(koreader_thirdparty_common)
include(koreader_thirdparty_git)

# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-makefile-tweaks.patch)
# Enable table.pack & table.unpack w/o the rest of the -DLUAJIT_ENABLE_LUA52COMPAT baggage...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-enable-table_pack.patch)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    # Debugging is a go!
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|#CCDEBUG= -g|CCDEBUG= -g|" src/Makefile)
    # To-do: make this auto-trigger when Valgrind is installed
    #list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_VALGRIND|XCFLAGS+= -DLUAJIT_USE_VALGRIND|" src/Makefile)
    if(DEFINED ENV{KODEBUG_LUAJIT_USE_SYSMALLOC})
        # Could this be helpful on Android?
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|" src/Makefile)
    endif()
    # Performance impact; not recommended unless required for something specific
    if(DEFINED ENV{KODEBUG_LUAJIT})
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_GDBJIT|XCFLAGS+= -DLUAJIT_USE_GDBJIT|" src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_APICHECK|XCFLAGS+= -DLUA_USE_APICHECK|" src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_ASSERT|XCFLAGS+= -DLUA_USE_ASSERT|" src/Makefile)
    endif()
endif()

if(EMULATE_READER)
    string(APPEND CFLAGS " -fno-fast-math")
    append_autotools_vars(BUILD_ARGS)
else()
    assert_var_defined(BASE_CFLAGS)
    assert_var_defined(HOSTCC)
    assert_var_defined(HOSTCFLAGS)

    # To recap, luajit builds:
    # - its TARGET_CC from CROSS+CC, so CC need to be set to HOSTCC.
    # - its HOST/TARGET_CFLAGS based on CFLAGS, so we need a neutral
    #   CFLAGS without arch.

    # Add -m32 when cross compile on 64 bit host for 32bit target,
    # (Per: http://luajit.org/install.html#cross).
    execute_process(
        COMMAND ${HOSTCC} -dumpmachine
        OUTPUT_VARIABLE HOST_CC_MACHINE
    )
    if((HOST_CC_MACHINE MATCHES "^.+64-.+$") AND (NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$"))
        set(HOST_CC "${HOSTCC} -m32")
    else()
        set(HOST_CC ${HOSTCC})
    endif()

    list(APPEND BUILD_ARGS
        "CROSS=${CCACHE} ${CHOST}-"
        CC=${HOSTCC}
        CFLAGS=${BASE_CFLAGS}
        LDFLAGS=
        "HOST_CC=${CCACHE} ${HOST_CC}"
        HOST_CFLAGS=${HOSTCFLAGS}
        HOST_LDFLAGS=
        "TARGET_AR=${AR} rcus"
        "TARGET_CFLAGS=${CFLAGS} -DLUAJIT_SECURITY_STRHASH=0 -DLUAJIT_SECURITY_STRID=0"
        TARGET_LDFLAGS=${LDFLAGS}
        TARGET_RANLIB=${RANLIB}
    )
    if(ANDROID)
        list(APPEND BUILD_ARGS TARGET_SYS=Linux)
    elseif(WIN32)
        list(APPEND BUILD_ARGS TARGET_SYS=Windows)
    endif()
    if(DARWIN)
        list(APPEND BUILD_ARGS TARGET_STRIP=${STRIP})
    else()
        list(APPEND BUILD_ARGS "TARGET_STRIP=${STRIP} --strip-unneeded")
    endif()
endif()

if(DARWIN)
    list(APPEND BUILD_ARGS TARGET_DYLIBPATH=@rpath/libluajit${LIB_EXT})
else()
    list(APPEND BUILD_ARGS TARGET_SONAME=libluajit${LIB_EXT})
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} ${BUILD_ARGS} amalg)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} ${BUILD_ARGS} install PREFIX=/ DESTDIR=${INSTALL_DIR})

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/LuaJIT/LuaJIT
    d06beb0480c5d1eb53b3343e78063950275aa281
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
