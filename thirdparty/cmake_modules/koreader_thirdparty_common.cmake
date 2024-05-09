if (DEFINED ENV{DARWIN})
    # Note: can't use `sed -i "" -e`, because cmake "helpfully"
    # filter-out the empty argument during command invocation…
    set(ISED sh -c "sed -i '' -e \"$@\"" --)
else()
    set(ISED sed -i -e)
endif()

set(KO_MAKE_RECURSIVE ${CMAKE_CURRENT_LIST_DIR}/komake.sh ${MAKE})
set(KO_NINJA_RECURSIVE ${CMAKE_CURRENT_LIST_DIR}/koninja.sh ${NINJA})
if(CMAKE_GENERATOR MATCHES "Ninja")
    set(KO_MAKE_PROGRAM ${KO_NINJA_RECURSIVE})
else()
    set(KO_MAKE_PROGRAM ${KO_MAKE_RECURSIVE})
endif()

set(KO_PATCH ${CMAKE_MODULE_PATH}/patch-wrapper.sh)

macro(assert_var_defined varName)
    if(NOT DEFINED ${varName})
        message(FATAL_ERROR "${varName} variable not defined!")
    endif()
endmacro()

macro(ep_get_source_dir varName)
    set(${varName} "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-prefix/src/${PROJECT_NAME}")
endmacro()

macro(ep_get_binary_dir varName)
    set(${varName} "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-prefix/src/${PROJECT_NAME}-build")
endmacro()

set(KO_DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/downloads")

if(DEFINED ENV{ANDROID})
    list(APPEND ANDROID_LIBTOOL_FIX_CMD ${ISED} $<SEMICOLON>
        -e "s|version_type=none|version_type=linux|"
        -e "s|need_lib_prefix=no|need_lib_prefix=yes|"
        -e "s|need_version=no|need_version=yes|"
        -e "s|library_names_spec=.*|library_names_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$versuffix \\\\$libname\\\\$release\\\\$shared_ext\\\\$major \\\\$libname\\\\$shared_ext\"|"
        -e "s|soname_spec=.*|soname_spec=\"\\\\$libname\\\\$release\\\\$shared_ext\\\\$major\"|"
        libtool)
endif()
