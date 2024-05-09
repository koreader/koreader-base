#!/bin/sh -e
NINJA="$1"
shift
# shellcheck disable=2086
exec "${NINJA}" ${NINJAFLAGS} "$@"
# vim: sw=4
