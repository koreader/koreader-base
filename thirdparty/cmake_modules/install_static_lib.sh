#!/bin/bash

set -e

run() {
    if [[ -n "${VERBOSE}" ]]; then
        printf '%q ' "$@"
        printf '\n'
    fi
    "$@"
}

if [[ $# -ne 3 ]]; then
    printf '%s: incorrect number of arguments' "$0"
    exit 1
fi

stlib="$1"
base_name="$2"
staging_dir="$3"

if ! [[ -r "${stlib}" ]]; then
    printf 'cannot install, no such library: “%s”\n' "${stlib}"
    exit 1
fi

run mkdir -p "${staging_dir}/static"
run ln -snf "${stlib}" "${staging_dir}/static/${base_name}"
