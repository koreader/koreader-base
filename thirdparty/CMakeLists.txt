PROJECT(koreader-base-thirdparty)
cmake_minimum_required(VERSION 3.5.1)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/cmake_modules")
include("koreader_thirdparty_common")

enable_language(C)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)

set(KO_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build/downloads)

message(STATUS "Thirdparty: zlib…")
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/zlib/CMakeLists.txt
    ${CMAKE_BINARY_DIR}/zlib-src/CMakeLists.txt
    @ONLY)
add_subdirectory("${CMAKE_BINARY_DIR}/zlib-src"
                 "${CMAKE_BINARY_DIR}/zlib-build")
message(STATUS "Thirdparty: zlib… DONE")
