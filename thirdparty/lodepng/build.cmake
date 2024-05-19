cmake_minimum_required(VERSION 3.14)
project(lodepng LANGUAGES C)

file(WRITE lodepng.c "#include \"lodepng.cpp\"\n")
add_library(lodepng SHARED lodepng.c)
