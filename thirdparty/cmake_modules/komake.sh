#!/bin/sh -e
unset MAKEOVERRIDES
MAKEFLAGS="${MAKEFLAGS%% -- *}"
MAKE="$1"
shift
# shellcheck disable=2086
exec "${MAKE}" ${PARALLEL_JOBS:+-j}${PARALLEL_JOBS} ${PARALLEL_LOAD:+-l}${PARALLEL_LOAD} "$@"
# vim: sw=4
