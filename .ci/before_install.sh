#!/usr/bin/env bash

# don't do this for clang
if [ "$CXX" = "g++" ]; then
    export CXX="g++-4.8" CC="gcc-4.8"
fi
# in case anything ignores the environment variables, override through PATH
mkdir bin
ln -s "$(command -v gcc-4.8)" bin/cc
ln -s "$(command -v gcc-4.8)" bin/gcc
ln -s "$(command -v c++-4.8)" bin/c++
ln -s "$(command -v g++-4.8)" bin/g++

export PATH=$PWD/bin:$PATH
