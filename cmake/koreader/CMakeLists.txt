include(koreader_targets)

list(APPEND CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
if(NOT CMAKE_GENERATOR MATCHES "Ninja")
    list(APPEND CMAKE_ARGS -DCMAKE_TARGET_MESSAGES:BOOL=OFF)
endif()

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM})

external_project(
    BUILD_ALWAYS
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)

function(add_target_build_step NAME)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "" "DEPENDS" ${ARGN})
    set(BUILD_DEPS)
    foreach(DEP IN LISTS _DEPENDS)
        if(NOT ${DEP} IN_LIST PROJECTS)
            message(FATAL_ERROR "trying to add koreader step '${NAME}' with a dependency on undeclared project: ${DEP}")
        endif()
        list(APPEND BUILD_DEPS ${${DEP}_BYPRODUCTS})
    endforeach()
    set(STEP build-${NAME})
    if(NOT _EXCLUDE_FROM_ALL AND BUILD_DEPS)
        ExternalProject_Add_StepDependencies(koreader build-deps ${BUILD_DEPS})
    endif()
    if(BUILD_DEPS)
        add_custom_target(${NAME}-deps DEPENDS ${BUILD_DEPS})
    endif()
    ExternalProject_Add_Step(koreader ${STEP}
        ALWAYS TRUE
        COMMAND ${KO_MAKE_PROGRAM} ${NAME}
        COMMENT "Performing build step for '${NAME}'"
        DEPENDEES configure
        DEPENDS ${BUILD_DEPS}
        EXCLUDE_FROM_MAIN TRUE
        USES_TERMINAL TRUE
        WORKING_DIRECTORY ${BINARY_DIR}
    )
    ExternalProject_Add_StepTargets(koreader ${STEP})
    add_custom_target(${NAME} DEPENDS koreader-${STEP})
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
