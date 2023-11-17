if (DARWIN)
    # Note: can't use `sed -i "" -e`, because cmake "helpfully"
    # filter-out the empty argument during command invocation…
    set(ISED sh -c "sed -i '' -e \"$@\"" --)
else()
    set(ISED sed -i -e)
endif()

macro(assert_var_defined varName)
    if(NOT DEFINED ${varName})
        message(FATAL_ERROR "${varName} variable not defined!")
    endif()
endmacro()

set(KO_DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/downloads")

if(ANDROID)
    set(ANDROID_LIBTOOL_FIX_CMD)
    list(APPEND ANDROID_LIBTOOL_FIX_CMD ${ISED} $<SEMICOLON>
        -e "s|version_type=none|version_type=linux|"
        -e "s|need_lib_prefix=no|need_lib_prefix=yes|"
        -e "s|need_version=no|need_version=yes|"
        -e "s|library_names_spec=.*|library_names_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$versuffix \\\\$libname\\\\$release\\\\$shared_ext\\\\$major \\\\$libname\\\\$shared_ext\"|"
        -e "s|soname_spec=.*|soname_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$major\"|"
        libtool)
endif()

# Append autotools variables ("VAR=value") to `list`.
function(append_autotools_vars list)
    foreach(var CC CFLAGS CXX CXXFLAGS LD LDFLAGS AR NM RANLIB RC STRIP)
        if(DEFINED ${var})
            list(APPEND ${list} "${var}=${${var}}")
        endif()
    endforeach()
    set(${list} "${${list}}" PARENT_SCOPE)
endfunction()

function(set_libname VAR NAME)
    cmake_parse_arguments("" "" "EXT;VERSION" "" ${ARGN})
    if(NOT DEFINED _EXT)
        set(_EXT "${LIB_EXT}")
    endif()
    set(NAME "lib${NAME}" "${_EXT}")
    if(DEFINED _VERSION)
        if(DARWIN)
            list(INSERT NAME 1 .${_VERSION})
        elseif(WIN32)
            list(INSERT NAME 1 -${_VERSION})
        else()
            list(APPEND NAME .${_VERSION})
        endif()
    endif()
    string(CONCAT NAME ${NAME})
    set(${VAR} ${NAME} PARENT_SCOPE)
endfunction()

function(append_install_command LIST)
    cmake_parse_arguments("" "" "DESTINATION" "" ${ARGN})
    if(_DESTINATION)
        if(_DESTINATION MATCHES "/$")
            set(TRAILING_SLASH 1)
        endif()
        get_filename_component(_DESTINATION "${_DESTINATION}" ABSOLUTE BASE_DIR "${OUTPUT_DIR}")
        if(TRAILING_SLASH)
            string(APPEND _DESTINATION "/")
        endif()
    else()
        set(_DESTINATION "${OUTPUT_DIR}/")
    endif()
    if(_DESTINATION MATCHES "/$")
        set(_DESTDIR "${_DESTINATION}")
    else()
        get_filename_component(_DESTDIR "${_DESTINATION}" DIRECTORY)
    endif()
    list(APPEND ${LIST} COMMAND mkdir -p "${_DESTDIR}")
    list(APPEND ${LIST} COMMAND
        "${CMAKE_COMMAND}" -E copy_if_different
        ${_UNPARSED_ARGUMENTS}
        "${_DESTINATION}"
    )
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

# Append to `LIST` the necessary commands to install the shared library
# `NAME` with optional `VERSION` from `SHLIB` to the output directory
# with proper symlinks in the current project staging directory. If
# `NEEDED` is specified, also fix the library dependencies.
function(append_shared_lib_install_command LIST SHLIB NAME)
    cmake_parse_arguments("" "" "EXT;VERSION" "NEEDED" ${ARGN})
    if(NOT DEFINED _EXT)
        set(_EXT "${LIB_EXT}")
    endif()
    set_libname(BASE_NAME ${NAME} EXT "${_EXT}")
    set_libname(VERSIONNED_NAME ${NAME} EXT "${_EXT}" VERSION ${_VERSION})
    list(APPEND ${LIST} COMMAND
        "${THIRDPARTY_DIR}/cmake_modules/install_shared_lib.sh"
        "${CMAKE_COMMAND}"
        "${SHLIB}"
        "${BASE_NAME}" "${VERSIONNED_NAME}"
        "${OUTPUT_DIR}/libs" "${STAGING_DIR}/${PROJECT_NAME}"
    )
    # if(DARWIN)
    #     list(APPEND ${LIST} "${THIRDPARTY_DIR}/cmake_modules/fix_macos_dynlib.sh" libs ${NEEDED})
    # endif()
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

function(append_static_lib_install_command LIST STLIB NAME)
    get_filename_component(STLIB "${STLIB}" ABSOLUTE BASE_DIR "${BINARY_DIR}")
    list(APPEND ${LIST} COMMAND
        "${THIRDPARTY_DIR}/cmake_modules/install_static_lib.sh"
        "${STLIB}"
        "lib${NAME}.a"
        "${STAGING_DIR}/${PROJECT_NAME}"
    )
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

function(append_tree_install_command LIST SRC DST)
    get_filename_component(DST "${DST}" ABSOLUTE BASE_DIR "${OUTPUT_DIR}")
    list(APPEND ${LIST} COMMAND ${CMAKE_COMMAND} -E)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
        list(APPEND ${LIST} copy_directory_if_different)
    else()
        list(APPEND ${LIST} copy_directory)
    endif()
    list(APPEND ${LIST} "${SRC}" "${DST}")
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

function(append_headers_install_command LIST)
    cmake_parse_arguments("" "" "SUBDIR" "" ${ARGN})
    list(APPEND ${LIST} COMMAND
        "${THIRDPARTY_DIR}/cmake_modules/install_headers.sh"
        "${STAGING_DIR}/${PROJECT_NAME}/include/${_SUBDIR}"
    )
    set(_FROM "${BINARY_DIR}")
    set(_SET_FROM 0)
    foreach(ARG IN LISTS _UNPARSED_ARGUMENTS)
        if(ARG STREQUAL FROM)
            set(_SET_FROM 1)
            continue()
        endif()
        if(_SET_FROM)
            get_filename_component(_FROM "${ARG}" ABSOLUTE BASE_DIR "${BINARY_DIR}")
            set(_SET_FROM 0)
            continue()
        endif()
        get_filename_component(ARG "${ARG}" ABSOLUTE BASE_DIR "${_FROM}")
        list(APPEND ${LIST} "${ARG}")
    endforeach()
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

function(append_luarocks_install_command LIST ROCKSPEC)
    assert_var_defined(LUAROCKS)
    assert_var_defined(LUAJIT_INCDIR)
    assert_var_defined(LUAJIT_LIBDIR)
    set(luarocks ${LUAROCKS})
    # We want to run `"luarocks" "--version=5.1"`,
    # not `"luarocks --version=5.1"`…
    separate_arguments(luarocks)
    list(APPEND ${LIST} COMMAND env
        # Forward our toolchain file in case of CMake based rock.
        "CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
        ${luarocks} make
        --deps-mode none #--no-doc
        "--tree=${INSTALL_DIR}/rocks"
    )
    foreach(var CC CFLAGS CXX CXXFLAGS LD LDFLAGS)
        if(DEFINED ${var})
            list(APPEND ${LIST} "${var}=${${var}}")
        endif()
    endforeach()
    list(APPEND ${LIST}
        "CMAKE=${CMAKE_COMMAND}"
        "LIBFLAG=${DYNLIB_LDFLAGS}"
        "LUALIB=${LUAJIT_LIB}"
        "LUA_INCDIR=${LUAJIT_INCDIR}"
        "LUA_LIBDIR=${LUAJIT_LIBDIR}"
        ${ROCKSPEC}
    )
    set(${LIST} "${${LIST}}" PARENT_SCOPE)
endfunction()

set(SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/source")
set(BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/build")
set(INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/install")

# Thirdparty projects support.
include(ExternalProject)
# `ExternalProject` step targets fully adopt their steps.
cmake_policy(SET CMP0114 NEW)
# When extracting an archive, preserve the timestamps (old behavior):
# new behavior set the timestamps to the time of extraction instead,
# which can break some builds (e.g. gettext: autotools fails to
# re-generate `configure` because `configure.ac` is missing).
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 OLD)
endif()
# Have `ExternalProject_Add()` create a dedicated target for each step.
set_property(DIRECTORY PROPERTY EP_STEP_TARGETS download patch configure build install)
# Helper to ensure a saner tree structure, e.g.:
# thirdparty/zlib
# ├── build
# │   ├── armv7a-unknown-linux-android18-debug
# │   │   ├── source/
# │   │   ├── build/
# │   │   ├── install/
# │   │   └── …
# │   └── downloads
# │       └── zlib-1.2.13.tar.xz
# ├── CMakeLists.txt
# ├── zlib-1.2.11-configure-fix-AR-RANLIB-NM-detection.patch
# ├── zlib-1.2.11-minizip-drop-crypt-header.patch
# └── zlib-1.2.13-use-LDFLAGS-in-configure.patch
function(thirdparty_project)
    cmake_parse_arguments(
        # Prefix.
        ""
        # Options.
        "BUILD_ALWAYS"
        # One value keywords.
        "URL;URL_MD5;SOURCE_SUBDIR"
        # Multi-value keywords.
        "CMAKE_ARGS;DOWNLOAD_COMMAND;PATCH_COMMAND;CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND"
        ${ARGN}
    )
    # Project name.
    list(APPEND PARAMS "${PROJECT_NAME}")
    # Options.
    if(_BUILD_ALWAYS)
        list(APPEND PARAMS BUILD_ALWAYS 1)
    endif()
    # Dowload parameters.
    if(_URL)
        list(APPEND PARAMS DOWNLOAD_DIR "${KO_DOWNLOAD_DIR}")
        list(APPEND PARAMS URL "${_URL}")
        if(_URL MATCHES "http://ftpmirror\.gnu\.org/")
            # Duplicate URL on flaky GNU FTP server as a form of retry
            # (since each connection may result in a different mirror).
            list(APPEND PARAMS "${_URL}" "${_URL}")
        endif()
        list(APPEND PARAMS URL_MD5 "${_URL_MD5}")
    else()
        if(NOT DEFINED _DOWNLOAD_COMMAND)
            message(FATAL_ERROR "no URL, and no DOWNLOAD_COMMAND!")
        endif()
        list(APPEND PARAMS DOWNLOAD_COMMAND ${_DOWNLOAD_COMMAND})
    endif()
    # Source dir.
    get_filename_component(DIR "${SOURCE_DIR}" NAME)
    list(APPEND PARAMS SOURCE_DIR "${DIR}")
    if(DEFINED _SOURCE_SUBDIR)
        list(APPEND PARAMS SOURCE_SUBDIR "${_SOURCE_SUBDIR}")
    endif()
    # Build dir.
    if(BINARY_DIR STREQUAL SOURCE_DIR)
        list(APPEND PARAMS BUILD_IN_SOURCE 1)
    else()
        get_filename_component(DIR "${BINARY_DIR}" NAME)
        list(APPEND PARAMS BINARY_DIR "${DIR}")
    ENDIF()
    # Install dir.
    get_filename_component(DIR "${INSTALL_DIR}" NAME)
    list(APPEND PARAMS INSTALL_DIR "${DIR}")
    # Other directories.
    list(APPEND PARAMS LOG_DIR log)
    list(APPEND PARAMS TMP_DIR tmp)
    list(APPEND PARAMS STAMP_DIR stamp)
    # CMake arguments, patch / configure / build commands.
    foreach(VAR CMAKE_ARGS PATCH_COMMAND CONFIGURE_COMMAND BUILD_COMMAND)
        if(DEFINED _${VAR})
            list(APPEND PARAMS ${VAR} ${_${VAR}})
        endif()
    endforeach()
    # Install command.
    if(NOT DEFINED _INSTALL_COMMAND)
        set(_INSTALL_COMMAND COMMAND)
    endif()
    list(APPEND PARAMS INSTALL_COMMAND ${_INSTALL_COMMAND})
    # message(STATUS "PARAMS: ${PARAMS}")
    ExternalProject_Add(${PARAMS} ${_UNPARSED_ARGUMENTS})
endfunction()
