if(NOT DEFINED PROCESSOR_COUNT)
    include(ProcessorCount)
    ProcessorCount(N)
    # 0 if unknown
    set(PROCESSOR_COUNT ${N})
endif()

if(APPLE)
    set(ISED "sed -i '' -e")
else()
    set(ISED "sed -i -e")
endif()

if(NOT DEFINED PARALLEL_JOBS)
    math(EXPR PARALLEL_JOBS "${PROCESSOR_COUNT}+1")
endif()

# $(MAKE) is for recursive make invocations, but evidently when using another
# generator there's no recursion. For us that other generator is ninja, but
# maybe one day also Visual Studio or Xcode…
if(CMAKE_GENERATOR MATCHES Makefiles)
    set(KO_MAKE_RECURSIVE "$(MAKE)")
else()
    set(KO_MAKE_RECURSIVE make)
endif()

set(KO_PATCH "${CMAKE_MODULE_PATH}/patch-wrapper.sh")

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
