#!/bin/sh -e
NINJA="$1"
shift
PROJECT="${PWD%/*}"
PROJECT="${PROJECT##*/}"
if [ -n "${CLICOLOR_FORCE}" ] || [ -t 1 ]; then
    STYLE="$(printf '\33[32m')"
    RESET="$(printf '\33[0m')"
else
    STYLE=''
    RESET=''
fi
export NINJA_STATUS="      | [${STYLE}${PROJECT} %p${RESET}] "
# shellcheck disable=2086
exec "${NINJA}" ${NINJAFLAGS} "$@"
# vim: sw=4
