project(luajit LANGUAGES)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

assert_var_defined(EMULATE_READER)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    assert_var_defined(KODEBUG_LUAJIT)
    assert_var_defined(KODEBUG_LUAJIT_USE_SYSMALLOC)
    # Debugging is a go!
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|#CCDEBUG= -g|CCDEBUG= -g|" src/Makefile)
    # To-do: make this auto-trigger when Valgrind is installed
    #list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_VALGRIND|XCFLAGS+= -DLUAJIT_USE_VALGRIND|" src/Makefile)
    if(KODEBUG_LUAJIT_USE_SYSMALLOC)
        # Could this be helpful on Android?
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|" src/Makefile)
    endif()
    # Performance impact; not recommended unless required for something specific
    if(KODEBUG_LUAJIT)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_GDBJIT|XCFLAGS+= -DLUAJIT_USE_GDBJIT|" src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_APICHECK|XCFLAGS+= -DLUA_USE_APICHECK|" src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_ASSERT|XCFLAGS+= -DLUA_USE_ASSERT|" src/Makefile)
    endif()
endif()

if(NOT EMULATE_READER)
    assert_var_defined(BASE_CFLAGS)
    assert_var_defined(HOST_CFLAGS)

    # To recap: build its TARGET_CC from CROSS+CC, so CC need to be set to HOSTCC.
    set(CC "${HOSTCC}")
    set(CROSS "${CHOST}-")

    # Build its HOST/TARGET_CFLAGS based on CFLAGS, so we need
    # a neutral CFLAGS without arch
    set(TARGET_CFLAGS "${CFLAGS} -DLUAJIT_SECURITY_STRHASH=0 -DLUAJIT_SECURITY_STRID=0")

    # Add -m32 when cross compile on 64 bit host for 32bit target, Per:
    # http://luajit.org/install.html#cross
    execute_process(
        COMMAND "${HOSTCC}" -dumpmachine
        OUTPUT_VARIABLE HOST_CC_MACHINE
    )
    if((HOST_CC_MACHINE MATCHES "^.+64-.+$") AND (NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$"))
        set(HOST_CC "${HOSTCC} -m32")
    else()
        set(HOST_CC "${HOSTCC}")
    endif()

    get_filename_component(TARGET_SONAME "${LUAJIT_LIB}" NAME)

    set(BUILD_ARGS "CC=${CC}" "HOST_CC=${HOST_CC}")
    set(BUILD_ARGS ${BUILD_ARGS} "CFLAGS=${BASE_CFLAGS}" "HOST_CFLAGS=${HOST_CFLAGS}")
    set(BUILD_ARGS ${BUILD_ARGS} LDFLAGS= HOST_LDFLAGS= "TARGET_LDFLAGS=${LDFLAGS}")
    if(ANDROID)
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_SYS=Linux")
    elseif(WIN32)
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_SYS=Windows")
    endif()
    set(BUILD_ARGS ${BUILD_ARGS} "TARGET_AR=${CMAKE_AR} rcus" "TARGET_RANLIB=${CMAKE_RANLIB}")
    if(DARWIN)
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_STRIP=${CMAKE_STRIP}")
    else()
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_STRIP=${CMAKE_STRIP} --strip-unneeded")
    endif()
    set(BUILD_ARGS ${BUILD_ARGS} "TARGET_SONAME=${TARGET_SONAME}" "TARGET_CFLAGS=${TARGET_CFLAGS}" "CROSS=${CROSS}" amalg)
endif()

set(BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} ${BUILD_ARGS})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-makefile-tweaks.patch)
# Enable table.pack & table.unpack w/o the rest of the -DLUAJIT_ENABLE_LUA52COMPAT baggage...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-enable-table_pack.patch)

# Install executable.
if(NOT SKIP_LUAJIT_BIN)
    append_install_command(INSTALL_CMD "src/luajit")
endif()

set(LIB_SPEC luajit EXT .so)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
if(USE_LUAJIT_LIB)
    append_shared_lib_install_command(INSTALL_CMD "src/${LIB}" ${LIB_SPEC})
    list(APPEND BYPRODUCTS "${STAGING_DIR}/${PROJECT_NAME}/shared/${LIB}")
endif()

# Install static lib.
append_static_lib_install_command(INSTALL_CMD "src/libluajit.a" ${LIB_SPEC})
list(APPEND BYPRODUCTS "${STAGING_DIR}/${PROJECT_NAME}/static/libluajit.a")

# Install headers.
append_headers_install_command(
    INSTALL_CMD
    FROM src
    lauxlib.h luaconf.h lua.h lua.hpp luajit.h lualib.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/LuaJIT/LuaJIT
    69bbbf77363ceb00ad2653a7729a5c9e8316e61f
    ${SOURCE_DIR}
)

thirdparty_project(
    PATCH_COMMAND
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND COMMAND
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    INSTALL_BYPRODUCTS ${BYPRODUCTS}
)
