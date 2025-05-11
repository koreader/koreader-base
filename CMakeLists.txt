cmake_minimum_required(VERSION 3.17.5)
project(koreader LANGUAGES C CXX)

include(${CMAKE_KOVARS})
include(koreader_targets)

foreach(NAME IN LISTS KOREADER_TARGETS)
    setup_target(${NAME})
endforeach()

# vim: foldmethod=marker foldlevel=0
