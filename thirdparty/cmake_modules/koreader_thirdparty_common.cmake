if(NOT DEFINED PROCESSOR_COUNT)
  # Unknown:
  set(PROCESSOR_COUNT 0)

  # Linux:
  set(cpuinfo_file "/proc/cpuinfo")
  if(EXISTS "${cpuinfo_file}")
    file(STRINGS "${cpuinfo_file}" procs REGEX "^processor.: [0-9]+$")
    list(LENGTH procs PROCESSOR_COUNT)
  endif()

  # Mac:
  if(APPLE)
    execute_process(COMMAND sysctl -n hw.ncpu OUTPUT_VARIABLE ncpu)
    set(PROCESSOR_COUNT "${ncpu}")
  endif()

  # Windows:
  if(WIN32)
    set(PROCESSOR_COUNT "$ENV{NUMBER_OF_PROCESSORS}")
  endif()
endif()

if(NOT DEFINED PARALLEL_JOBS)
    math(EXPR PARALLEL_JOBS "${PROCESSOR_COUNT}+1")
endif()

macro(assert_var_defined varName)
    if(NOT DEFINED ${varName})
        message(FATAL_ERROR "${varName} variable not defined!")
    endif(NOT DEFINED ${varName})
endmacro(assert_var_defined)

macro(ep_get_source_dir varName)
    set(${varName} "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-prefix/src/${PROJECT_NAME}")
endmacro(ep_get_source_dir)

macro(ep_get_binary_dir varName)
    set(${varName} "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-prefix/src/${PROJECT_NAME}-build")
endmacro(ep_get_binary_dir)

set(KO_DOWNLOAD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build/downloads)
