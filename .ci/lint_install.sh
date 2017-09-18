#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

# print some useful info
echo "TRAVIS_BUILD_DIR: ${TRAVIS_BUILD_DIR}"
echo "pwd: $(pwd)"
ls

travis_retry luarocks --local install luacheck
travis_retry luarocks --local install lanes # for parallel luacheck
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
SHFMT_URL="https://github.com/mvdan/sh/releases/download/v1.3.1/shfmt_v1.3.1_linux_amd64"
if [ "$(shfmt --version)" != "v1.3.1" ]; then
    curl -sSL "${SHFMT_URL}" -o "${HOME}/bin/shfmt"
    chmod +x "${HOME}/bin/shfmt"
else
    echo -e "${ANSI_GREEN}Using cached shfmt."
fi
