project(tar LANGUAGES)

# O_PATH may be defined in our ToolChains, but older devices actually run kernels where it's not entirely usable...
# (Usage in tar via gnulib's https://git.savannah.gnu.org/cgit/gnulib.git/log/lib/fchmodat.c)
if(NOT EMULATE_READER)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.33-remove-o_path-usage.patch)
endif()

# The wordsplit changes introduced in 1.31 require glob.h, which is not present on Androdi before ABI 28 (c.f., #787)
if(ANDROID)
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/tar-1.31-revert-wordsplit-for-android-glob.patch)
endif()

# list(APPEND PATCH_CMD COMMAND touch ABOUT-NLS po/Makevars.template)
# list(APPEND PATCH_CMD COMMAND env AUTOPOINT=true ./bootstrap --skip-po)

if(ANDROID)
    set(LIBS "-static")
elseif(DARWIN OR WIN32)
    set(LIBS "")
else()
    set(LIBS "-lrt")
endif()

list(APPEND CFG_CMD COMMAND env)
# Avoid pulling > GLIBC_2.4 symbols on crappy platforms
if(LEGACY OR POCKETBOOK)
    list(APPEND CFG_CMD ac_cv_func_utimensat=no ac_cv_func_futimens=no)
endif()
append_autotools_vars(CFG_CMD)
list(APPEND CFG_CMD
    "CPPFLAGS=-DHAVE_MKFIFO=1" "LIBS=${LIBS}"
    ${SOURCE_DIR}/configure --host=${CHOST} --prefix=${INSTALL_DIR}
    --disable-acl
    --disable-gcc-warnings
    --disable-nls
    --without-posix-acls
    --without-xattrs
)
if(LEGACY OR POCKETBOOK)
    list(APPEND CFG_CMD --disable-largefile)
endif()

if(LEGACY OR POCKETBOOK)
    # Forcibly disable FORTIFY on legacy devices...
    list(APPEND CFG_CMD COMMAND ${ISED} "s/# define _FORTIFY_SOURCE 2/#undef _FORTIFY_SOURCE/" config.h)
endif()

# Only compile the minimum (or rather give it a try).
list(APPEND CFG_CMD COMMAND ${ISED} "s/^SUBDIRS = .*/SUBDIRS = gnu lib src/" Makefile)

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_RECURSIVE})

# Install executable.
append_install_command(INSTALL_CMD src/tar)

set(TAR_VER "1.34")

thirdparty_project(
    BUILD_ALWAYS
    URL http://ftpmirror.gnu.org/tar/tar-${TAR_VER}.tar.gz
    URL_MD5 9d5949e4c2d9665546ac65dafc0e726a
    PATCH_COMMAND ${PATCH_CMD}
    CONFIGURE_COMMAND ${CFG_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
