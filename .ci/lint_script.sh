#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

"${CI_DIR}/helper_shellchecks.sh"

exclude="ffi/sha2.lua"

echo -e "\n${ANSI_GREEN}Luacheck results"
if ! command -v luajit; then
    luacheck --no-color -q --exclude-files "${exclude}" ffi spec
else
    luajit "$(command -v luacheck)" --no-color -q --exclude-files "${exclude}" ffi spec
fi
