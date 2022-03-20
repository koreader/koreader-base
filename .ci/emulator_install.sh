#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

test -d "${HOME}/.luarocks" || {
    mkdir "${HOME}/.luarocks"
    cp /etc/luarocks/config-5.1.lua "${HOME}/.luarocks/config.lua"
    echo "wrap_bin_scripts = false" >>"${HOME}/.luarocks/config.lua"
    # Temporary workaround until upstream merges <https://github.com/Olivine-Labs/busted/pull/677>
    travis_retry luarocks --local build https://raw.githubusercontent.com/Olivine-Labs/busted/14c69b8ececb4575869c5efc61cd54820332fabe/busted-scm-2.rockspec
    # for verbose_print module
    travis_retry luarocks --local install ansicolors
}
eval "$(luarocks path --bin)"

# install clang for clang build
if [ "$CC" = "clang" ]; then
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

    sudo tee -a /etc/apt/sources.list.d/clang11.list >/dev/null <<EOF
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main
EOF

    sudo apt-get update
    sudo apt-get install -y clang-11
fi
