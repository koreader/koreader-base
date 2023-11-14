include_guard(GLOBAL)

find_package(Git)

function(_ko_write_gitclone_script script_filename git_EXECUTABLE git_repository git_tag git_submodules src_name work_dir build_source_dir gitclone_infofile gitclone_stampfile)

# Default depth
set(git_clone_depth 50)

set(clone_checkout "${work_dir}")

  file(WRITE ${script_filename}
"if(\"${git_tag}\" STREQUAL \"\")
  message(FATAL_ERROR \"Tag for git checkout should not be empty.\")
endif()

######################################################################
# 1. if not cloned before, do it
# 2. try to checkout the requested revision 3 times:
#   - if the 1st try fails: try to fetch only the requested revision
#   - if the 2nd try fails: try to unshallow the repository
#   - if the 3rd try fails: game over…
# 3. update the requested sub-modules
# 4. copy everything over to source directory
######################################################################

set(run 0)

if(\"${gitclone_infofile}\" IS_NEWER_THAN \"${gitclone_stampfile}\")
  set(run 1)
endif()

if(NOT run)
  message(STATUS \"Avoiding repeated git clone, stamp file is up to date: '${gitclone_stampfile}'\")
  return()
endif()

set(should_clone 1)
if(EXISTS \"${work_dir}\")
  set(should_clone 0)
endif()

if(should_clone)
  # try the clone 3 times in case there is an odd git clone issue
  set(error_code 1)
  set(number_of_tries 0)
  while(error_code AND number_of_tries LESS 3)
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" clone --depth ${git_clone_depth} \"${git_repository}\" \"${clone_checkout}\"
      RESULT_VARIABLE error_code
    )
    math(EXPR number_of_tries \"\${number_of_tries} + 1\")
  endwhile()
  if(number_of_tries GREATER 1)
    message(STATUS \"Had to git clone more than once:
            \${number_of_tries} times.\")
  endif()
  if(error_code)
    message(FATAL_ERROR \"Failed to clone repository: '${git_repository}'\")
  endif()
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" sparse-checkout init
    RESULT_VARIABLE error_code
  )
  if(error_code)
    message(WARNING \"Failed to enable sparse checkout in: '${clone_checkout}'\")
  endif()
endif()

# checkout the requested revision
foreach(TRY RANGE 1 3)
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" checkout -f \"${git_tag}\" --
    RESULT_VARIABLE error_code
  )
  if(NOT error_code)
    break()
  endif()
  if(TRY EQUAL 1)
    message(STATUS \"Fetching revision: '${git_tag}'\")
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" fetch --recurse-submodules=no --depth ${git_clone_depth} origin \"+${git_tag}:refs/remotes/origin/${git_tag}\"
      RESULT_VARIABLE error_code
    )
    if(error_code)
      message(WARNING \"Failed to fetch revision from origin: '${git_tag}'\")
    endif()
  elseif(TRY EQUAL 2)
    message(STATUS \"Fetching full repo\")
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" remote rm origin
    )
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" remote add origin \"${git_repository}\"
    )
    execute_process(
      COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" fetch --unshallow --tags
      RESULT_VARIABLE error_code
    )
    if(error_code)
      message(WARNING \"Failed to unshallow repo\")
    endif()
  elseif(TRY EQUAL 3)
    message(FATAL_ERROR \"Failed to checkout revision: '${git_tag}'\")
  endif()
endforeach()

# Update sub-modules
if(NOT \"${git_submodules}\" STREQUAL \"none\")
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" submodule update --depth ${git_clone_depth} --force --init --recursive ${git_submodules}
    RESULT_VARIABLE error_code
  )
  if(error_code)
    message(FATAL_ERROR \"Failed to update submodules in: '${clone_checkout}'\")
  endif()
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" -C \"${clone_checkout}\" submodule foreach --recursive git sparse-checkout init
    RESULT_VARIABLE error_code
  )
  if(error_code)
    message(WARNING \"Failed to enable submodules sparse checkouts in: '${clone_checkout}'\")
  endif()
endif()

# Complete success, update the script-last-run stamp file:
execute_process(
  COMMAND \${CMAKE_COMMAND} -E copy
    \"${gitclone_infofile}\"
    \"${gitclone_stampfile}\"
  RESULT_VARIABLE error_code
)
if(error_code)
  message(FATAL_ERROR \"Failed to copy script-last-run stamp file: '${gitclone_stampfile}'\")
endif()

# Copy everything over to source directory
if(EXISTS ${build_source_dir})
  file(REMOVE_RECURSE ${build_source_dir})
endif()
get_filename_component(destination_dir \"${build_source_dir}\" DIRECTORY)
get_filename_component(destination_name \"${build_source_dir}\" NAME)
get_filename_component(source_name \"${clone_checkout}\" NAME)
if (NOT \${source_name\} STREQUAL \${destination_name})
    message(FATAL_ERROR \"source / destination basenames don't match: ${clone_checkout} / ${build_source_dir}\")
endif()
file(COPY \"${clone_checkout}\" DESTINATION \${destination_dir})

execute_process(
  COMMAND \"${git_EXECUTABLE}\" -C \"${build_source_dir}\" sparse-checkout disable
  RESULT_VARIABLE error_code
)
if(error_code)
  message(WARNING \"Failed to disable sparse checkout in: '${build_source_dir}'\")
endif()

if(NOT \"${git_submodules}\" STREQUAL \"none\")
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" -C \"${build_source_dir}\" submodule foreach --recursive git sparse-checkout disable
    RESULT_VARIABLE error_code
  )
  if(error_code)
    message(WARNING \"Failed to disable submodules sparse checkouts in: '${build_source_dir}'\")
  endif()
endif()

"
)
endfunction()

function(ko_write_gitclone_script script_filename git_repository git_tag build_source_dir)
    set(clone_dir ${CMAKE_CURRENT_SOURCE_DIR}/build/source)
    set(tmp_dir ${CMAKE_CURRENT_BINARY_DIR}/tmp/git)
    set(stamp_dir ${CMAKE_CURRENT_BINARY_DIR}/stamp/git)
    if(ARGC GREATER 4)
        set(git_submodules ${ARGV4})
    endif()
    message(STATUS "clone_dir=${clone_dir} / tmp_dir=${tmp_dir} / stamp_dir=${stamp_dir}")

    set(${script_filename} ${tmp_dir}/${PROJECT_NAME}-gitclone-${git_tag}.cmake)
    set(${script_filename} ${${script_filename}} PARENT_SCOPE)
    set(gitinfo_file ${stamp_dir}/${PROJECT_NAME}-gitinfo-${git_tag}.txt)

    if(NOT EXISTS ${gitinfo_file})
        # it's a new commit checkout, remove all previous script and gitinfo
        # files to force a rebuild
        file(REMOVE_RECURSE ${stamp_dir} ${tmp_dir})
    endif()

    # create new gitinfo file if needed
    if(${CMAKE_VERSION} VERSION_EQUAL "3.23.0" OR ${CMAKE_VERSION} VERSION_GREATER "3.23.0")
        set(gitinfo_configure "${CMAKE_ROOT}/Modules/ExternalProject/RepositoryInfo.txt.in")
    else()
        set(gitinfo_configure "${CMAKE_ROOT}/Modules/RepositoryInfo.txt.in")
    endif()
    configure_file(
      "${gitinfo_configure}"
      "${gitinfo_file}"
      @ONLY
    )

    _ko_write_gitclone_script(
        ${${script_filename}}
        ${GIT_EXECUTABLE}
        ${git_repository}
        ${git_tag}
        "${git_submodules}"
        ${PROJECT_NAME}
        ${clone_dir}
        ${build_source_dir}
        ${gitinfo_file}
        ${stamp_dir}/${PROJECT_NAME}-gitclone-lastrun.txt
    )
endfunction()

