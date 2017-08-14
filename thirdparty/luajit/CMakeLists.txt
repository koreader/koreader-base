PROJECT(luajit)
cmake_minimum_required(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C)

ep_get_source_dir(SOURCE_DIR)
assert_var_defined(XCOMPILE)

if(${XCOMPILE})
    assert_var_defined(HOST_CFLAGS)
    assert_var_defined(CC)
    assert_var_defined(BASE_CFLAGS)
    assert_var_defined(HOST_CFLAGS)
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
    if(HOST_CC_MACHINE MATCHES "^x86_64*")
        # Add -m32 when cross compile on 64 bit host for 32bit target, Per:
        # http://luajit.org/install.html#cross
        set(HOST_CC "${CC} -m32")
    else()
        set(HOST_CC "${CC}")
    endif()

    set(BUILD_CMD_STR "$(MAKE) -j${PARALLEL_JOBS} CC=\"${CC}\" HOST_CC=\"${HOST_CC}\"")
    set(BUILD_CMD_STR "${BUILD_CMD_STR} CFLAGS=\"${BASE_CFLAGS}\" HOST_CFLAGS=\"${HOST_CFLAGS}\"")
    if(DEFINED LDFLAGS)
        set(BUILD_CMD_STR "${BUILD_CMD_STR} LDFLAGS=\"${LDFLAGS}\"")
    endif()
    if(DEFINED TARGET_SYS)
        set(BUILD_CMD_STR "${BUILD_CMD_STR} TARGET_SYS=\"${TARGET_SYS}\"")
    endif()
    set(BUILD_CMD_STR "${BUILD_CMD_STR} TARGET_SONAME=\"${TARGET_SONAME}\" TARGET_CFLAGS=\"${TARGET_CFLAGS}\" TARGET_FLAGS=\"-DLUAJIT_NO_LOG2 -DLUAJIT_NO_EXP2\" CROSS=\"${CROSS}\" amalg")
    set(BUILD_CMD sh -c ${BUILD_CMD_STR})
else()
    set(BUILD_CMD $(MAKE) -j${PARALLEL_JOBS})
endif()


ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/LuaJIT/LuaJIT
    v2.1.0-beta3
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_IN_SOURCE 1
    # skip configure
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${BUILD_CMD}
    # skip install
    INSTALL_COMMAND ""
)
