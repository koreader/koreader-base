cmake_minimum_required(VERSION 3.17.5)
project(sqlite LANGUAGES C)

include(CheckIncludeFile)
include(CheckSymbolExists)

set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

set(CMAKE_REQUIRED_FLAGS "-D_GNU_SOURCE -D_REENTRANT")

set(DEFINITIONS _GNU_SOURCE _REENTRANT)

set(CHECKS
    "inttypes.h" HAVE_INTTYPES_H
    "stdint.h"   HAVE_STDINT_H
)
while(CHECKS)
    list(POP_FRONT CHECKS HEADER DEFINE)
    check_include_file(${HEADER} ${DEFINE})
    if(${DEFINE})
        list(APPEND DEFINITIONS ${DEFINE})
    endif()
endwhile()

set(CHECKS
    fdatasync       "unistd.h" HAVE_FDATASYNC
    gmtime_r        "time.h"   HAVE_GMTIME_R
    localtime_r     "time.h"   HAVE_LOCALTIME_R
    posix_fallocate "fcntl.h"  HAVE_POSIX_FALLOCATE
    strchrnul       "string.h" HAVE_STRCHRNUL
    strerror_r      "string.h" HAVE_STRERROR_R
    usleep          "unistd.h" HAVE_USLEEP
)
while(CHECKS)
    list(POP_FRONT CHECKS SYMBOL HEADER DEFINE)
    check_symbol_exists(${SYMBOL} ${HEADER} ${DEFINE})
    if(${DEFINE})
        list(APPEND DEFINITIONS ${DEFINE})
    endif()
endwhile()

add_library(sqlite3)
set_target_properties(sqlite3 PROPERTIES SOVERSION 0)
target_compile_definitions(sqlite3 PRIVATE
    ${DEFINITIONS}
    SQLITE_DEFAULT_MEMSTATUS=0
    SQLITE_DEFAULT_WAL_SYNCHRONOUS=1
    SQLITE_ENABLE_FTS4
    SQLITE_ENABLE_FTS5
    SQLITE_ENABLE_GEOPOLY
    SQLITE_ENABLE_MATH_FUNCTIONS
    SQLITE_ENABLE_RTREE
    SQLITE_LIKE_DOESNT_MATCH_BLOBS
    SQLITE_MAX_EXPR_DEPTH=0
    SQLITE_OMIT_DECLTYPE
    SQLITE_OMIT_DEPRECATED
    SQLITE_OMIT_LOAD_EXTENSION=1
    SQLITE_OMIT_PROGRESS_CALLBACK
    SQLITE_OMIT_SHARED_CACHE
    SQLITE_THREADSAFE=1
    SQLITE_USE_ALLOCA
)
target_sources(sqlite3 PRIVATE sqlite3.c)
target_link_libraries(sqlite3 m Threads::Threads)

install(TARGETS sqlite3)
install(FILES sqlite3.h sqlite3ext.h TYPE INCLUDE)
