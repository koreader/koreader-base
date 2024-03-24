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

if(ANDROID)
    set(ANDROID_LIBTOOL_FIX_CMD ${ISED} $<SEMICOLON>
        -e "s|version_type=none|version_type=linux|"
        -e "s|need_lib_prefix=no|need_lib_prefix=yes|"
        -e "s|need_version=no|need_version=yes|"
        -e "s|library_names_spec=.*|library_names_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$versuffix \\\\$libname\\\\$release\\\\$shared_ext\\\\$major \\\\$libname\\\\$shared_ext\"|"
        -e "s|soname_spec=.*|soname_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$major\"|"
        libtool)
endif()

# Append autotools variables ("VAR=value") to `list`.
function(append_autotools_vars list)
    foreach(var CC CFLAGS CPPFLAGS CXX CXXFLAGS LD LDFLAGS LIBS AR NM RANLIB RC STRIP)
        if(DEFINED ${var})
            string(STRIP "${${var}}" value)
            list(APPEND ${list} "${var}=${value}")
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

function(append_strip_command CMD_LIST)
    if(DARWIN)
        list(APPEND ${CMD_LIST} COMMAND "${CMAKE_STRIP}" -x)
    else()
        list(APPEND ${CMD_LIST} COMMAND "${CMAKE_STRIP}" --strip-unneeded)
    endif()
    set(${CMD_LIST} "${${CMD_LIST}}" PARENT_SCOPE)
endfunction()

function(append_install_commands CMD_LIST BYPRODUCTS_LIST)
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
    if(_DESTINATION MATCHES "^(.+)/$")
        set(DESTDIR "${CMAKE_MATCH_1}")
        foreach(SRC IN LISTS _UNPARSED_ARGUMENTS)
            get_filename_component(SRC "${SRC}" NAME)
            list(APPEND ${BYPRODUCTS_LIST} "${DESTDIR}/${SRC}")
        endforeach()
    else()
        list(LENGTH _UNPARSED_ARGUMENTS NARGS)
        if(NARGS GREATER 1)
            message(FATAL_ERROR "multiple sources, destination must be a directory")
        endif()
        list(APPEND ${BYPRODUCTS_LIST} "${_DESTINATION}")
        get_filename_component(DESTDIR "${_DESTINATION}" DIRECTORY)
    endif()
    list(APPEND ${CMD_LIST} COMMAND mkdir -p "${DESTDIR}")
    list(APPEND ${CMD_LIST} COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${_UNPARSED_ARGUMENTS} "${_DESTINATION}")
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" PARENT_SCOPE)
endfunction()

function(append_binary_install_command CMD_LIST BYPRODUCTS_LIST SRC)
    get_filename_component(SRC "${SRC}" ABSOLUTE BASE_DIR "${BINARY_DIR}")
    if(ARGC GREATER 3)
        set(DST "${ARGV3}")
        if(DST MATCHES "/$")
            get_filename_component(NAME "${SRC}" NAME)
            string(APPEND DST "${NAME}")
        endif()
    else()
        get_filename_component(DST "${SRC}" NAME)
    endif()
    get_filename_component(DST "${DST}" ABSOLUTE BASE_DIR "${OUTPUT_DIR}")
    set(STRIP_CMD "")
    if(DO_STRIP)
        append_strip_command(STRIP_CMD)
        list(JOIN STRIP_CMD $<SEMICOLON> STRIP_CMD)
    endif()
    list(APPEND ${CMD_LIST}
        COMMAND "${CMAKE_COMMAND}"
        -DMODE=binary
        # Source.
        "-DSRC=${SRC}"
        # Destination.
        "-DDST=${DST}"
        # Processing.
        "-DSTRIP=${STRIP_CMD}"
        -P "${THIRDPARTY_DIR}/cmake_modules/koreader_install.cmake"
    )
    list(APPEND ${BYPRODUCTS_LIST} "${DST}")
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" PARENT_SCOPE)
endfunction()

function(append_shared_lib_install_command CMD_LIST BYPRODUCTS_LIST SHLIB NAME)
    cmake_parse_arguments("" "" "EXT;VERSION" "" ${ARGN})
    if(NOT DEFINED _EXT)
        set(_EXT "${LIB_EXT}")
    endif()
    set_libname(BASE_NAME ${NAME} EXT "${_EXT}")
    set_libname(VERSIONED_NAME ${NAME} EXT "${_EXT}" VERSION ${_VERSION})
    set(STAGING "${STAGING_DIR}/lib")
    set(LIBS "${OUTPUT_DIR}/libs")
    set(STRIP_CMD "")
    if(DO_STRIP)
        append_strip_command(STRIP_CMD)
        list(JOIN STRIP_CMD $<SEMICOLON> STRIP_CMD)
    endif()
    list(APPEND ${CMD_LIST}
        COMMAND "${CMAKE_COMMAND}"
        -DMODE=shared_lib
        # Source.
        "-DSHLIB=${SHLIB}"
        # Destinations.
        "-DLIBS=${LIBS}" "-DSTAGING=${STAGING}"
        "-DBASE=${BASE_NAME}" "-DVERSIONED=${VERSIONED_NAME}"
        # Processing.
        "-DSTRIP=${STRIP_CMD}"
        -P "${THIRDPARTY_DIR}/cmake_modules/koreader_install.cmake"
    )
    list(APPEND ${BYPRODUCTS_LIST} "${LIBS}/${VERSIONED_NAME}" "${STAGING}/${VERSIONED_NAME}")
    if(NOT BASE_NAME STREQUAL VERSIONED_NAME)
        list(APPEND ${BYPRODUCTS_LIST} "${STAGING}/${BASE_NAME}")
    endif()
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" PARENT_SCOPE)
endfunction()

