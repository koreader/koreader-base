find_package(Git REQUIRED)

# Transform paths in depfiles to be absolute.
if(POLICY CMP0116)
    cmake_policy(SET CMP0116 NEW)
endif()

# Stricter `add_custom_command()` (rejects invalid argument(s)).
if(POLICY CMP0175)
    cmake_policy(SET CMP0175 NEW)
endif()

# Crappy macOS command line utilities strike again…
set(PRINTF_QS "%q")
if(CMAKE_HOST_APPLE)
    set(PRINTF_QS "'%s'")
endif()
set(KOENV ${CMAKE_BINARY_DIR}/koenv.sh)
configure_file(${CMAKE_CURRENT_LIST_DIR}/koenv.sh ${KOENV} @ONLY)
file(MD5 ${CMAKE_TOOLCHAIN_FILE} CMAKE_TOOLCHAIN_FILE_MD5)

function(external_project_step NAME)

    # Arguments.
    cmake_parse_arguments(
        PARSE_ARGV 1
        # Prefix.
        ""
        # Options.
        "ALWAYS;ONLY_ONCE;USES_TERMINAL"
        # One value keywords.
        "DEPFILE;WORKING_DIRECTORY"
        # Multi-value keywords.
        "AFTER;BEFORE;COMMAND;COMMENT;DEPENDS;OUTPUTS;TRIGGERS"
    )
    if(_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "unparsed arguments: ${_UNPARSED_ARGUMENTS}")
    endif()

    get_property(PROJECT_STEPS TARGET ${PROJECT_NAME} PROPERTY STEPS)
    if(NAME IN_LIST PROJECT_STEPS)
        message(FATAL_ERROR "step already defined: ${NAME}")
    endif()

    set(SPEC)
    set(STAMP)
    if(DEFINED _COMMAND)
        set(LOGFILE)
        set(STAMP ${CMAKE_CURRENT_BINARY_DIR}/stamp/${NAME})
        if(NOT "$ENV{CI}" STREQUAL "")
            # CI: no need for logging, and don't use the terminal.
            set(_USES_TERMINAL)
        elseif(_USES_TERMINAL)
            set(_USES_TERMINAL USES_TERMINAL)
        else()
            set(_USES_TERMINAL)
            set(LOGFILE ${CMAKE_CURRENT_BINARY_DIR}/log/${NAME})
        endif()
        set(ONLY_ONCE 0)
        if(_ONLY_ONCE)
            set(ONLY_ONCE 1)
        endif()
        string(REGEX REPLACE [[(^|\\;)(COMMAND\\;)+]] [[\1COMMAND\\;run\\;]] _COMMAND "${_COMMAND}")
        set(SPEC
            COMMENT "${_COMMENT}"
            COMMAND : "$<JOIN:$<TARGET_PROPERTY:${PROJECT_NAME}-${NAME},TRIGGERS>, >"
            COMMAND set --  ${PROJECT_NAME} ${_COMMENT} ${ONLY_ONCE} ${STAMP} ${LOGFILE}
            COMMAND . ${KOENV}
            COMMAND ${_COMMAND}
            DEPENDS $<TARGET_PROPERTY:${PROJECT_NAME}-${NAME},DEPENDS>
            VERBATIM
            ${_USES_TERMINAL}
        )
        if(DEFINED _WORKING_DIRECTORY)
            list(APPEND SPEC WORKING_DIRECTORY ${_WORKING_DIRECTORY})
        endif()
        if(DEFINED _DEPFILE)
            list(APPEND SPEC DEPFILE ${_DEPFILE})
        endif()
    else()
        if(_ONLY_ONCE OR DEFINED _TRIGGERS)
            message(FATAL_ERROR "unsupported: with ONLY_ONCE / TRIGGERS and no COMMAND")
        endif()
    endif()
    if(_ALWAYS OR NOT SPEC)
        add_custom_target(${PROJECT_NAME}-${NAME} ${SPEC} BYPRODUCTS ${_OUTPUTS} ${STAMP})
    else()
        add_custom_command(${SPEC} OUTPUT ${_OUTPUTS} ${STAMP})
        add_custom_target(${PROJECT_NAME}-${NAME} DEPENDS ${STAMP})
    endif()

    # Update properties.
    set_property(TARGET ${PROJECT_NAME}-${NAME} APPEND PROPERTY TRIGGERS "${_TRIGGERS}")
    set_property(TARGET ${PROJECT_NAME}-${NAME} APPEND PROPERTY DEPENDS "${_DEPENDS}")
    set_property(TARGET ${PROJECT_NAME}-${NAME} PROPERTY STAMP ${STAMP})
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY STEPS ${NAME})
    set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY BYPRODUCTS ${STAMP})
    add_dependencies(${PROJECT_NAME} ${PROJECT_NAME}-${NAME})

    # Inter-steps dependencies.
    set(INTER_STEPS_DEPS)
    foreach(STEP IN LISTS _AFTER)
        if(NOT STEP IN_LIST PROJECT_STEPS)
            message(FATAL_ERROR "invalid AFTER step: ${STEP}")
        endif()
        list(APPEND INTER_STEPS_DEPS ${NAME} ${STEP})
    endforeach()
    foreach(STEP IN LISTS _BEFORE)
        if(NOT STEP IN_LIST PROJECT_STEPS)
            message(FATAL_ERROR "invalid BEFORE step: ${STEP}")
        endif()
        list(APPEND INTER_STEPS_DEPS ${STEP} ${NAME})
    endforeach()
    while(INTER_STEPS_DEPS)
        list(POP_FRONT INTER_STEPS_DEPS STEP1 STEP2)
        add_dependencies(${PROJECT_NAME}-${STEP1} ${PROJECT_NAME}-${STEP2})
        get_property(STAMP2 TARGET ${PROJECT_NAME}-${STEP2} PROPERTY STAMP)
        set_property(TARGET ${PROJECT_NAME}-${STEP1} APPEND PROPERTY DEPENDS ${STAMP2})
    endwhile()

