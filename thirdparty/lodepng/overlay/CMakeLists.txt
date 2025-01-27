cmake_minimum_required(VERSION 3.16.3)
project(lodepng LANGUAGES C)

file(WRITE lodepng.c "#include \"lodepng.cpp\"\n")
add_library(lodepng)
target_sources(lodepng PRIVATE lodepng.c)
target_compile_definitions(lodepng PRIVATE LODEPNG_NO_COMPILE_ANCILLARY_CHUNKS)

install(TARGETS lodepng)
install(FILES lodepng.h TYPE INCLUDE)
