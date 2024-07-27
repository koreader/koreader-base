#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

exit_code=0

echo -e "${ANSI_GREEN}Bincheck results${ANSI_RESET}"
make bincheck || exit_code=1

if [ "${EMULATE_READER}" = "1" ]; then
    echo -e "\n${ANSI_GREEN}Testsuite${ANSI_RESET}"
    # cp build/luajit "${HOME}/.luarocks/bin/"
    (
        # install test data
        travis_retry make test-data
        # finally make test
        travis_retry make --assume-old=all test
    ) || exit_code=1
else
    if [ "${TARGET}" = "android" ] && [ -f build/luajit ]; then
        echo -e "\n${ANSI_RED}ERROR${ANSI_RESET}: android build should not include luajit binary."
        exit_code=1
    fi
fi

exit ${exit_code}
