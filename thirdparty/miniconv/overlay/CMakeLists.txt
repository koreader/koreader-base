cmake_minimum_required(VERSION 3.17.5)
project(miniconv LANGUAGES C)

add_library(iconv)
set_target_properties(iconv PROPERTIES C_VISIBILITY_PRESET hidden)
target_sources(iconv PRIVATE miniconv.c precompile.c)

install(TARGETS iconv)
install(FILES miniconv_config.h TYPE INCLUDE)
install(FILES miniconv.h TYPE INCLUDE RENAME iconv.h)
