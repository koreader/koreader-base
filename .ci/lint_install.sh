#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

# print some useful info
echo "pwd: $(pwd)"
ls

# follow deps are already included in ko docker image (used in circleci)
command -v luacheck || {
    test -d "${HOME}/.luarocks" || mkdir "${HOME}/.luarocks"
    echo "wrap_bin_scripts = false" >>"${HOME}/.luarocks/config.lua"
    travis_retry luarocks --local install luacheck
    travis_retry luarocks --local install lanes # for parallel luacheck
}
eval "$(luarocks path --bin)"
export PATH=$PATH:$HOME/.luarocks/bin

#install our own updated shellcheck
SHELLCHECK_URL="https://s3.amazonaws.com/travis-blue-public/binaries/ubuntu/14.04/x86_64/shellcheck-0.4.5.tar.bz2"
if ! command -v shellcheck; then
    curl -sSL "${SHELLCHECK_URL}" | tar --exclude 'SHA256SUMS' --strip-components=1 -C "${HOME}/bin" -xjf -
    chmod +x "${HOME}/bin/shellcheck"
    shellcheck --version
else
    echo -e "${ANSI_GREEN}Using cached shellcheck."
fi

# install shfmt
SHFMT_URL="https://github.com/mvdan/sh/releases/download/v2.6.4/shfmt_v2.6.4_linux_amd64"
if [ "$(shfmt --version)" != "v2.6.4" ]; then
    curl -sSL "${SHFMT_URL}" -o "${HOME}/bin/shfmt"
    chmod +x "${HOME}/bin/shfmt"
else
    echo -e "${ANSI_GREEN}Using cached shfmt."
fi
