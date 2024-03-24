# Android makes Linux syscalls hard to get to... Fix pilfered from Python.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/glib-2.58.2-android-linux-syscalls.patch)
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/libglib-only.patch)

list(APPEND CFG_CMD COMMAND sh -c "printf '%s\\n' \"$@\" >config.ini" --
    "[constants]"
    "CPPFLAGS = ['-I${STAGING_DIR}/include']"
    "LDFLAGS = ['-L${STAGING_DIR}/lib']"
)

if(ANDROID OR DARWIN)
    set(ICONV gnu)
else()
    set(ICONV libc)
endif()

list(APPEND CFG_CMD COMMAND
    ${MESON_SETUP} ${MESON_FILE_ARG}=config.ini --default-library=static
    -Dforce_posix_threads=true
    -Diconv=${ICONV}
    -Dinternal_pcre=true
    -Dlibmount=false
    -Dselinux=false
    "${SOURCE_DIR}"
)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} glib/libglib-2.0.a)

# Install static lib.
append_static_lib_install_command(INSTALL_CMD BYPRODUCTS glib/libglib-2.0.a glib-2.0)

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/glib"
    glib.h glib-object.h glib-unix.h
    "${BINARY_DIR}/glib/glibconfig.h"
)
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
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
    INSTALL_CMD BYPRODUCTS
    SUBDIR glib/deprecated
    FROM "${SOURCE_DIR}/glib/deprecated"
    gallocator.h gcache.h gcompletion.h gmain.h grel.h gthread.h
)

thirdparty_project(
    URL https://download.gnome.org/sources/glib/2.58/glib-2.58.3.tar.xz
    URL_MD5 8058c7bde846dcffe5fa453eca366d73
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
