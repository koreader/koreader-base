cmake_minimum_required(VERSION 3.17.5)
project(turbo LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(OpenSSL openssl REQUIRED IMPORTED_TARGET)

add_library(tffi_wrap)
target_include_directories(tffi_wrap PRIVATE deps/http-parser)
target_link_libraries(tffi_wrap PRIVATE PkgConfig::OpenSSL)
target_sources(tffi_wrap PRIVATE deps/http-parser/http_parser.c deps/turbo_ffi_wrap.c)
