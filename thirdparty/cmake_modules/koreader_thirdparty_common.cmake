include_guard(GLOBAL)

if (DARWIN)
    # Note: can't use `sed -i "" -e`, because cmake "helpfully"
    # filter-out the empty argument during command invocation…
    set(ISED sh -c "sed -i '' -e \"$@\"" --)
    set(STRIP_CMD ${CMAKE_STRIP} -x)
else()
    set(ISED sed -i -e)
    set(STRIP_CMD ${CMAKE_STRIP} --strip-unneeded)
endif()

set(KO_MAKE_RECURSIVE ${CMAKE_CURRENT_LIST_DIR}/komake.sh ${MAKE})
set(KO_NINJA_RECURSIVE ${CMAKE_CURRENT_LIST_DIR}/koninja.sh ${NINJA})
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

function(set_libname VAR NAME)
    cmake_parse_arguments("" "" "EXT;VERSION" "" ${ARGN})
    if(NOT DEFINED _EXT)
        set(_EXT ${LIB_EXT})
    endif()
    set(NAME lib${NAME} ${_EXT})
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

function(append_install_commands CMD_LIST)
    cmake_parse_arguments("" "" "DESTINATION" "" ${ARGN})
    if(_DESTINATION)
        get_filename_component(_DESTINATION ${_DESTINATION} ABSOLUTE BASE_DIR ${OUTPUT_DIR})
    else()
        set(_DESTINATION ${OUTPUT_DIR})
    endif()
    list(APPEND ${CMD_LIST} COMMAND ${CMAKE_COMMAND} -E make_directory ${_DESTINATION})
    list(APPEND ${CMD_LIST} COMMAND ${CMAKE_COMMAND} -E copy_if_different ${_UNPARSED_ARGUMENTS} ${_DESTINATION}/)
    set(${CMD_LIST} ${${CMD_LIST}} PARENT_SCOPE)
endfunction()

function(append_binary_install_command CMD_LIST)
    cmake_parse_arguments("" "" "DESTINATION" "" ${ARGN})
    if(DEFINED _DESTINATION)
        get_filename_component(_DESTINATION ${_DESTINATION} ABSOLUTE BASE_DIR ${OUTPUT_DIR})
    else()
        set(_DESTINATION ${OUTPUT_DIR})
    endif()
    list(APPEND ${CMD_LIST} COMMAND ${CMAKE_COMMAND} -E make_directory ${_DESTINATION})
    foreach(SRC IN LISTS _UNPARSED_ARGUMENTS)
        get_filename_component(DST ${SRC} NAME)
        set(DST ${_DESTINATION}/${DST})
        if(DO_STRIP)
            list(APPEND ${CMD_LIST} COMMAND ${STRIP_CMD} -o ${DST} ${SRC})
        else()
            list(APPEND ${CMD_LIST} COMMAND ${CMAKE_COMMAND} -E copy_if_different ${SRC} ${DST})
        endif()
    endforeach()
    set(${CMD_LIST} ${${CMD_LIST}} PARENT_SCOPE)
endfunction()

function(append_shared_lib_install_commands CMD_LIST)
    set_libname(LIB ${ARGN})
    append_binary_install_command(${CMD_LIST} ${STAGING_DIR}/lib/${LIB} DESTINATION ${OUTPUT_DIR}/libs)
    set(${CMD_LIST} ${${CMD_LIST}} PARENT_SCOPE)
endfunction()

if(DARWIN)
    function(append_shared_lib_fix_commands CMD_LIST)
        cmake_parse_arguments("" "ID;RPATH" "" "" ${ARGN})
        set_libname(LIB ${_UNPARSED_ARGUMENTS})
        list(APPEND ${CMD_LIST} COMMAND install_name_tool)
        if(_ID)
            list(APPEND ${CMD_LIST} -id @rpath/${LIB})
        endif()
        if(_RPATH)
            list(APPEND ${CMD_LIST} -add_rpath @executable_path/libs -add_rpath @executable_path/../koreader/libs)
        endif()
        list(APPEND ${CMD_LIST} ${STAGING_DIR}/lib/${LIB})
        set(${CMD_LIST} ${${CMD_LIST}} PARENT_SCOPE)
    endfunction()
endif()

function(append_tree_install_commands CMD_LIST SRC DST)
    get_filename_component(DST ${DST} ABSOLUTE BASE_DIR ${OUTPUT_DIR})
    list(APPEND ${CMD_LIST} COMMAND ${CMAKE_COMMAND} -E)
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.26")
        list(APPEND ${CMD_LIST} copy_directory_if_different)
    else()
        list(APPEND ${CMD_LIST} copy_directory)
    endif()
    set(${CMD_LIST} ${${CMD_LIST}} ${SRC} ${DST} PARENT_SCOPE)
