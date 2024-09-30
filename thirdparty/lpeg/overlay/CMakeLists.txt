cmake_minimum_required(VERSION 3.15)
project(lpeg LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LuaJIT luajit REQUIRED IMPORTED_TARGET)

if(BUILD_SHARED_LIBS)
    add_library(lpeg MODULE)
else()
    add_library(lpeg STATIC)
endif()
set_target_properties(lpeg PROPERTIES
    C_STANDARD 99
    PREFIX ""
)
target_link_libraries(lpeg PRIVATE PkgConfig::LuaJIT)
target_sources(lpeg PRIVATE
    lpcap.c
    lpcode.c
    lpcset.c
    lpprint.c
    lptree.c
    lpvm.c
)
