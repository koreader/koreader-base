cmake_minimum_required(VERSION 3.15)
project(lodepng LANGUAGES C)

file(WRITE lodepng.c "#include \"lodepng.cpp\"\n")
add_library(lodepng SHARED lodepng.c)

install(TARGETS lodepng)
install(FILES lodepng.h TYPE INCLUDE)
