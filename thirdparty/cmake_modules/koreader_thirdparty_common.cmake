if (DARWIN)
    # Note: can't use `sed -i "" -e`, because cmake "helpfully"
    # filter-out the empty argument during command invocation…
    set(ISED sh -c "sed -i '' -e \"$@\"" --)
else()
    set(ISED sed -i -e)
endif()

set(KO_MAKE_RECURSIVE sh -c "exec \"\$0\" \${PARALLEL_JOBS:+-j}\${PARALLEL_JOBS} \${PARALLEL_LOAD:+-l}\${PARALLEL_LOAD} \"$@\"" ${MAKE})
set(KO_NINJA_RECURSIVE sh -c "exec \"\$0\" \${NINJAFLAGS} \"\$@\"" ${NINJA})
if(CMAKE_GENERATOR MATCHES "Ninja")
    set(KO_MAKE_PROGRAM ${KO_NINJA_RECURSIVE})
else()
    set(KO_MAKE_PROGRAM ${KO_MAKE_RECURSIVE})
endif()

set(KO_PATCH ${CMAKE_CURRENT_LIST_DIR}/patch-wrapper.sh)

macro(assert_var_defined varName)
    if(NOT DEFINED ${varName})
        message(FATAL_ERROR "${varName} variable not defined!")
    endif()
endmacro()

set(SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/source)
set(BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/build)

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
    set(${list} ${${list}} PARENT_SCOPE)
endfunction()

# Improved external projects support.
include(ExternalProject)
# When extracting an archive, preserve the timestamps (old behavior):
# new behavior set the timestamps to the time of extraction instead,
# which can break some builds (e.g. gettext: autotools fails to
# re-generate `configure` because `configure.ac` is missing).
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 OLD)
endif()
function(external_project)
    cmake_parse_arguments(
        # Prefix.
        ""
        # Options.
        "BUILD_ALWAYS"
        # One value keywords.
        "URL_MD5;SOURCE_SUBDIR"
        # Multi-value keywords.
        "CMAKE_ARGS;DOWNLOAD_COMMAND;PATCH_COMMAND;CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND;URL"
        ${ARGN}
    )
    if(_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "unparsed arguments: ${_UNPARSED_ARGUMENTS}")
    endif()
    # Project name.
    list(APPEND PARAMS ${PROJECT_NAME})
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
        list(APPEND PARAMS DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build/downloads)
        list(APPEND PARAMS URL ${_URL})
        list(APPEND PARAMS URL_MD5 ${_URL_MD5})
    else()
        list(APPEND PARAMS DOWNLOAD_DIR .)
        if(NOT DEFINED _DOWNLOAD_COMMAND)
            message(FATAL_ERROR "no URL, and no DOWNLOAD_COMMAND!")
        endif()
        list(APPEND PARAMS DOWNLOAD_COMMAND ${_DOWNLOAD_COMMAND})
    endif()
    list(APPEND PARAMS LOG_DOWNLOAD ${LOGGING})
    # Source dir.
    list(APPEND PARAMS SOURCE_DIR ${SOURCE_DIR})
    if(DEFINED _SOURCE_SUBDIR)
        list(APPEND PARAMS SOURCE_SUBDIR ${_SOURCE_SUBDIR})
    endif()
    # Build dir.
    # NOTE: don't use `BUILD_IN_SOURCE` when doing an in-source
    # build as for some reason CMake will still create an empty
    # build directory with the standard naming scheme.
    list(APPEND PARAMS BINARY_DIR ${BINARY_DIR})
    # Install dir.
    list(APPEND PARAMS INSTALL_DIR ${STAGING_DIR})
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
                if(ARG STREQUAL "")
                    message(FATAL_ERROR "empty argument in ${VAR} command!")
                endif()
                if(LOGGING)
                    string(REPLACE "\\" "\\\\" ARG ${ARG})
                    string(REPLACE "\"" "\\\"" ARG ${ARG})
                    string(REPLACE "\$" "\\\$" ARG ${ARG})
                    # Keep generator expressions…
                    string(REPLACE "\\\$<" "\$<" ARG ${ARG})
                    # But not $<SEMICOLON>…
                    string(REPLACE "\$<SEMICOLON>" "\\\$<SEMICOLON>" ARG ${ARG})
                endif()
                list(APPEND PARAMS ${ARG})
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
    # Show a logged step output on failure.
    list(APPEND PARAMS LOG_OUTPUT_ON_FAILURE TRUE)
    # Merge stdout & stderr output when logging.
    list(APPEND PARAMS LOG_MERGED_STDOUTERR TRUE)
    # message(STATUS "ExternalProject_Add(${PARAMS})")
    ExternalProject_Add(${PARAMS})
endfunction()
