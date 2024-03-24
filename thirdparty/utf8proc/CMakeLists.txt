cmake_minimum_required(VERSION 3.5.1)
project(utf8proc LANGUAGES)

include("koreader_thirdparty_common")
include("koreader_thirdparty_git")

assert_var_defined(CC)
assert_var_defined(LDFLAGS)

# Build in source tree.
set(BINARY_DIR "${SOURCE_DIR}")

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/JuliaStrings/utf8proc.git
    v2.9.0
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    BUILD_COMMAND ${KO_MAKE_RECURSIVE} -j${PARALLEL_JOBS}
)
