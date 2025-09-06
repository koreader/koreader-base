cmake_minimum_required(VERSION 3.17.5)
project(koreader-lfs LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LuaJIT luajit REQUIRED IMPORTED_TARGET)

if(BUILD_SHARED_LIBS)
    add_library(koreader-lfs MODULE)
else()
    add_library(koreader-lfs STATIC)
endif()
set_target_properties(koreader-lfs PROPERTIES C_VISIBILITY_PRESET hidden)
target_link_libraries(koreader-lfs PRIVATE PkgConfig::LuaJIT)
target_sources(koreader-lfs PRIVATE src/lfs.c)
