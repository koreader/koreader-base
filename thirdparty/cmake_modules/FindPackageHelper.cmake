include(FindPackageHandleStandardArgs)

function(find_package_helper NAME)
    cmake_parse_arguments("" "" "" "FIND_LIB_ARGS;FIND_HDR_ARGS" ${ARGN})
    if(NOT ${NAME}_LIBRARY)
        find_library(${NAME}_LIBRARY ${_FIND_LIB_ARGS})
    endif()
    if(NOT ${NAME}_INCLUDE_DIR)
        find_path(${NAME}_INCLUDE_DIR ${_FIND_HDR_ARGS})
    endif()
    find_package_handle_standard_args(${NAME} REQUIRED_VARS ${NAME}_LIBRARY ${NAME}_INCLUDE_DIR)
    set(${NAME}_FOUND ${NAME}_FOUND PARENT_SCOPE)
    if(${NAME}_FOUND)
        set(${NAME}_INCLUDE_DIRS ${${NAME}_INCLUDE_DIR} PARENT_SCOPE)
        set(${NAME}_LIBRARIES ${${NAME}_LIBRARY} PARENT_SCOPE)
        if(NOT TARGET ${NAME}::${NAME})
            add_library(${NAME}::${NAME} UNKNOWN IMPORTED)
            set_target_properties(${NAME}::${NAME} PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIR}"
                IMPORTED_LOCATION "${${NAME}_LIBRARY}"
            )
        endif()
    endif()
endfunction()
