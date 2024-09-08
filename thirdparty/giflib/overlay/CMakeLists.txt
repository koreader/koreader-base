cmake_minimum_required(VERSION 3.15)
project(giflib LANGUAGES C)

add_library(gif)
set_target_properties(gif PROPERTIES SOVERSION 7)
if(DEFINED ANDROID_STL)
    target_compile_definitions(gif PRIVATE -DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR)
endif()
target_sources(gif PRIVATE
    dgif_lib.c egif_lib.c
    gifalloc.c gif_err.c gif_font.c gif_hash.c
    openbsd-reallocarray.c quantize.c
)

install(TARGETS gif)
install(FILES gif_lib.h TYPE INCLUDE)
