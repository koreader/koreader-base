#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

rm -rf "${HOME}/.luarocks"
mkdir "${HOME}/.luarocks"
cp "${TRAVIS_BUILD_DIR}/install/etc/luarocks/config.lua" "${HOME}/.luarocks/config.lua"
echo "wrap_bin_scripts = false" >>"$HOME/.luarocks/config.lua"
travis_retry luarocks --local install luacheck
travis_retry luarocks --local install lanes # for parallel luacheck
