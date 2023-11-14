#!/bin/bash

set -e

run() {
    if [[ -n "${VERBOSE}" ]]; then
        printf '%q ' "$@"
        printf '\n'
    fi
    "$@"
}

if [[ $# -lt 2 ]]; then
    printf '%s: incorrect number of arguments' "$0"
    exit 1
fi

include_dir="$1"
shift

run mkdir -p "${include_dir}"

for spec in "$@"; do
    # shellcheck disable=SC2206
    hdrlist=(${spec})
    for hdr in "${hdrlist[@]}"; do
        if ! [[ -r "${hdr}" ]]; then
            printf 'cannot install, no such header: “%s”\n' "${hdr}"
            exit 1
        fi
        run ln -snf "${hdr}" "${include_dir}/${hdr##*/}"
    done
done
