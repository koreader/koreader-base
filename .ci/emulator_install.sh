#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

test -d "${HOME}/.luarocks" || {
    mkdir "${HOME}/.luarocks"
    cp /etc/luarocks/config-5.1.lua "${HOME}/.luarocks/config.lua"
    echo "wrap_bin_scripts = false" >>"${HOME}/.luarocks/config.lua"
    travis_retry luarocks --local install busted 2.0.0-1
    # for verbose_print module
    travis_retry luarocks --local install ansicolors
}
eval "$(luarocks path --bin)"

sudo apt-get update

# install clang for clang build
if [ "$CC" = "clang" ]; then
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

    sudo tee -a /etc/apt/sources.list.d/clang11.list >/dev/null <<EOF
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main
EOF

    sudo apt-get install -y clang-11
fi

# Install chrpath and a python interpreter for meson.
sudo apt-get install -y --no-install-recommends chrpath python3-minimal python3-pip
# Install meson.
python3 -m pip install meson
# shellcheck disable=SC2016
echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
