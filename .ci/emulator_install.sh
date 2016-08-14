#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CI_DIR}/common.sh"

mkdir $HOME/.luarocks
cp /etc/luarocks/config.lua $HOME/.luarocks/config.lua
echo "wrap_bin_scripts = false" >> $HOME/.luarocks/config.lua
# recent versions of busted may cause some weird segmentation faults
# - git clone https://github.com/Olivine-Labs/busted/
# - cd busted && git checkout v1.10.0 && luarocks --local make busted-1.10.0-0.rockspec && cd ..
travis_retry luarocks --local install busted 2.0.rc12-1
# for verbose_print module
travis_retry luarocks --local install ansicolors
eval $(luarocks path --bin)
export PATH=$PATH:$HOME/.luarocks/bin

