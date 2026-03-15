#!/bin/bash

set -eo pipefail

extract_cdefs() {
    sed -n '/^ffi.cdef\[\[$/{:_1;n;/^\]\]$/Q;/{$/{h;:_2;n;H;/^}.*;$/!b_2;g;s/\n/\t/g};p;b_1}' "$1"
}

pretty_cdefs() {
    tr $'\t' $'\n' <"$1"
}

output_cdefs_prolog() {
    printf '%s\n' "-- Automatically generated with $0." '' 'local ffi = require("ffi")' '' 'ffi.cdef[['
}

output_cdefs_epilog() {
    printf '%s\n' ']]'
}

[[ $# -ge 4 ]]

tmpdir="$(mktemp -d)"
# shellcheck disable=SC2064
trap "rm -rf ${tmpdir@Q}" EXIT

output="$1"
input="$2"
shift 2

[[ -d "${input}" ]]

# Find out common cdefs.
touch "${tmpdir}/common"
for v in "$@"; do
    extract_cdefs "${input}/inkview_h_${v}.lua" >"${tmpdir}/${v}"
    if [[ -s "${tmpdir}/common" ]]; then
        # Keep cdefs in common.
        grep -xFf "${tmpdir}/common" "${tmpdir}/${v}" >"${tmpdir}/common.tmp"
        mv "${tmpdir}/common.tmp" "${tmpdir}/common"
    else
        cp "${tmpdir}/${v}" "${tmpdir}/common"
    fi
done

# Update individual versions cdefs to keep only symbols not in common.
# Additionally, eliminate duplicates: when a version specific cdefs
# are the same as the previous one.
prev_v=''
versions=()
for v in "$@"; do
    grep -xvFf "${tmpdir}/common" "${tmpdir}/${v}" >"${tmpdir}/${v}.tmp"
    mv "${tmpdir}/${v}.tmp" "${tmpdir}/${v}"
    if [[ -n "${prev_v}" ]]; then
        diff="$(diff --unified --label "${prev_v}" --label "${v}" "${tmpdir}/${prev_v}" "${tmpdir}/${v}" || [[ $? -lt 2 ]])"
        # printf '%s' "${diff}" | delta
        [[ -n "${diff}" ]] || continue
    fi
    versions+=("${v}")
    prev_v="${v}"
done

{
    cat <<EOF
-- Automatically generated with $0.

local ffi = require("ffi")
local C = ffi.C

local target_pocketbook_version
for ver in string.gmatch("${versions[@]}", "%d+") do
    ver = tonumber(ver)
    if C.POCKETBOOK_VERSION >= ver then
        target_pocketbook_version = ver
    end
end
if not target_pocketbook_version then
    error("unsupported PocketBook software version: " .. tonumber(C.POCKETBOOK_VERSION))
EOF
    for v in "${versions[@]}"; do
        printf '%s\n' "elseif target_pocketbook_version == ${v} then" '    ffi.cdef[['
        pretty_cdefs "${tmpdir}/${v}"
        printf '%s\n' '    ]]'
    done
    printf '%s\n' 'end' '' 'print("targeting PocketBook SDK version " .. target_pocketbook_version)' '' 'ffi.cdef[['
    pretty_cdefs "${tmpdir}"/common
    printf '%s\n' ']]'
} >"${output}"
