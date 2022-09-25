project(luajit)
cmake_minimum_required(VERSION 3.5.1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
assert_var_defined(XCOMPILE)

if($ENV{KODEBUG})
    # Debugging is go!
    set(DBG_CMD "${ISED} 's|#CCDEBUG= -g|CCDEBUG= -g|' ${SOURCE_DIR}/src/Makefile")
    # To-do: make this auto-trigger when Valgrind is installed
    #set(DBG_CMD "${DBG_CMD} && ${ISED} 's|#XCFLAGS+= -DLUAJIT_USE_VALGRIND|XCFLAGS+= -DLUAJIT_USE_VALGRIND|' ${SOURCE_DIR}/src/Makefile")
    if($ENV{KODEBUG_LUAJIT_USE_SYSMALLOC})
        # Could this be helpful on Android?
        set(DBG_CMD "${DBG_CMD} && ${ISED} 's|#XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|XCFLAGS+= -DLUAJIT_USE_SYSMALLOC|' ${SOURCE_DIR}/src/Makefile")
    endif()
    # Performance impact; not recommended unless required for something specific
    if($ENV{KODEBUG_LUAJIT})
        set(DBG_CMD "${DBG_CMD} && ${ISED} 's|#XCFLAGS+= -DLUAJIT_USE_GDBJIT|XCFLAGS+= -DLUAJIT_USE_GDBJIT|' ${SOURCE_DIR}/src/Makefile")
        set(DBG_CMD "${DBG_CMD} && ${ISED} 's|#XCFLAGS+= -DLUA_USE_APICHECK|XCFLAGS+= -DLUA_USE_APICHECK|' ${SOURCE_DIR}/src/Makefile")
        set(DBG_CMD "${DBG_CMD} && ${ISED} 's|#XCFLAGS+= -DLUA_USE_ASSERT|XCFLAGS+= -DLUA_USE_ASSERT|' ${SOURCE_DIR}/src/Makefile")
    endif()

    set(BUILD_CMD_STR "${DBG_CMD} && ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}")
else()
    set(BUILD_CMD_STR "${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}")
endif()

if(${XCOMPILE})
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

    set(BUILD_CMD_STR "${BUILD_CMD_STR} CC=\"${CC}\" HOST_CC=\"${HOST_CC}\"")
    set(BUILD_CMD_STR "${BUILD_CMD_STR} CFLAGS=\"${BASE_CFLAGS}\" HOST_CFLAGS=\"${HOST_CFLAGS}\"")
    if(DEFINED LDFLAGS)
        set(BUILD_CMD_STR "${BUILD_CMD_STR} LDFLAGS=\"\" HOST_LDFLAGS=\"\" TARGET_LDFLAGS=\"${LDFLAGS}\"")
    endif()
    if(DEFINED TARGET_SYS)
        set(BUILD_CMD_STR "${BUILD_CMD_STR} TARGET_SYS=\"${TARGET_SYS}\"")
    endif()
    set(BUILD_CMD_STR "${BUILD_CMD_STR} TARGET_AR=\"$ENV{AR} rcus\" TARGET_RANLIB=\"$ENV{RANLIB}\" TARGET_STRIP=\"$ENV{STRIP} --strip-unneeded\" TARGET_SONAME=\"${TARGET_SONAME}\" TARGET_CFLAGS=\"${TARGET_CFLAGS}\" CROSS=\"${CROSS}\" amalg")
endif()

set(BUILD_CMD sh -c "${BUILD_CMD_STR}")

set(PATCH_CMD "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/koreader-luajit-makefile-tweaks.patch")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/LuaJIT/LuaJIT
    dad04f1754723e76ba9dcf9f401f3134a0cd3972
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD}
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
