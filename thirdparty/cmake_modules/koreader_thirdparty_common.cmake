if(NOT DEFINED PROCESSOR_COUNT)
    include(ProcessorCount)
    ProcessorCount(N)
    # 0 if unknown
    set(PROCESSOR_COUNT ${N})
endif()

if (DEFINED ENV{DARWIN})
    # Note: can't use `sed -i "" -e`, because cmake "helpfully"
    # filter-out the empty argument during command invocation…
    set(ISED sh -c "sed -i '' -e \"$@\"" --)
else()
    set(ISED sed -i -e)
endif()

if(NOT DEFINED PARALLEL_JOBS)
    math(EXPR PARALLEL_JOBS "${PROCESSOR_COUNT}+1")
endif()

if(NOT DEFINED CONSTRAINED_PARALLEL_JOBS)
    # Default to ${PROCESSOR_COUNT} instead of ${PROCESSOR_COUNT}+1
    set(CONSTRAINED_PARALLEL_JOBS ${PROCESSOR_COUNT})

    # Some compilations (like harfbuzz) are known to OOM on memory-constrained CI.
    if(DEFINED ENV{CIRCLECI})
        set(CONSTRAINED_PARALLEL_JOBS 1)
    endif()
endif()

# $(MAKE) is for recursive make invocations, but evidently when using another
# generator there's no recursion. For us that other generator is ninja, but
# maybe one day also Visual Studio or Xcode…
if(CMAKE_GENERATOR MATCHES Makefiles)
    set(KO_MAKE_RECURSIVE "$(MAKE)")
else()
    set(KO_MAKE_RECURSIVE make)
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
