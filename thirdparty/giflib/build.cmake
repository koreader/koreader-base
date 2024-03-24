cmake_minimum_required(VERSION 3.14)
project(giflib LANGUAGES C)

add_library(gif SHARED
    dgif_lib.c egif_lib.c
    gifalloc.c gif_err.c gif_font.c gif_hash.c
    openbsd-reallocarray.c quantize.c)
set_target_properties(gif PROPERTIES SOVERSION 7)
if(DEFINED ANDROID_STL)
    target_compile_definitions(gif PRIVATE -DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR)
endif()
