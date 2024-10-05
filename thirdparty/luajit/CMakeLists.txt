# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND PATCH_FILES koreader-luajit-makefile-tweaks.patch)
# Enable table.pack & table.unpack w/o the rest of the -DLUAJIT_ENABLE_LUA52COMPAT baggage...
list(APPEND PATCH_FILES koreader-luajit-enable-table_pack.patch)
if(ANDROID)
    list(APPEND PATCH_FILES koreader-luajit-mcode-reserve-hack.patch)
    # list(APPEND PATCH_FILES koreader-luajit-mcode-debug.patch)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
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
        TARGET_SHLDFLAGS=${LDFLAGS}
    )
    if(ANDROID)
        list(APPEND BUILD_ARGS TARGET_SYS=Linux)
    elseif(WIN32)
        list(APPEND BUILD_ARGS TARGET_SYS=Windows)
    endif()
    string(JOIN " " TARGET_STRIP ${STRIP_CMD})
    list(APPEND BUILD_ARGS TARGET_STRIP=${TARGET_STRIP})
endif()

if(APPLE)
    set(DYLIBNAME libluajit${LIB_EXT})
    list(APPEND BUILD_ARGS TARGET_DYLIBPATH=@rpath/${DYLIBNAME} INSTALL_DYLIBNAME=${DYLIBNAME})
else()
    set(SONAME libluajit${LIB_EXT})
    list(APPEND BUILD_ARGS TARGET_SONAME=${SONAME} INSTALL_SONAME=${SONAME})
endif()

list(APPEND BUILD_CMD COMMAND make ${BUILD_ARGS} amalg)

list(APPEND INSTALL_CMD COMMAND make ${BUILD_ARGS} install PREFIX=${STAGING_DIR})

if(NOT SKIP_LUAJIT_BIN)
    append_binary_install_command(INSTALL_CMD ${STAGING_DIR}/bin/luajit)
endif()

if(USE_LUAJIT_LIB)
    append_shared_lib_install_commands(INSTALL_CMD luajit)
else()
    # Prevent LUA modules from linking with the LuaJIT library.
    list(APPEND INSTALL_CMD COMMAND ${ISED} "s|-l\${libname}||" ${STAGING_DIR}/lib/pkgconfig/luajit.pc)
endif()

append_tree_install_commands(INSTALL_CMD src/jit jit)

external_project(
    DOWNLOAD GIT 97813fb924edf822455f91a5fbbdfdb349e5984f
    https://github.com/LuaJIT/LuaJIT
    PATCH_FILES ${PATCH_FILES}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
