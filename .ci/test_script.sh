#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

if [ "$TARGET" = "android" ]; then
    if [ -f build/arm-linux-androideabi/luajit ]; then
        echo "ERROR: android build should not include luajit binary."
        exit 1
    fi
elif [ "$EMULATE_READER" = "1" ]; then
    cp build/*/luajit "${HOME}/.luarocks/bin"
    # fetch font for base test
    travis_retry wget https://github.com/koreader/koreader-fonts/raw/master/droid/DroidSansMono.ttf
    export OUTPUT_DIR
    if [ -n "${KODEBUG+x}" ]; then
        KODEBUG_SUFFIX=-debug
    fi
    OUTPUT_DIR=$(ls -d ./build/x86_64-*linux-gnu${KODEBUG_SUFFIX})
    mkdir -p "${OUTPUT_DIR}/fonts/droid/"
    cp DroidSansMono.ttf "${OUTPUT_DIR}/fonts/droid/DroidSansMono.ttf"
    # finally make test
    travis_retry make test
fi

echo "test passed."
