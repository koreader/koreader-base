cmake_minimum_required(VERSION 3.15)
project(luasocket LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LuaJIT luajit REQUIRED IMPORTED_TARGET)

add_library(luasocket STATIC)
set_target_properties(luasocket PROPERTIES C_VISIBILITY_PRESET hidden)
target_sources(luasocket PRIVATE
    src/auxiliar.c
    src/buffer.c
    src/compat.c
    src/except.c
    src/inet.c
    src/io.c
    src/options.c
    src/select.c
    src/tcp.c
    src/timeout.c
    src/udp.c
)
if(APPLE)
    target_sources(luasocket PRIVATE src/usocket.c)
elseif(LINUX)
    target_sources(luasocket PRIVATE src/usocket.c)
elseif(WIN32)
    # TODO
    message(FATAL_ERROR "Windows is not supported")
endif()
target_link_libraries(luasocket PRIVATE PkgConfig::LuaJIT)

foreach(MOD mcore score)
    if(BUILD_SHARED_LIBS)
        add_library(${MOD} MODULE)
    else()
        add_library(${MOD} STATIC)
    endif()
    set_target_properties(${MOD} PROPERTIES C_VISIBILITY_PRESET hidden PREFIX "")
    target_link_libraries(${MOD} PRIVATE luasocket PkgConfig::LuaJIT)
endforeach()
target_sources(mcore PRIVATE src/mime.c)
target_sources(score PRIVATE src/luasocket.c)
