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
    cp build/*/luajit "${HOME}/.luarocks/bin/"
    # install test data
    travis_retry make test-data
    # finally make test
    travis_retry make --assume-old=all test
fi

echo "test passed."
