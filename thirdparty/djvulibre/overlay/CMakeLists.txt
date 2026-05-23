cmake_minimum_required(VERSION 3.17.5)
project(djvulibre LANGUAGES C CXX)

include(CMakePushCheckState)
include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
include(CheckIncludeFile)
include(CheckIncludeFiles)
include(CheckSymbolExists)
include(CheckTypeSize)

set(PACKAGE_VERSION 3.5.29)

set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)
set(HAVE_PTHREAD ${CMAKE_USE_PTHREADS_INIT})

find_package(PkgConfig REQUIRED)
pkg_check_modules(JPeg libjpeg REQUIRED IMPORTED_TARGET)

foreach(HDR
        cpuid.h
        dirent.h
        iconv.h
        inttypes.h
        ndir.h
        new.h
        stdint.h
        sys/dir.h
        sys/mman.h
        sys/ndir.h
        sys/time.h
        wchar.h
    )
    string(REGEX REPLACE "[./]" "_" VAR HAVE_${HDR})
    string(TOUPPER ${VAR} VAR)
    check_include_file(${HDR} ${VAR})
endforeach()

check_include_files("sys/time.h;time.h" TIME_WITH_SYS_TIME)

set(SYM_CHECKS
    getpwuid  "sys/types.h pwd.h"
    iconv     "iconv.h"
    mkstemp   "stdlib.h"
    mmap      "sys/mman.h"
    snprintf  "stdio.h"
    strerror  "string.h"
    vsnprintf "stdio.h"
    wcrtomb   "wchar.h"
)
while(SYM_CHECKS)
    list(POP_FRONT SYM_CHECKS SYM HEADERS)
    string(TOUPPER HAVE_${SYM} VAR)
    string(REPLACE " " ";" HEADERS ${HEADERS})
    check_symbol_exists(${SYM} "${HEADERS}" ${VAR})
endwhile()

if(HAVE_WCHAR_H)
    cmake_push_check_state()
    set(CMAKE_EXTRA_INCLUDE_FILES "wchar.h")
    check_type_size(mbstate_t MBSTATE_T_SIZE)
    if(NOT MBSTATE_T_SIZE STREQUAL "")
        set(HAVE_MBSTATE_T TRUE)
    endif()
    cmake_pop_check_state()
endif()

cmake_push_check_state()
set(CMAKE_EXTRA_INCLUDE_FILES "stddef.h")
check_type_size(wchar_t WCHAR_T_SIZE)
if(NOT WCHAR_T_SIZE STREQUAL "")
    set(HAVE_WCHAR_T TRUE)
endif()
cmake_pop_check_state()

check_c_source_compiles([=[
__thread int i;
int main(void) {
    return i;
}
]=] HAVE_GCCTLS)

check_cxx_source_compiles([=[
int main(void) {
    try { throw  1; } catch (int i) { return i; }
}
]=] HAVE_EXCEPTIONS)

check_cxx_source_compiles([=[
static int volatile l;
int main(void) {
    __sync_lock_test_and_set(&l,1);
    __sync_lock_release(&l);
    __sync_add_and_fetch(&l,1);
    __sync_bool_compare_and_swap(&l,&l,1);
    __sync_synchronize();
    return 0;
}
]=] HAVE_INTEL_ATOMIC_BUILTINS)

check_c_source_compiles([=[
long long int i;
int main(void) {
    return i;
}
]=] HAVE_LONG_LONG_INT)

check_cxx_source_compiles([=[
template<class T, int N> class A
{ public:
  template<int N2> A<T,N> operator=(const A<T,N2>& z) { return A<T,N>(); }
};
int main(void) {
    A<double,4> x; A<double,7> y;
    x = y;
    return 0;
}
]=] HAVE_MEMBER_TEMPLATES)

check_cxx_source_compiles([=[
namespace Outer { namespace Inner { int i = 0; }}
int main(void) {
    using namespace Outer::Inner;
    return i;
}
]=] HAVE_NAMESPACES)

