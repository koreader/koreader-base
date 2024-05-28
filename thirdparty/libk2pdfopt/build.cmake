cmake_minimum_required(VERSION 3.15)
project(k2pdfopt LANGUAGES C CXX)

find_package(Leptonica REQUIRED)
find_package(Tesseract REQUIRED)

file(GLOB K2PDFOPTLIB_SRC k2pdfoptlib/*.c)
file(GLOB WILLUSLIB_SRC willuslib/*.c)
file(GLOB HDR *.h k2pdfoptlib/*.h willuslib/*.h)

add_library(k2pdfopt SHARED
    koptcrop.c koptimize.c koptocr.c koptreflow.c
    setting.c
    tesscapi.cpp
    ${K2PDFOPTLIB_SRC} ${WILLUSLIB_SRC}
)
set_target_properties(k2pdfopt PROPERTIES SOVERSION 2)
target_include_directories(k2pdfopt PRIVATE k2pdfoptlib willuslib .)
target_link_libraries(k2pdfopt PRIVATE m Leptonica::Leptonica Tesseract::Tesseract)

install(TARGETS k2pdfopt)
install(FILES ${HDR} DESTINATION ${CMAKE_INSTALL_PREFIX}/include/k2pdfopt)
