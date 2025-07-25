cmake_minimum_required(VERSION 3.17.5)
project(lanes LANGUAGES C)

set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LuaJIT luajit REQUIRED IMPORTED_TARGET)

if(BUILD_SHARED_LIBS)
    add_library(core MODULE)
else()
    add_library(core STATIC)
endif()
set_target_properties(core PROPERTIES C_VISIBILITY_PRESET hidden PREFIX "")
target_link_libraries(core PRIVATE PkgConfig::LuaJIT Threads::Threads m)
if(ANDROID)
    target_link_libraries(core PRIVATE log)
endif()
target_sources(core PRIVATE
    src/lanes.c
    src/cancel.c
    src/compat.c
    src/threading.c
    src/tools.c
    src/state.c
    src/linda.c
    src/deep.c
    src/keeper.c
    src/universe.c
)
