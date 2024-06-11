#!/usr/bin/env bash

set -eo pipefail

if [[ -n "${CLICOLOR_FORCE}" ]] || [[ -t 1 ]]; then
    CLICOLOR_FORCE=1
fi

if [[ -n "${CLICOLOR_FORCE}" ]]; then
    declare -r ANSI_GREEN=$'\e[32;1m'
    declare -r ANSI_RED=$'\e[31;1m'
    declare -r ANSI_RESET=$'\e[0m'
else
    declare -r ANSI_GREEN=''
    declare -r ANSI_RED=''
    declare -r ANSI_RESET=''
fi

info() {
    printf '%s' "${ANSI_GREEN}" "$*" "${ANSI_RESET}" $'\n'
}

warn() {
    printf '%s' "${ANSI_RED}" "$*" "${ANSI_RESET}" $'\n'
}

shellcheck() {
    local cmd=(command shellcheck)
    if [[ -n "${CLICOLOR_FORCE}" ]]; then
        cmd+=(--color=always)
    fi
    cmd+=(--enable=require-variable-braces --norc)
    "${cmd[@]}" "$@"
}

shfmt() {
    # -i 4: indent unit is 4 spaces
    # -ci: switch cases will be indented
    command shfmt -i 4 -ci "$@"
}

diff() {
    local cmd=(command diff --unified)
    if [[ -n "${CLICOLOR_FORCE}" ]]; then
        cmd+=(--color=always)
    fi
    "${cmd[@]}" "$@"
}

exit_code=0

for shellscript in "$@"; do
    info "Running shellcheck on ${shellscript}"
    shellcheck "${shellscript}" || exit_code=1
    info "Running shfmt on ${shellscript}"
    # First pass: detect syntax errors.
    if ! out="$(shfmt -kp "${shellscript}" 2>&1)"; then
        warn "Warning: ${shellscript} contains the following problem:"
        printf '%s\n' "${out}"
        exit_code=1
        continue
    fi
    # Second pass: check style.
    if ! out="$(diff --label="actual/${shellscript}" "${shellscript}" --label="expect/${shellscript}" <(shfmt "${shellscript}"))"; then
        warn "Warning: ${shellscript} does not abide by coding style, diff for expected style:"
        printf '%s\n' "${out}"
        exit_code=1
    fi
done

exit "${exit_code}"

# vim: sw=4
