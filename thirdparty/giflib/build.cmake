cmake_minimum_required(VERSION 3.14)
project(giflib LANGUAGES C)

add_library(gif SHARED
    lib/dgif_lib.c lib/egif_lib.c
    lib/gifalloc.c lib/gif_err.c lib/gif_font.c lib/gif_hash.c
    lib/openbsd-reallocarray.c lib/quantize.c)
set_target_properties(gif PROPERTIES SOVERSION 7)
if(DEFINED ANDROID_STL)
    target_compile_definitions(gif PRIVATE -DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR)
endif()