endfunction()

function(external_project)

    # Arguments.
    cmake_parse_arguments(
        PARSE_ARGV 0
        # Prefix.
        ""
        # Options.
        "BUILD_ALWAYS;PROTECTED"
        # One value keywords.
        "PATCH_OVERLAY;SOURCE_SUBDIR"
        # Multi-value keywords.
        "BUILD_COMMAND;BUILD_DEPENDS;CMAKE_ARGS;CONFIGURE_COMMAND;DOWNLOAD;INSTALL_COMMAND;PATCH_COMMAND;PATCH_FILES"
    )
    if(_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "unparsed arguments: ${_UNPARSED_ARGUMENTS}")
    endif()

    set(OUT_OF_TREE_BUILD TRUE)
    if(BINARY_DIR STREQUAL SOURCE_DIR)
        set(OUT_OF_TREE_BUILD FALSE)
    endif()
    set(ONLY_ONCE)
    if(_PROTECTED)
        set(ONLY_ONCE ONLY_ONCE)
    endif()

    # Main target.
    add_custom_target(${PROJECT_NAME} ALL)

    # Download.
    set(CMD)
    set(DOWNLOAD_METHOD)
    set(DOWNLOAD_URL_FILE)
    set(DOWNLOAD_GIT_REPO_ARGS)
    set(PROJECT_HASH)
    if(DEFINED _DOWNLOAD)
        list(LENGTH _DOWNLOAD LEN)
        list(POP_FRONT _DOWNLOAD DOWNLOAD_METHOD)
        if(LEN LESS "3" OR NOT (DOWNLOAD_METHOD STREQUAL "GIT" OR DOWNLOAD_METHOD STREQUAL "URL"))
            message(FATAL_ERROR "invalid DOWNLOAD arguments: ${_DOWNLOAD}")
        endif()
        if(DOWNLOAD_METHOD STREQUAL "GIT")
            # DOWNLOAD: <revision> <remote> <submodules>*
            list(POP_FRONT _DOWNLOAD GIT_REVISION GIT_REMOTE)
            set(GIT_SUBMODULES ${_DOWNLOAD})
            set(GIT_CLONE ${DOWNLOAD_DIR}/source)
            list(APPEND CMD COMMAND clone_git_repo ${GIT_CLONE} ${GIT_REMOTE} ${GIT_REVISION} ${GIT_SUBMODULES})
            set(PROJECT_HASH ${GIT_REVISION})
        elseif(DOWNLOAD_METHOD STREQUAL "URL")
            # DOWNLOAD: <md5> <url>+
            list(GET _DOWNLOAD 0 DOWNLOAD_MD5)
            list(GET _DOWNLOAD 1 DOWNLOAD_URL_FILE)
            get_filename_component(DOWNLOAD_URL_FILE ${DOWNLOAD_URL_FILE} NAME)
            set(DOWNLOAD_URL_FILE ${DOWNLOAD_DIR}/${DOWNLOAD_URL_FILE})
            list(APPEND CMD COMMAND download_archive ${DOWNLOAD_URL_FILE} ${_DOWNLOAD})
            set(PROJECT_HASH ${DOWNLOAD_MD5})
        endif()
    endif()
    external_project_step(
        download
        COMMENT "Downloading '${PROJECT_NAME}'"
        COMMAND "${CMD}"
    )
    set_property(TARGET ${PROJECT_NAME} PROPERTY HASH ${PROJECT_HASH})

    # Prepare.
    set(CMD)
    set(TRIGGERS)
    # Create source tree.
    if(DOWNLOAD_METHOD STREQUAL "GIT")
        list(APPEND CMD COMMAND checkout_git_repo ${SOURCE_DIR} ${GIT_CLONE} ${GIT_REVISION})
    elseif(DOWNLOAD_METHOD STREQUAL "URL")
        list(APPEND CMD COMMAND extract_archive ${SOURCE_DIR} ${DOWNLOAD_URL_FILE})
    endif()
    # Patch source tree:
    # - overlay directory
    # - patch files
    # - command
    if(DEFINED _PATCH_OVERLAY OR DEFINED _PATCH_FILES OR DEFINED _PATCH_COMMAND)
        if(NOT DEFINED _DOWNLOAD)
            message(FATAL_ERROR "unsupported: with PATCH_FILES and/or PATCH_COMMAND but no DOWNLOAD")
        endif()
        list(APPEND CMD COMMAND cd ${SOURCE_DIR})
    endif()
    if(DEFINED _PATCH_OVERLAY)
        get_filename_component(OVERLAY_PATH ${_PATCH_OVERLAY} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
        file(GLOB_RECURSE OVERLAY_FILES ${OVERLAY_PATH}/*)
        set(OVERLAY_MANIFEST)
        foreach(F IN LISTS _BEFORE)
            file(MD5 ${F} MD5)
            list(APPEND OVERLAY_MANIFEST ${MD5})
            file(MD5 ${F} MD5)
        endforeach()
        string(MD5 MD5 "${OVERLAY_MANIFEST}")
        list(APPEND TRIGGERS overlay:${MD5})
        list(APPEND CMD COMMAND ${CMAKE_COMMAND} -E copy_directory ${OVERLAY_PATH} .)
    endif()
    if(DEFINED _PATCH_FILES)
        list(APPEND CMD COMMAND apply_patches)
        foreach(PATCH IN LISTS _PATCH_FILES)
            get_filename_component(PATCH_PATH ${PATCH} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
            set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${PATCH_PATH})
            list(APPEND CMD ${PATCH_PATH})
            file(MD5 ${PATCH_PATH} MD5)
            list(APPEND TRIGGERS ${PATCH}:${MD5})
        endforeach()
    endif()
    if(DEFINED _PATCH_COMMAND)
        list(APPEND CMD COMMAND ${_PATCH_COMMAND})
    endif()
    # Generate source list.
    set(SOURCE_LIST)
    if(NOT OUT_OF_TREE_BUILD OR NOT _BUILD_ALWAYS)
        set(SOURCE_LIST "${CMAKE_CURRENT_BINARY_DIR}/source.list")
        list(APPEND CMD COMMAND list_tree ${SOURCE_DIR} ${SOURCE_LIST})
    endif()
    # And build step depfile.
    set(BUILD_D)
    if(NOT _BUILD_ALWAYS)
        set(BUILD_D "${CMAKE_CURRENT_BINARY_DIR}/build.d")
        list(APPEND CMD COMMAND generate_depfile ${BUILD_D} ${CMAKE_CURRENT_BINARY_DIR}/stamp/build ${SOURCE_LIST})
    endif()
    external_project_step(
        prepare AFTER download
        COMMENT "Preparing '${PROJECT_NAME}'"
        COMMAND "${CMD}"
        TRIGGERS ${TRIGGERS}
        OUTPUTS ${SOURCE_LIST}
        ${ONLY_ONCE}
    )

    # (Configure) dependencies.
    external_project_step(deps COMMENT "Completed dependencies for '${PROJECT_NAME}'")

    # Configure.
    set(CMD)
    if(DEFINED _CMAKE_ARGS OR DEFINED _CONFIGURE_COMMAND)
        if(DEFINED _CMAKE_ARGS AND DEFINED _CONFIGURE_COMMAND)
            message(FATAL_ERROR "unsupported: with both CMAKE_ARGS and CONFIGURE_COMMAND")
        endif()
        if(DEFINED _CMAKE_ARGS)
            list(APPEND CMD COMMAND ${CMAKE_COMMAND} -G Ninja
                -S ${SOURCE_DIR}/${_SOURCE_SUBDIR}
                -B ${BINARY_DIR} ${_CMAKE_ARGS}
            )
        elseif(DEFINED _CONFIGURE_COMMAND)
            list(APPEND CMD COMMAND cd ${BINARY_DIR})
            list(APPEND CMD COMMAND ${_CONFIGURE_COMMAND})
        endif()
    endif()
    if(CMD OR _BUILD_COMMAND)
        # (Re-)configure from a clean slate.
        if(OUT_OF_TREE_BUILD)
            list(PREPEND CMD COMMAND rm -rf ${BINARY_DIR} COMMAND mkdir -p ${BINARY_DIR})
        else()
            list(PREPEND CMD COMMAND clean_tree ${SOURCE_DIR} ${SOURCE_LIST})
        endif()
    endif()
    external_project_step(
        configure AFTER deps prepare
        COMMENT "Configuring '${PROJECT_NAME}'"
        COMMAND "${CMD}"
        # Trigger a rebuild on change to compilation flags.
        TRIGGERS toolchain:${CMAKE_TOOLCHAIN_FILE_MD5}
        ${ONLY_ONCE}
    )

    # Build.
    set(ALWAYS)
    set(DEPFILE)
    if(_BUILD_ALWAYS)
        set(ALWAYS ALWAYS)
    elseif(BUILD_D)
        set(DEPFILE DEPFILE ${BUILD_D})
    endif()
    if(DEFINED _BUILD_DEPENDS)
        file(GLOB _BUILD_DEPENDS LIST_DIRECTORIES false ${_BUILD_DEPENDS})
    endif()
    external_project_step(
        build AFTER configure
        COMMENT "Building '${PROJECT_NAME}'"
        COMMAND "${_BUILD_COMMAND}"
        DEPENDS ${_BUILD_DEPENDS}
        WORKING_DIRECTORY ${BINARY_DIR}
        USES_TERMINAL
        ${ALWAYS}
        ${DEPFILE}
    )

    # Install.
    external_project_step(
        install AFTER build
        COMMENT "Installing '${PROJECT_NAME}'"
        COMMAND "${_INSTALL_COMMAND}"
        WORKING_DIRECTORY ${BINARY_DIR}
        ${ALWAYS}
    )

    # Clean target.
    add_custom_target(
        ${PROJECT_NAME}-clean
        COMMENT "Cleaning '${PROJECT_NAME}'"
        COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}
    )

endfunction()