function(append_static_lib_install_command CMD_LIST BYPRODUCTS_LIST STLIB NAME)
    get_filename_component(STLIB "${STLIB}" ABSOLUTE BASE_DIR "${BINARY_DIR}")
    set(STAGING "${STAGING_DIR}/lib")
    set(LIBNAME "lib${NAME}.a")
    list(APPEND ${CMD_LIST}
        COMMAND "${CMAKE_COMMAND}"
        -DMODE=static_lib
        # Source.
        "-DSTLIB=${STLIB}"
        # Destination.
        "-DSTAGING=${STAGING}" "-DLIBNAME=${LIBNAME}"
        -P "${THIRDPARTY_DIR}/cmake_modules/koreader_install.cmake"
    )
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" "${STAGING}/${LIBNAME}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" PARENT_SCOPE)
endfunction()

function(append_tree_install_commands CMD_LIST BYPRODUCTS_LIST SRC DST)
    get_filename_component(DST "${DST}" ABSOLUTE BASE_DIR "${OUTPUT_DIR}")
    list(APPEND ${CMD_LIST} COMMAND "${CMAKE_COMMAND}" -E)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
        list(APPEND ${CMD_LIST} copy_directory_if_different)
    else()
        list(APPEND ${CMD_LIST} copy_directory)
    endif()
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" "${DST}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" "${SRC}" "${DST}" PARENT_SCOPE)
endfunction()

function(append_headers_install_command CMD_LIST BYPRODUCTS_LIST)
    cmake_parse_arguments("" "" "SUBDIR" "" ${ARGN})
    set(INCLUDE "${STAGING_DIR}/include")
    if(DEFINED _SUBDIR)
        string(APPEND INCLUDE "/${_SUBDIR}")
    endif()
    set(_FROM "${BINARY_DIR}")
    set(_SET_FROM 0)
    list(APPEND ${CMD_LIST} COMMAND mkdir -p "${INCLUDE}")
    list(APPEND ${CMD_LIST} COMMAND "${CMAKE_COMMAND}" -E copy_if_different)
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
        list(APPEND ${CMD_LIST} "${ARG}")
        get_filename_component(ARG "${ARG}" NAME)
        list(APPEND ${BYPRODUCTS_LIST} "${INCLUDE}/${ARG}")
    endforeach()
    set(${BYPRODUCTS_LIST} "${${BYPRODUCTS_LIST}}" PARENT_SCOPE)
    set(${CMD_LIST} "${${CMD_LIST}}" "${INCLUDE}/" PARENT_SCOPE)
endfunction()

# Thirdparty projects support.
include(ExternalProject)
# `ExternalProject` step targets fully adopt their steps.
if(POLICY CMP0114)
    cmake_policy(SET CMP0114 NEW)
