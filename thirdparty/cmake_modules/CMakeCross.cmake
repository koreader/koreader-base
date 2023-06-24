# CMake Cross ToolChain config file. Adapted from Debian's dpkg-cross ;).
# c.f., https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling-toolchain
# NOTE: Remember that CMake is a special snowflake that completely *ignores* CPPFLAGS,
# because of course it does...
# (https://gitlab.kitware.com/cmake/cmake/issues/12928)

# set minimum cmake version required for cross-compiling to work
cmake_minimum_required (VERSION 3.5.1)
set(NO_POLICY_SCOPE NEW)
# Build with rm CMakeCache.txt; cmake -DCMAKE_TOOLCHAIN_FILE=./CMakeCross.txt .

# set target system name
set(CMAKE_SYSTEM_NAME Linux)
# set target system processor, because we can't set CMAKE_SYSTEM_NAME without setting CMAKE_SYSTEM_PROCESSOR too...

if(DEFINED ENV{WIN32})
    set(CMAKE_SYSTEM_NAME Windows)
endif()

# x86 Android
if($ENV{CROSS_TC} MATCHES "^i686-.*")
	set(CMAKE_SYSTEM_PROCESSOR i686)
endif()

# AArch64
if($ENV{CROSS_TC} MATCHES "^aarch64-.*")
	set(CMAKE_SYSTEM_PROCESSOR aarch64)
endif()

# x86_64
if($ENV{CROSS_TC} MATCHES "^x86_64-.*")
	set(CMAKE_SYSTEM_PROCESSOR x86_64)
endif()

# Otherwise, we should mostly be targeting ARM ;).
if($ENV{CROSS_TC} MATCHES "^arm-.*")
	set(CMAKE_SYSTEM_PROCESSOR arm)
endif()

if(DEFINED ENV{CCACHE})
    set(CMAKE_C_COMPILER_LAUNCHER $ENV{CCACHE})
    set(CMAKE_CXX_COMPILER_LAUNCHER $ENV{CCACHE})
endif()

# set compiler name
set(CMAKE_C_COMPILER $ENV{CROSS_TC}-gcc)
set(CMAKE_CXX_COMPILER $ENV{CROSS_TC}-g++)

# Choose the right STL on Android
if(DEFINED ENV{ANDROID})
    # NOTE: This is mostly for documentation purposes, if we ever switch to the NDK toolchain config file,
    #       c.f., android-ndk-r15c/build/cmake/android.toolchain.cmake
    set(ANDROID_STL gnustl_shared)
endif()

# set various other toolchain tools
# NOTE: These apparently need to be cache values for arcane CMake reasons.
#       Should also apparently be fully resolved absolute paths,
#       but that lead to weird expansion and hilarious warnings last time I tried...
#       If all else fails, comment out, and hope just export AR & co will do the job.
#       That, or directly including this in a toplevel CmakeFile.txt...
set(CMAKE_STRIP "$ENV{CROSS_TC}-strip" CACHE FILEPATH "Strip")
set(CMAKE_AR "$ENV{CROSS_TC}-ar" CACHE FILEPATH "Archive")
set(CMAKE_RANLIB "$ENV{CROSS_TC}-ranlib" CACHE FILEPATH "RanLib")
set(CMAKE_NM "$ENV{CROSS_TC}-nm" CACHE FILEPATH "NM")

# Set path(s) to search for libraries/binaries/headers
set(CMAKE_SYSROOT $ENV{SYSROOT})
set(CMAKE_STAGING_PREFIX $ENV{CROSS_STAGING})
# NOTE: CMAKE_SYSROOT should take precedence over this (... hopefully).
set(CMAKE_FIND_ROOT_PATH $ENV{CROSS_STAGING})
# Ensure only cross-dirs are searched
set(ONLY_CMAKE_FIND_ROOT_PATH TRUE)
# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# For libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# As well as for CMake packages too
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Enable x-compilation by default
#message("Target system:${CMAKE_SYSTEM_NAME}, Host system:${CMAKE_HOST_SYSTEM}")
#if(CMAKE_CROSSCOMPILING)
#	message("CROSS COMPILING for ${CMAKE_C_COMPILER}")
	include_directories(BEFORE ${CMAKE_FIND_ROOT_PATH}/include)
	# Make pkg-config look in the right place
	set(ENV{PKG_CONFIG_PATH})
	set(ENV{PKG_CONFIG_LIBDIR} ${CMAKE_FIND_ROOT_PATH}/lib/pkgconfig/)
#else(CMAKE_CROSSCOMPILING)
#	message("Native Compile")
#endif(CMAKE_CROSSCOMPILING)
