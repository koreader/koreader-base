cmake_minimum_required(VERSION 3.15)
project(minizip LANGUAGES C)

file(GLOB AES_SRC aes/*.c)
file(GLOB AES_HDR aes/*.h)

add_library(aes STATIC ${AES_SRC})
target_compile_definitions(aes PRIVATE -DHAVE_AES)
target_compile_options(aes PRIVATE -Wno-error=implicit-function-declaration)

install(TARGETS aes)
install(FILES ${AES_HDR} DESTINATION ${CMAKE_INSTALL_PREFIX}/include/aes)
