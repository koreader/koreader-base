project(glib LANGUAGES)

# We only care about `libglib-2.0.a`.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-libglib-only.patch)

# Android makes Linux syscalls hard to get to... Fix pilfered from Python.
if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-2.58.2-android-linux-syscalls.patch)
endif()

list(APPEND PATCH_CMD COMMAND env NOCONFIGURE=1 ./autogen.sh)

# Autotools needs some hints when x-compiling
if(NOT "${CHOST}" STREQUAL "")
    list(APPEND gen_cache_config "glib_cv_stack_grows=no")
    list(APPEND gen_cache_config "glib_cv_uscore=no")
    # In order to support legacy PocketBook 4.x firmware we should get rid of eventfd@GLIBC_2.7 and pipe2@GLIBC_2.9
    if(LEGACY OR POCKETBOOK)
        list(APPEND gen_cache_config "glib_cv_eventfd=no")
        list(APPEND gen_cache_config "ac_cv_func_pipe2=no")
        # As well as mkostemp@GLIBC_2.7
        list(APPEND gen_cache_config "ac_cv_func_mkostemp=no")
    endif()
    if(ANDROID)
        # disable getpwuid, getgrgid and timegm for > android-12
        list(APPEND gen_cache_config "ac_cv_func_posix_getpwuid_r=no")
        list(APPEND gen_cache_config "ac_cv_func_posix_getgrgid_r=no")
        list(APPEND gen_cache_config "ac_cv_func_getpwuid_r=no")
        list(APPEND gen_cache_config "ac_cv_func_getgrgid_r=no")
        list(APPEND gen_cache_config "ac_cv_func_timegm=no")
    endif()
    list(APPEND CFG_CMD COMMAND sh -c "printf '%s\\n' \"$@\" >cache.conf" -- ${gen_cache_config})
    list(APPEND CFG_CACHE --cache-file=cache.conf)
endif()

list(APPEND CFG_CMD COMMAND env)
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-I${STAGING_DIR}/gettext/include -I${STAGING_DIR}/libiconv/include"
    "LIBS=-L${STAGING_DIR}/gettext/static -L${STAGING_DIR}/libiconv/static"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --enable-static=true --enable-shared=false
    --disable-compile-warnings
    --disable-libelf
    --disable-selinux
    --enable-libmount=no
    --with-libiconv=gnu
    --with-pcre=internal
    --with-threads=posix
    ${CFG_CACHE}
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE} -C glib)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD glib/.libs/libglib-2.0.a glib-2.0)

# Install headers.
append_headers_install_command(INSTALL_CMD
    SUBDIR glib
    FROM "${SOURCE_DIR}/glib"
    galloca.h garray.h gasyncqueue.h gatomic.h gbacktrace.h gbase64.h
    gbitlock.h gbookmarkfile.h gbytes.h gcharset.h gchecksum.h gconvert.h
    gdataset.h gdate.h gdatetime.h gdir.h genviron.h gerror.h gfileutils.h
    ggettext.h ghash.h ghmac.h ghook.h ghostutils.h gi18n.h gi18n-lib.h
    giochannel.h gkeyfile.h glib-autocleanups.h glist.h gmacros.h gmain.h
    gmappedfile.h gmarkup.h gmem.h gmessages.h gnode.h goption.h gpattern.h
    gpoll.h gprimes.h gprintf.h gqsort.h gquark.h gqueue.h grand.h grcbox.h
    grefcount.h grefstring.h gregex.h gscanner.h gsequence.h gshell.h
    gslice.h gslist.h gspawn.h gstdio.h gstrfuncs.h gstringchunk.h
    gstring.h gtestutils.h gthread.h gthreadpool.h gtimer.h gtimezone.h
    gtrashstack.h gtree.h gtypes.h gunicode.h gurifuncs.h gutils.h guuid.h
    gvariant.h gvarianttype.h gversion.h gversionmacros.h gwin32.h
)
append_headers_install_command(
    INSTALL_CMD SUBDIR glib/deprecated
    "${SOURCE_DIR}/glib/deprecated/*.h"
)
append_headers_install_command(
    INSTALL_CMD
    "${BINARY_DIR}/glib/glibconfig.h"
    FROM "${SOURCE_DIR}/glib"
    glib.h glib-object.h glib-unix.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/GNOME/glib.git
    2.58.3
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
