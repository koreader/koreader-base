# CMake Cross ToolChain config file. Adapted from Debian's dpkg-cross ;).
# c.f., https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling-toolchain

# set minimum cmake version required for cross-compiling to work
cmake_minimum_required (VERSION 2.6.3)
SET (NO_POLICY_SCOPE NEW)
# Build with rm CMakeCache.txt; cmake -DCMAKE_TOOLCHAIN_FILE=./CMakeCross.txt .

# set target system name
SET (CMAKE_SYSTEM_NAME Linux)
SET (CMAKE_SYSTEM_PROCESSOR arm)

# set compiler name
SET (CMAKE_C_COMPILER $ENV{CROSS_TC}-gcc)
SET (CMAKE_CXX_COMPILER $ENV{CROSS_TC}-g++)

# set various other toolchain tools
SET (CMAKE_STRIP $ENV{CROSS_TC}-strip)
SET (CMAKE_AR $ENV{CROSS_TC}-gcc-ar)
SET (CMAKE_RANLIB $ENV{CROSS_TC}-gcc-ranlib)
SET (CMAKE_NM $ENV{CROSS_TC}-gcc-nm)

# Set path(s) to search for libraries/binaries/headers
SET (CMAKE_SYSROOT $ENV{HOME}/x-tools/$ENV{CROSS_TC}/$ENV{CROSS_TC}/sysroot)
SET (CMAKE_STAGING_PREFIX /dev/null)
# NOTE: CMAKE_SYSROOT should take precedence over this (... hopefully).
SET (CMAKE_FIND_ROOT_PATH /dev/null)
# Ensure only cross-dirs are searched
SET (ONLY_CMAKE_FIND_ROOT_PATH TRUE)
# Search for programs in the build host directories
SET (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# For libraries and headers in the target directories
SET (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# As well as for CMake packages too
SET (CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Enable x-compilation by default
#MESSAGE ("Target system:${CMAKE_SYSTEM_NAME}, Host system:${CMAKE_HOST_SYSTEM}")
#IF (CMAKE_CROSSCOMPILING)
#	MESSAGE ("CROSS COMPILING for ${CMAKE_C_COMPILER}")
	INCLUDE_DIRECTORIES (BEFORE ${CMAKE_FIND_ROOT_PATH}/include)
	# Make pkg-config look in the right place
	#SET (ENV{PKG_CONFIG_LIBDIR} ${CMAKE_FIND_ROOT_PATH}/lib/pkgconfig/)
#ELSE (CMAKE_CROSSCOMPILING)
#	MESSAGE("Native Compile")
#ENDIF (CMAKE_CROSSCOMPILING)
