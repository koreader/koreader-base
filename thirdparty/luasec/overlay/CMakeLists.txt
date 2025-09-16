cmake_minimum_required(VERSION 3.17.5)
project(luasec LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LuaJIT luajit REQUIRED IMPORTED_TARGET)
pkg_check_modules(OpenSSL openssl REQUIRED IMPORTED_TARGET)

if(BUILD_SHARED_LIBS)
    add_library(ssl MODULE)
else()
    add_library(ssl STATIC)
endif()
set_target_properties(ssl PROPERTIES C_VISIBILITY_PRESET hidden PREFIX "")
target_compile_definitions(ssl PRIVATE -DWITH_LUASOCKET)
target_include_directories(ssl PRIVATE ${CMAKE_INSTALL_PREFIX}/include)
target_link_libraries(ssl PRIVATE
    ${CMAKE_INSTALL_PREFIX}/lib/libluasocket.a
    PkgConfig::LuaJIT
    PkgConfig::OpenSSL
)
target_sources(ssl PRIVATE
    src/options.c
    src/x509.c
    src/context.c
    src/ssl.c
    src/config.c
    src/ec.c
)
