cmake_minimum_required(VERSION 3.15)
project(koreader LANGUAGES C CXX)

include(koreader_targets)

foreach(NAME IN LISTS KOREADER_TARGETS)
    setup_target(${NAME})
endforeach()

# vim: foldmethod=marker foldlevel=0
