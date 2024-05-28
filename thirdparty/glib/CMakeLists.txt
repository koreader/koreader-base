cmake_minimum_required(VERSION 3.5.1)
project(glib LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(CFLAGS)
assert_var_defined(LDFLAGS)
assert_var_defined(HOST_OPTS)
assert_var_defined(GETTEXT_DIR)
assert_var_defined(LIBICONV_DIR)
assert_var_defined(WITH_LIBICONV)

# We only care about `libglib-2.0.a`.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-libglib-only.patch)

# Android makes Linux syscalls hard to get to... Fix pilfered from Python.
if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-2.58.2-android-linux-syscalls.patch)
endif()

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# Autotools needs some hints when x-compiling
list(APPEND gen_arm_config "glib_cv_stack_grows=no")
list(APPEND gen_arm_config "glib_cv_uscore=no")
# In order to support legacy PocketBook 4.x firmware we should get rid of eventfd@GLIBC_2.7 and pipe2@GLIBC_2.9
if(LEGACY OR POCKETBOOK)
    list(APPEND gen_arm_config "glib_cv_eventfd=no")
    list(APPEND gen_arm_config "ac_cv_func_pipe2=no")
    # As well as mkostemp@GLIBC_2.7
    list(APPEND gen_arm_config "ac_cv_func_mkostemp=no")
endif()
if(ANDROID)
    # disable getpwuid, getgrgid and timegm for > android-12
    list(APPEND gen_arm_config "ac_cv_func_posix_getpwuid_r=no")
    list(APPEND gen_arm_config "ac_cv_func_posix_getgrgid_r=no")
    list(APPEND gen_arm_config "ac_cv_func_getpwuid_r=no")
    list(APPEND gen_arm_config "ac_cv_func_getgrgid_r=no")
    list(APPEND gen_arm_config "ac_cv_func_timegm=no")
endif()

list(APPEND CFG_CMD COMMAND sh -c "printf '%s\\n' \"$@\" >arm_cache.conf" -- ${gen_arm_config})

set(CFG_ENV_VAR "CC=${CC}" "AR=${AR}" "RANLIB=${RANLIB}")
set(CFG_ENV_VAR ${CFG_ENV_VAR} "CFLAGS=${CFLAGS} -I${LIBICONV_DIR}/include -I${GETTEXT_DIR}/include" "LDFLAGS=${LDFLAGS} -L${GETTEXT_DIR}/lib -L${LIBICONV_DIR}/lib")
set(CFG_OPTS --with-libiconv=${WITH_LIBICONV} --with-threads=posix --prefix=${INSTALL_DIR} --disable-libelf --with-pcre=internal --disable-selinux --disable-compile-warnings --enable-libmount=no)
set(CFG_OPTS ${CFG_OPTS} --enable-static=true --enable-shared=false)
set(CFG_OPTS ${CFG_OPTS} --host=${CHOST} ${HOST_OPTS})
list(APPEND CFG_CMD COMMAND env ${CFG_ENV_VAR} ${SOURCE_DIR}/configure ${CFG_OPTS})

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C glib)

list(APPEND INSTALL_CMD COMMAND ${KO_MAKE_RECURSIVE} -C glib install)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/GNOME/glib.git
    2.58.3
    ${SOURCE_DIR}
)

external_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