endif()
# When extracting an archive, preserve the timestamps (old behavior):
# new behavior set the timestamps to the time of extraction instead,
# which can break some builds (e.g. gettext: autotools fails to
# re-generate `configure` because `configure.ac` is missing).
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 OLD)
endif()
# Have `ExternalProject_Add()` create a dedicated target for each step.
set_property(DIRECTORY PROPERTY EP_STEP_TARGETS download patch configure build install)
function(thirdparty_project)
    cmake_parse_arguments(
        # Prefix.
        ""
        # Options.
        "BUILD_ALWAYS"
        # One value keywords.
        "URL_MD5;SOURCE_SUBDIR"
        # Multi-value keywords.
        "BYPRODUCTS;CMAKE_ARGS;DOWNLOAD_COMMAND;PATCH_COMMAND;CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND;URL"
        ${ARGN}
    )
    # Project name.
    list(APPEND PARAMS "${PROJECT_NAME}")
    # Don't log steps' output on CI builds.
    if(DEFINED ENV{CI})
        set(LOGGING FALSE)
    else()
        set(LOGGING TRUE)
    endif()
    # Options.
    if(_BUILD_ALWAYS)
        list(APPEND PARAMS BUILD_ALWAYS TRUE)
    endif()
    # Dowload parameters.
    if(_URL)
        list(APPEND PARAMS DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/downloads")
        list(APPEND PARAMS URL ${_URL})
        list(APPEND PARAMS URL_MD5 "${_URL_MD5}")
    else()
        list(APPEND PARAMS DOWNLOAD_DIR .)
        if(NOT DEFINED _DOWNLOAD_COMMAND)
            message(FATAL_ERROR "no URL, and no DOWNLOAD_COMMAND!")
        endif()
        list(APPEND PARAMS DOWNLOAD_COMMAND ${_DOWNLOAD_COMMAND})
    endif()
    list(APPEND PARAMS LOG_DOWNLOAD ${LOGGING})
    # Source dir.
    get_filename_component(DIR "${SOURCE_DIR}" NAME)
    list(APPEND PARAMS SOURCE_DIR "${DIR}")
    if(DEFINED _SOURCE_SUBDIR)
        list(APPEND PARAMS SOURCE_SUBDIR "${_SOURCE_SUBDIR}")
    endif()
    # Build dir.
    # NOTE: don't use `BUILD_IN_SOURCE` when doing an in-source
    # build as for some reason CMake will still create an empty
    # build directory with the standard naming scheme.
    get_filename_component(DIR "${BINARY_DIR}" NAME)
    list(APPEND PARAMS BINARY_DIR "${DIR}")
    # Install dir.
    get_filename_component(DIR "${INSTALL_DIR}" NAME)
    list(APPEND PARAMS INSTALL_DIR "${DIR}")
    # Other directories.
    list(APPEND PARAMS PREFIX .)
    list(APPEND PARAMS LOG_DIR log)
    list(APPEND PARAMS TMP_DIR tmp)
    list(APPEND PARAMS STAMP_DIR stamp)
    # CMake arguments, patch / configure / install: we need to manually
    # escape special characters ourselves because CMake does not take
    # care of that when creating its intermediate script to run each
    # command (because logging is enabled).
    foreach(VAR CMAKE_ARGS PATCH_COMMAND CONFIGURE_COMMAND INSTALL_COMMAND)
        if(DEFINED _${VAR})
            list(APPEND PARAMS ${VAR})
            foreach(ARG ${_${VAR}})
                if(LOGGING)
                    string(REPLACE "\\" "\\\\" ARG "${ARG}")
                    string(REPLACE "\"" "\\\"" ARG "${ARG}")
                    string(REPLACE "\$" "\\\$" ARG "${ARG}")
                endif()
                list(APPEND PARAMS "${ARG}")
            endforeach()
        endif()
    endforeach()
    # Patch command.
    list(APPEND PARAMS LOG_PATCH ${LOGGING})
    # Configure command.
    if(DEFINED _CMAKE_ARGS OR DEFINED _CONFIGURE_COMMAND)
        # NOTE: don't try to log an "empty" configure command…
        list(APPEND PARAMS LOG_CONFIGURE ${LOGGING})
    else()
        list(APPEND PARAMS CONFIGURE_COMMAND COMMAND)
    endif()
    # Build command.
    if(DEFINED _BUILD_COMMAND)
        list(APPEND PARAMS BUILD_COMMAND ${_BUILD_COMMAND})
    else()
        list(APPEND PARAMS BUILD_COMMAND COMMAND)
    endif()
    list(APPEND PARAMS USES_TERMINAL_BUILD TRUE)
    # Install command.
    if(DEFINED _INSTALL_COMMAND)
        # NOTE: same as above, only work for a non-empty command.
        list(APPEND PARAMS LOG_INSTALL ${LOGGING})
    else()
        list(APPEND PARAMS INSTALL_COMMAND COMMAND)
    endif()
    # By-products.
    if(NOT DEFINED _BYPRODUCTS)
        message(FATAL_ERROR "external project ̈́“${PROJECT_NAME}” does not declare any by-products")
    endif()
    # By-products (CMake >= 3.26)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
        list(APPEND PARAMS INSTALL_BYPRODUCTS ${_BYPRODUCTS})
    endif()
    # Show a logged step output on failure.
    list(APPEND PARAMS LOG_OUTPUT_ON_FAILURE TRUE)
    # Merge stdout & stderr output when logging.
    list(APPEND PARAMS LOG_MERGED_STDOUTERR TRUE)
    ExternalProject_Add(${PARAMS} ${_UNPARSED_ARGUMENTS})
    # By-products (CMake < 3.26).
    if(CMAKE_VERSION VERSION_LESS "3.26")
        # No `INSTALL_BYPRODUCTS` support: use a custom intermediate step.
        ExternalProject_Add_Step(${PROJECT_NAME} _install
            COMMENT "Performing (real) install step for '#{PROJECT_NAME}'"
            DEPENDEES install
            BYPRODUCTS ${_BYPRODUCTS}
        )
    endif()
endfunction()
