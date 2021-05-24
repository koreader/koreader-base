project(glib)
cmake_minimum_required(VERSION 3.10.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/../cmake_modules")
include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

enable_language(C CXX)

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(HOST_OPTS)
assert_var_defined(WITH_LIBICONV)
assert_var_defined(ENABLE_SHARED)
assert_var_defined(LIBFFI_DIR)
assert_var_defined(ZLIB_DIR)

ep_get_source_dir(SOURCE_DIR)
ep_get_binary_dir(BINARY_DIR)

# The build system (even the legacy autoconf one) has a hard dependency on Python,
# but fails to actually honor the specified/detected Python version in every cases,
# sometimes just hoping there's a python binary somewhere in $PATH (which, granted, there should be)...
# Enforce that to python3 for containers where that's the only available Python version.
if(DEFINED ENV{APPIMAGE} OR DEFINED ENV{CERVANTES} OR DEFINED ENV{KINDLE} OR DEFINED ENV{KOBO})
    set(PATCH_CMD1 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-2.56.2-python3.patch")
endif()
# Android makes Linux syscalls hard to get to... Fix pilfered from Python.
if(DEFINED ENV{ANDROID})
    set(PATCH_CMD2 "${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-2.58.2-android-linux-syscalls.patch")
endif()

set(PATCH_CMD3 sh -c "NOCONFIGURE=1 ./autogen.sh")

# Autotools needs some hints when x-compiling
set(gen_arm_config "${gen_arm_config}glib_cv_stack_grows=no\\n")
set(gen_arm_config "${gen_arm_config}glib_cv_uscore=no\\n")
# In order to support legacy PocketBook 4.x firmware we should get rid of eventfd@GLIBC_2.7 and pipe2@GLIBC_2.9
if(DEFINED ENV{LEGACY} OR DEFINED ENV{POCKETBOOK})
	set(gen_arm_config "${gen_arm_config}glib_cv_eventfd=no\\n")
	set(gen_arm_config "${gen_arm_config}ac_cv_func_pipe2=no\\n")
	# As well as mkostemp@GLIBC_2.7
	set(gen_arm_config "${gen_arm_config}ac_cv_func_mkostemp=no\\n")
endif()
if(DEFINED ENV{ANDROID})
	# disable getpwuid, getgrgid and timegm for > android-12
	set(gen_arm_config "${gen_arm_config}ac_cv_func_posix_getpwuid_r=no\\n")
	set(gen_arm_config "${gen_arm_config}ac_cv_func_posix_getgrgid_r=no\\n")
	set(gen_arm_config "${gen_arm_config}ac_cv_func_getpwuid_r=no\\n")
	set(gen_arm_config "${gen_arm_config}ac_cv_func_getgrgid_r=no\\n")
	set(gen_arm_config "${gen_arm_config}ac_cv_func_timegm=no\\n")
endif()

set(gen_arm_config sh -c "printf \"${gen_arm_config}\" > arm_cache.conf")

set(CFG_ENV_VAR "CC=\"${CC}\" AR=\"${AR}\" RANLIB=\"${RANLIB}\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} LIBFFI_CFLAGS=\"-I${LIBFFI_DIR}/include\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} LIBFFI_LIBS=\"-L${LIBFFI_DIR}/.libs -lffi\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} ZLIB_CFLAGS=\"-I${ZLIB_DIR}/include\"")
set(CFG_ENV_VAR "${CFG_ENV_VAR} ZLIB_LIBS=\"-L${ZLIB_DIR} -lz\"")
set(CFG_OPTS "--with-libiconv=\"${WITH_LIBICONV}\" --with-threads=posix --prefix=${BINARY_DIR} --enable-shared=${ENABLE_SHARED} --disable-libelf --with-pcre=internal --disable-selinux --disable-compile-warnings --enable-libmount=no")
if("${ENABLE_SHARED}" STREQUAL "false")
    set(CFG_OPTS "${CFG_OPTS} --enable-static=true")
else()
    set(CFG_OPTS "${CFG_OPTS} --disable-static")
endif()

if(NOT DEFINED ENV{DARWIN})
    set(LDFLAGS "${LDFLAGS} -Wl,-rpath-link,${ZLIB_DIR}/lib -Wl,-rpath-link,${LIBFFI_DIR}/.libs -Wl,-rpath-link,${BINARY_DIR}/gmodule/.libs")
else()
    set(CFLAGS "-I/usr/local/opt/gettext/include ${CFLAGS}")
    set(LDFLAGS "${LDFLAGS} -L/usr/local/opt/gettext/lib -L${LIBICONV_DIR}/lib -L${ZLIB_DIR}/lib -L${LIBFFI_DIR}/.libs -L${BINARY_DIR}/gmodule/.libs")
endif()

set(CFG_OPTS "${CFG_OPTS} CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ${HOST_OPTS}")
set(CFG_CMD sh -c "${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/GNOME/glib.git
    2.58.3
    ${SOURCE_DIR}
)

include(ExternalProject)
ExternalProject_Add(
    ${PROJECT_NAME}
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND COMMAND ${PATCH_CMD1} COMMAND ${PATCH_CMD2} COMMAND ${PATCH_CMD3}
    CONFIGURE_COMMAND COMMAND ${gen_arm_config} COMMAND ${CFG_CMD}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
    INSTALL_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS} install
)