check_cxx_source_compiles([=[
#include <new>
struct X { int a; X(int a):a(a){} };
X* foo(void *x) { return new(x) X(2); }
int main(void) {
    return 0;
}
]=] HAVE_STDINCLUDES)

check_cxx_source_compiles([=[
template<typename T>class X {public:X(){}};
int main(void) {
    X<float> z;
    return 0;
}
]=] HAVE_TYPENAME)

configure_file(config.h.in config.h)

add_library(djvulibre
    libdjvu/Arrays.cpp
    libdjvu/atomic.cpp
    libdjvu/BSByteStream.cpp
    libdjvu/BSEncodeByteStream.cpp
    libdjvu/ByteStream.cpp
    libdjvu/DataPool.cpp
    libdjvu/ddjvuapi.cpp
    libdjvu/debug.cpp
    libdjvu/DjVmDir.cpp
    libdjvu/DjVmDir0.cpp
    libdjvu/DjVmDoc.cpp
    libdjvu/DjVmNav.cpp
    libdjvu/DjVuAnno.cpp
    libdjvu/DjVuDocEditor.cpp
    libdjvu/DjVuDocument.cpp
    libdjvu/DjVuDumpHelper.cpp
    libdjvu/DjVuErrorList.cpp
    libdjvu/DjVuFile.cpp
    libdjvu/DjVuFileCache.cpp
    libdjvu/DjVuGlobal.cpp
    libdjvu/DjVuGlobalMemory.cpp
    libdjvu/DjVuImage.cpp
    libdjvu/DjVuInfo.cpp
    libdjvu/DjVuMessage.cpp
    libdjvu/DjVuMessageLite.cpp
    libdjvu/DjVuNavDir.cpp
    libdjvu/DjVuPalette.cpp
    libdjvu/DjVuPort.cpp
    libdjvu/DjVuText.cpp
    libdjvu/DjVuToPS.cpp
    libdjvu/GBitmap.cpp
    libdjvu/GContainer.cpp
    libdjvu/GException.cpp
    libdjvu/GIFFManager.cpp
    libdjvu/GMapAreas.cpp
    libdjvu/GOS.cpp
    libdjvu/GPixmap.cpp
    libdjvu/GRect.cpp
    libdjvu/GScaler.cpp
    libdjvu/GSmartPointer.cpp
    libdjvu/GString.cpp
    libdjvu/GThreads.cpp
    libdjvu/GUnicode.cpp
    libdjvu/GURL.cpp
    libdjvu/IFFByteStream.cpp
    libdjvu/IW44EncodeCodec.cpp
    libdjvu/IW44Image.cpp
    libdjvu/JB2EncodeCodec.cpp
    libdjvu/JB2Image.cpp
    libdjvu/JPEGDecoder.cpp
    libdjvu/miniexp.cpp
    libdjvu/MMRDecoder.cpp
    libdjvu/MMX.cpp
    libdjvu/UnicodeByteStream.cpp
    libdjvu/XMLParser.cpp
    libdjvu/XMLTags.cpp
    libdjvu/ZPCodec.cpp
)
set_target_properties(djvulibre PROPERTIES SOVERSION 21)
# Fix symbols visibility.
set_target_properties(djvulibre PROPERTIES
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN TRUE
)
target_compile_definitions(djvulibre PRIVATE HAVE_CONFIG_H)
target_compile_options(djvulibre PRIVATE -Wall)
# Unbreak build with GCC 16 at higher optimization levels (-O2 and above).
target_compile_options(djvulibre PRIVATE -fno-strict-aliasing)
target_include_directories(djvulibre PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(djvulibre PRIVATE PkgConfig::JPeg Threads::Threads)

install(TARGETS djvulibre)
install(FILES
    libdjvu/ddjvuapi.h
    libdjvu/miniexp.h
    DESTINATION ${CMAKE_INSTALL_PREFIX}/include/libdjvu
)
