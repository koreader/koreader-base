#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

exit_code=0

"${CI_DIR}/helper_shellchecks.sh" || exit_code=1

echo -e "\n${ANSI_GREEN}Luacheck results${ANSI_RESET}"
luacheck -q ffi spec || exit_code=1

echo -e "\n${ANSI_GREEN}CMakeLint results${ANSI_RESET}"
mapfile -t cmake_files < <(git ls-files '*.cmake' '*/CMakeLists.txt')
cmakelint "${cmake_files[@]}" || exit_code=1

exit ${exit_code}
