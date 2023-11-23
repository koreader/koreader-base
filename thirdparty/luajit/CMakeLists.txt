cmake_minimum_required(VERSION 3.5.1)
project(luajit)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
assert_var_defined(XCOMPILE)

if($ENV{KODEBUG})
    # Debugging is a go!
    list(APPEND PATCH_CMD COMMAND ${ISED} "s|#CCDEBUG= -g|CCDEBUG= -g|" ${SOURCE_DIR}/src/Makefile)
    # To-do: make this auto-trigger when Valgrind is installed
    #list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_VALGRIND|XCFLAGS+= -DLUAJIT_USE_VALGRIND|" ${SOURCE_DIR}/src/Makefile)
    if(DEFINED ENV{KODEBUG_LUAJIT_USE_SYSMALLOC})
        # Could this be helpful on Android?
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|" ${SOURCE_DIR}/src/Makefile)
    endif()
    # Performance impact; not recommended unless required for something specific
    if(DEFINED ENV{KODEBUG_LUAJIT})
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUAJIT_USE_GDBJIT|XCFLAGS+= -DLUAJIT_USE_GDBJIT|" ${SOURCE_DIR}/src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_APICHECK|XCFLAGS+= -DLUA_USE_APICHECK|" ${SOURCE_DIR}/src/Makefile)
        list(APPEND PATCH_CMD COMMAND ${ISED} "s|#XCFLAGS+= -DLUA_USE_ASSERT|XCFLAGS+= -DLUA_USE_ASSERT|" ${SOURCE_DIR}/src/Makefile)
    endif()
endif()

if(XCOMPILE)
    assert_var_defined(HOST_CFLAGS)
    assert_var_defined(CC)
    assert_var_defined(BASE_CFLAGS)
    assert_var_defined(HOST_CFLAGS)
    assert_var_defined(LDFLAGS)
    assert_var_defined(TARGET_SONAME)
    assert_var_defined(TARGET_CFLAGS)
    assert_var_defined(CROSS)

    # To recap: build its TARGET_CC from CROSS+CC, so we need HOSTCC in CC.
    # Build its HOST/TARGET_CFLAGS based on CFLAGS, so we need
    # a neutral CFLAGS without arch
    execute_process(
        COMMAND "${CC}" -dumpmachine
        OUTPUT_VARIABLE HOST_CC_MACHINE
    )
    if((HOST_CC_MACHINE MATCHES "^.+64-.+$") AND (NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$"))
        # Add -m32 when cross compile on 64 bit host for 32bit target, Per:
        # http://luajit.org/install.html#cross
        set(HOST_CC "${CC} -m32")
    else()
        set(HOST_CC "${CC}")
    endif()

    set(BUILD_ARGS "CC=${CC}" "HOST_CC=${HOST_CC}")
    set(BUILD_ARGS ${BUILD_ARGS} "CFLAGS=${BASE_CFLAGS}" "HOST_CFLAGS=${HOST_CFLAGS}")
    if(DEFINED LDFLAGS)
        set(BUILD_ARGS ${BUILD_ARGS} LDFLAGS= HOST_LDFLAGS= "TARGET_LDFLAGS=${LDFLAGS}")
    endif()
    if(DEFINED TARGET_SYS)
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_SYS=${TARGET_SYS}")
    endif()
    set(BUILD_ARGS ${BUILD_ARGS} "TARGET_AR=$ENV{AR} rcus" "TARGET_RANLIB=$ENV{RANLIB}")
    if(DEFINED ENV{DARWIN})
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_STRIP=$ENV{STRIP}")
    else()
        set(BUILD_ARGS ${BUILD_ARGS} "TARGET_STRIP=$ENV{STRIP} --strip-unneeded")
    endif()
    set(BUILD_ARGS ${BUILD_ARGS} "TARGET_SONAME=${TARGET_SONAME}" "TARGET_CFLAGS=${TARGET_CFLAGS}" "CROSS=${CROSS}" amalg)
endif()

set(BUILD_CMD ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} ${BUILD_ARGS})

list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-makefile-tweaks.patch)
# Enable table.pack & table.unpack w/o the rest of the -DLUAJIT_ENABLE_LUA52COMPAT baggage...
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-enable-table_pack.patch)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/LuaJIT/LuaJIT
    43d0a19158ceabaa51b0462c1ebc97612b420a2e
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
