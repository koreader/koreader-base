include(koreader_targets)

list(APPEND CMAKE_ARGS -DCMAKE_KOVARS=${CMAKE_KOVARS} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})

list(APPEND BUILD_CMD COMMAND ninja)

external_project(
    BUILD_ALWAYS
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)

function(add_target_build_step NAME)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "" "DEPENDS" ${ARGN})
    foreach(DEP IN LISTS _DEPENDS)
        if(NOT ${DEP} IN_LIST PROJECTS)
            message(FATAL_ERROR "trying to add ${PROJECT_NAME} step '${NAME}' with a dependency on undeclared project: ${DEP}")
        endif()
    endforeach()
    if(NOT _EXCLUDE_FROM_ALL AND _DEPENDS)
        add_dependencies(${PROJECT_NAME}-build ${_DEPENDS})
    endif()
    set(COMMENT "Performing build step for '${NAME}'")
    add_custom_target(${NAME}-deps DEPENDS ${_DEPENDS})
    add_custom_target(
        ${NAME}
        COMMENT ${COMMENT}
        COMMAND set -- ${PROJECT_NAME} ${COMMENT} 0
        COMMAND . ${KOENV}
        COMMAND ninja ${NAME}
        DEPENDS ${PROJECT_NAME}-configure ${NAME}-deps
        WORKING_DIRECTORY ${BINARY_DIR}
        USES_TERMINAL
        VERBATIM
    )
endfunction()

function(add_targets)
    foreach(NAME IN LISTS KOREADER_TARGETS)
        if(${NAME}_EXCLUDE_FROM_ALL)
            set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
        else()
            set(EXCLUDE_FROM_ALL)
        endif()
        set(DEPENDS)
        foreach(DEP IN LISTS ${NAME}_DEPENDS)
            string(REGEX MATCH "^([^:]+)::([^:])+$" MATCHES ${DEP})
            list(APPEND DEPENDS ${CMAKE_MATCH_1})
        endforeach()
        add_target_build_step(${NAME} ${EXCLUDE_FROM_ALL} DEPENDS ${DEPENDS})
    endforeach()
endfunction()

add_targets()
