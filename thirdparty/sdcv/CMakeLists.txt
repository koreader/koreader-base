project(sdcv LANGUAGES)

# Revert 6e36e7730caf07b6cd0bfa265cdf9b5e31e7acad, because it's not helpful in our workflow, and just causes logging noise.
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-no-unknown-dict-warning.patch)
# Force utf8 command line parsing
list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/sdcv-locale-hack.patch)
# Fix check for glib/gregex.h
# FIXME: need to link to + report bug to upstream.
# list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/fix-gregex-check.patch)

list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")

# because cmake needs all kinds of annoying special cmake variables
# Compiler and linker flags
if(DARWIN)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_INIT} -framework CoreFoundation -framework CoreServices -framework Security")
elseif(ANDROID)
    # Android 5+ requires PIE (yum!)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_INIT} -pie -fPIE")
endif()
list(APPEND CMAKE_ARGS "-DCMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}")

# took me an eternity to find $<SEMICOLON>
# important docs here https://cmake.org/cmake/help/v2.8.11/cmake.html#command:add_custom_command
list(APPEND CMAKE_ARGS "-DGLIB2_INCLUDE_DIRS=${STAGING_DIR}/glib/include$<SEMICOLON>$<SEMICOLON>${STAGING_DIR}/gettext/include$<SEMICOLON>${STAGING_DIR}/libiconv/include")

# For some reason this doesn't actually work and CMake keeps finding mostly .so
# Which is funny, because the .a is in the *same* directory. Just saying.
# Instead we add semi-hardcoded references to the right libraries in GLIB2_LIBRARIES
# glib2 also needs to link with libiconv and gettext
# this is a fairly clean hack
# CMAKE_CXX_FLAGS with -I and -L doesn't seem to have much of an effect
string(APPEND GLIB2_LIBRARIES
    "${STAGING_DIR}/glib/static/libglib-2.0.a"
    $<SEMICOLON>
    "${STAGING_DIR}/gettext/static/libintl.a"
    $<SEMICOLON>
    "${STAGING_DIR}/libiconv/static/libiconv.a"
)
# # Need pthread library and rt library on old glibc (for `clock_gettime`).
if(NOT DARWIN)
    string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -pthread)
    if(NOT ANDROID)
        string(APPEND GLIB2_LIBRARIES $<SEMICOLON> -lrt)
    endif()
endif()
list(APPEND CMAKE_ARGS "-DGLIB2_LIBRARIES=${GLIB2_LIBRARIES}")

list(APPEND CMAKE_ARGS "-DENABLE_NLS=False")
list(APPEND CMAKE_ARGS "-DWITH_READLINE=False")

if(ANDROID)
    set(ZLIB "${STAGING_DIR}/zlib/static/libz.a")
else()
    set(ZLIB "${STAGING_DIR}/zlib/shared/libz${LIB_EXT}")
endif()

list(APPEND CMAKE_ARGS "-DZLIB_INCLUDE_DIR=${STAGING_DIR}/zlib/include")
list(APPEND CMAKE_ARGS "-DZLIB_LIBRARIES=${ZLIB}")
# I just want to be able to -I and -L and have things work. CMake, CMake...
list(APPEND CMAKE_ARGS "-DZLIB_LIBRARY_RELEASE=${ZLIB}")

list(APPEND BUILD_CMD ${KO_MAKE_PROGRAM})

# Install executable.
append_install_command(INSTALL_CMD sdcv)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/Dushistov/sdcv.git
    v0.5.5
    ${SOURCE_DIR}
)

thirdparty_project(
    BUILD_ALWAYS
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    CMAKE_ARGS ${CMAKE_ARGS}
    PATCH_COMMAND ${PATCH_CMD}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