endfunction()

# Improved external projects support.
include(ExternalProject)
# `ExternalProject` step targets fully adopt their steps.
if(POLICY CMP0114)
    cmake_policy(SET CMP0114 NEW)
endif()
# Transform paths in depfiles to be absolute.
if(POLICY CMP0116)
    cmake_policy(SET CMP0116 NEW)
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
function(external_project)
    cmake_parse_arguments(
        # Prefix.
        ""
        # Options.
        "BUILD_ALWAYS"
        # One value keywords.
        "URL_MD5;SOURCE_SUBDIR"
        # Multi-value keywords.
        "BUILD_COMMAND;CMAKE_ARGS;CONFIGURE_COMMAND;DOWNLOAD_COMMAND;INSTALL_COMMAND;PATCH_COMMAND;URL"
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
        list(APPEND PARAMS DOWNLOAD_DIR ${DOWNLOAD_DIR})
        list(APPEND PARAMS URL ${_URL})
        list(APPEND PARAMS URL_MD5 ${_URL_MD5})
    else()
        list(APPEND PARAMS DOWNLOAD_DIR .)
        if(DEFINED _DOWNLOAD_COMMAND)
            list(APPEND PARAMS DOWNLOAD_COMMAND ${_DOWNLOAD_COMMAND})
        endif()
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
    if(DEFINED ENV{CI})
        # Improve parallelization on CI builds.
        list(APPEND PARAMS USES_TERMINAL_BUILD FALSE)
    else()
        list(APPEND PARAMS USES_TERMINAL_BUILD TRUE)
    endif()
    # Install command.
    if(DEFINED _INSTALL_COMMAND)
        # NOTE: same as above, only work for a non-empty command.
        list(APPEND PARAMS LOG_INSTALL ${LOGGING})
    else()
        list(APPEND PARAMS INSTALL_COMMAND COMMAND)
    endif()
    # By-products.
    set(BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/stamp/${PROJECT_NAME}-done)
    if(NOT CMAKE_GENERATOR MATCHES "Ninja")
        list(PREPEND BYPRODUCTS ${PROJECT_NAME})
    endif()
    set_property(GLOBAL PROPERTY ${PROJECT_NAME}_BYPRODUCTS ${BYPRODUCTS})
    # Show a logged step output on failure.
    list(APPEND PARAMS LOG_OUTPUT_ON_FAILURE TRUE)
    # Merge stdout & stderr output when logging.
    list(APPEND PARAMS LOG_MERGED_STDOUTERR TRUE)
    # Add clean target.
    add_custom_target(${PROJECT_NAME}-clean
        # Remove build directory and by-products.
        COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}
        # And trigger reconfigure the build the next time.
        COMMAND touch ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    # message(STATUS "ExternalProject_Add(${PARAMS})")
    ExternalProject_Add(${PARAMS})
    # Build dependencies.
    set(BUILD_DEPS ${${PROJECT_NAME}_BUILD_DEPENDS})
    ExternalProject_Add_Step(${PROJECT_NAME} deps
        COMMENT "Completed dependencies for '${PROJECT_NAME}'"
        DEPENDERS configure
        DEPENDS ${BUILD_DEPS}
    )
    ExternalProject_Add_StepTargets(${PROJECT_NAME} deps)
    if(NOT _BUILD_ALWAYS AND (CMAKE_GENERATOR MATCHES "^Ninja" OR CMAKE_VERSION VERSION_GREATER_EQUAL "3.20"))
        set(SOURCE_D ${CMAKE_CURRENT_BINARY_DIR}/source.d)
        list(APPEND BUILD_DEPS ${SOURCE_D})
        add_custom_command(
            COMMENT "Generating source list for '${PROJECT_NAME}'"
            COMMAND ${THIRDPARTY_DIR}/cmake_modules/mk-source-deps.sh ${SOURCE_D} ${SOURCE_DIR}
            DEPENDS ${PROJECT_NAME}-configure
            DEPFILE ${SOURCE_D}
            OUTPUT ${SOURCE_D}
            VERBATIM
        )
    endif()
    ExternalProject_Add_Step(${PROJECT_NAME} build-deps
        COMMENT "Completed build dependencies for '${PROJECT_NAME}'"
        DEPENDERS build
        DEPENDS ${BUILD_DEPS}
    )
endfunction()
