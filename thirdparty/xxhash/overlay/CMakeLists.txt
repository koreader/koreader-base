cmake_minimum_required(VERSION 3.17.5)
project(xxhash LANGUAGES C)

add_library(xxhash)
set_target_properties(xxhash PROPERTIES SOVERSION 0)
target_sources(xxhash PRIVATE xxhash.c)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(xxhash PRIVATE XXH_NO_INLINE_HINTS)
endif()

install(TARGETS xxhash)
install(FILES xxh3.h xxhash.h DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
