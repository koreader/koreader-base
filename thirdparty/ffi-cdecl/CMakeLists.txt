# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

find_executable(GCC "GNU C compiler" gcc --version)
find_executable(GXX "GNU C++ compiler" g++ --version)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(PLUGIN_CC ${CMAKE_C_COMPILER})
    set(PLUGIN_CXX ${CMAKE_CXX_COMPILER})
else()
    set(PLUGIN_CC ${GCC})
    set(PLUGIN_CXX ${GXX})
endif()

if(PLUGIN_CC)
    if(NOT DEFINED CACHE{PLUGIN_CC_PLUGIN_DIR})
        ensure_execute_process(COMMAND ${PLUGIN_CC} -print-file-name=plugin OUTPUT_VARIABLE PLUGIN_CC_PLUGIN_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(NOT EXISTS ${PLUGIN_CC_PLUGIN_DIR}/include/gcc-plugin.hh)
            set(PLUGIN_CC_PLUGIN_DIR NOTFOUND)
        endif()
        message(STATUS "Looking for ${PLUGIN_CC} plugin directory - ${PLUGIN_CC_PLUGIN_DIR}")
        set(PLUGIN_CC_PLUGIN_DIR ${PLUGIN_CC_PLUGIN_DIR} CACHE INTERNAL "${PLUGIN_CC} plugin directory")
    endif()
    if(NOT DEFINED CACHE{PLUGIN_CC_MACHINE})
        ensure_execute_process(COMMAND ${PLUGIN_CC} -dumpmachine OUTPUT_VARIABLE PLUGIN_CC_MACHINE OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(PLUGIN_CC_MACHINE ${PLUGIN_CC_MACHINE} CACHE INTERNAL "${PLUGIN_CC} machine")
    endif()
endif()

set(MAKE_CMD make CROSSCC=${PLUGIN_CC} CROSSCXX=${PLUGIN_CXX} HOSTCC=${GCC} CROSS_DIR= GCCPLUGIN_DIR=${PLUGIN_CC_PLUGIN_DIR})
if(EMULATE_READER)
    # Native compiler, use our own luajit.
    set(LUACFLAGS "-I${STAGING_DIR}/include/luajit-2.1")
    set(LUALIBS "${STAGING_DIR}/lib/libluajit-5.1.a -ldl -lm")
else()
    # We're building for a cross-compiler, let's hope Lua is installed
    # in the standard locations (as pkg-config can't be used since
    # we've overriden its environment in `Makefile.defs`). 🤞
    find_path(
        LUA_INCLUDE_DIR
        NAMES lua.h
        PATHS /usr/local/include /usr/include
        PATH_SUFFIXES luajit-2.1 lua5.4 lua5.3 lua5.2
        NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH
        NO_CMAKE_ENVIRONMENT_PATH NO_SYSTEM_ENVIRONMENT_PATH
        NO_CMAKE_SYSTEM_PATH NO_CMAKE_INSTALL_PREFIX NO_CMAKE_FIND_ROOT_PATH
    )
    find_library(
        LUA_LIBRARIES
        NAMES libluajit-5.1.so liblua5.4.so liblua5.3.so liblua5.2.so liblua.so
        PATHS /usr/local/lib /usr/lib
        PATH_SUFFIXES x86_64-linux-gnu
        NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH
        NO_CMAKE_ENVIRONMENT_PATH NO_SYSTEM_ENVIRONMENT_PATH
        NO_CMAKE_SYSTEM_PATH NO_CMAKE_INSTALL_PREFIX NO_CMAKE_FIND_ROOT_PATH
    )
    if(LUA_INCLUDE_DIR AND LUA_LIBRARIES)
        set(LUACFLAGS "-I${LUA_INCLUDE_DIR}")
        set(LUALIBS "${LUA_LIBRARIES}")
    else()
        # Last chance fallback…
        set(LUACFLAGS "")
        set(LUALIBS "-llua")
    endif()
endif()
list(APPEND MAKE_CMD LUAMOD= LUACFLAGS=${LUACFLAGS} LUALIBS=${LUALIBS})
if(APPLE)
    list(APPEND MAKE_CMD "CPPFLAGS=-I${BREW_PREFIX}/include -DENABLE_BUILD_WITH_CXX" "INSTALL_L=install -m 644")
endif()

list(APPEND PATCH_CMD COMMAND ${MAKE_CMD} patch)

list(APPEND BUILD_CMD COMMAND ${MAKE_CMD})

# Install GCC plugin.
list(APPEND INSTALL_CMD COMMAND ${MAKE_CMD} -C gcc-lua install DESTDIR=${STAGING_DIR} INSTALL_GCC_PLUGIN=/lib/gcc/plugin)

# Install Lua code.
set(INSTALL_LUADIR ${STAGING_DIR}/share/lua/5.1)
append_install_commands(INSTALL_CMD ffi-cdecl.lua DESTINATION ${INSTALL_LUADIR})
append_install_commands(INSTALL_CMD gcc-lua-cdecl/ffi-cdecl/ffi-cdecl.lua DESTINATION ${INSTALL_LUADIR}/ffi-cdecl)
append_install_commands(INSTALL_CMD gcc-lua-cdecl/gcc/cdecl.lua DESTINATION ${INSTALL_LUADIR}/gcc)

# Install headers.
append_install_commands(
    INSTALL_CMD DESTINATION ${STAGING_DIR}/include/ffi-cdecl
    gcc-lua-cdecl/ffi-cdecl/C.c
    gcc-lua-cdecl/ffi-cdecl/C99.c
    gcc-lua-cdecl/ffi-cdecl/ffi-cdecl.h
)

set(COMMON_CFLAGS -std=gnu11 -fno-builtin)
set(COMMON_CXXFLAGS -std=gnu++17 -fno-builtin)
set(TARGET_FLAGS)
set(PLUGIN_FLAGS -Wno-attributes)
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    list(APPEND TARGET_FLAGS -fno-blocks)
    list(APPEND PLUGIN_FLAGS -D_Nonnull='' -D_Nullable='')
endif()
# Add -m32 when cross compiling on a 64bit host for a 32bit target.
if(PLUGIN_CC_MACHINE MATCHES "^.+64-.+$" AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES ".+64$")
    list(APPEND PLUGIN_FLAGS -m32)
endif()
string(JOIN " " TARGET_CC ${CMAKE_C_COMPILER} ${COMMON_CFLAGS} ${TARGET_FLAGS})
string(JOIN " " TARGET_CXX ${CMAKE_CXX_COMPILER} ${COMMON_CXXFLAGS} ${TARGET_FLAGS})
string(JOIN " " PLUGIN_CC ${PLUGIN_CC} ${COMMON_CFLAGS} ${PLUGIN_FLAGS})
string(JOIN " " PLUGIN_CXX ${PLUGIN_CXX} ${COMMON_CXXFLAGS} ${PLUGIN_FLAGS})

# Install helper.
list(APPEND INSTALL_CMD COMMAND mkdir -p ${STAGING_DIR}/bin)
list(APPEND INSTALL_CMD COMMAND
    sh -c "in=\"$1\" out=\"$2\" && shift 2 && sed \"$@\" <\"$in\" >\"$out\"" sed
    ${CMAKE_CURRENT_SOURCE_DIR}/ffi-cdecl.sh.in ${STAGING_DIR}/bin/ffi-cdecl
    -e "s,@TARGET_CC@,${TARGET_CC}," -e "s,@TARGET_CXX@,${TARGET_CXX},"
    -e "s,@PLUGIN_CC@,${PLUGIN_CC}," -e "s,@PLUGIN_CXX@,${PLUGIN_CXX},"
    -e "s,@PREFIX@,${STAGING_DIR},"
)
list(APPEND INSTALL_CMD COMMAND chmod +x ${STAGING_DIR}/bin/ffi-cdecl)

external_project(
    DOWNLOAD GIT 9c9d46a61cac1a5073c07cc5163b97e75d5b8a7e
    https://github.com/koreader/ffi-cdecl.git
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
