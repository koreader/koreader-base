#!/bin/bash

set -e

run() {
    if [[ -n "${VERBOSE}" ]]; then
        printf '%q ' "$@"
        printf '\n'
    fi
    "$@"
}

if [[ $# -lt 6 ]]; then
    printf '%s: incorrect number of arguments' "$0"
    exit 1
fi

cmake="$1"
shlib="$2"
base_name="$3"
versionned_name="$4"
libs_dir="$5"
staging_dir="$6"
shift 6

if [[ $# -gt 0 ]]; then
    fixup_script="$1"
    fixup_dir="$2"
    shift 2
fi

if ! [[ -r "${shlib}" ]]; then
    printf 'cannot install, no such library: “%s”\n' "${shlib}"
    exit 1
fi

run mkdir -p "${libs_dir}" "${staging_dir}/shared"
run ln -snf "${libs_dir}" "${staging_dir}/shared/libs"
if [[ -n "${fixup_script}" ]]; then
    run "${cmake}" -E copy_if_different "${shlib}" "${staging_dir}/${versionned_name}"
    run "${fixup_script}" "${fixup_dir}:${staging_dir}/${versionned_name}" "$@"
    run "${cmake}" -E copy_if_different "${staging_dir}/${versionned_name}" "${libs_dir}/${versionned_name}"
    run rm -f "${staging_dir}/${versionned_name}"
else
    run "${cmake}" -E copy_if_different "${shlib}" "${libs_dir}/${versionned_name}"
fi
run ln -snf "${libs_dir}/${versionned_name}" "${staging_dir}/shared/${versionned_name}"
if [[ "${base_name}" != "${versionned_name}" ]]; then
    run ln -snf "${versionned_name}" "${staging_dir}/shared/${base_name}"
fi
