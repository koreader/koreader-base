cmake_minimum_required(VERSION 3.15)
project(popen-noshell LANGUAGES C)

add_library(popen_noshell STATIC popen_noshell.c)

install(TARGETS popen_noshell)
install(FILES popen_noshell.h TYPE INCLUDE)
