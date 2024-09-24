cmake_minimum_required(VERSION 3.15)
project(turbo LANGUAGES C)

find_package(OpenSSL REQUIRED)

add_library(tffi_wrap)
target_include_directories(tffi_wrap PRIVATE deps/http-parser)
target_link_libraries(tffi_wrap PRIVATE OpenSSL::Crypto OpenSSL::SSL)
target_sources(tffi_wrap PRIVATE deps/http-parser/http_parser.c deps/turbo_ffi_wrap.c)
