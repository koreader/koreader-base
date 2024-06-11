#!/usr/bin/env bash

set -eo pipefail

if [[ -n "${CLICOLOR_FORCE}" ]] || [[ -t 1 ]]; then
    GREEN=$'\033[32;1m'
    RESET=$'\033[0m'
    OK=$'\33[32m'
    KO=$'\33[31m'
else
    GREEN=''
    RESET=''
    OK=$'\33[32m'
    KO=$'\33[31m'
fi

LIBCHECK_DIR="${0%/*}/libcheck"

os="$(uname -s)"
case "${os}" in
    Linux)
        binary_mime_rx='application/x-sharedlib'
        libcheck() {
            set -x
            "${compiler[@]}" \
                -o /dev/null -shared \
                -Wl,--fatal-warnings \
                -Wl,--library-path="${LIBCHECK_DIR}" \
                -Wl,--no-as-needed \
                -Wl,--rpath-link="${LIBCHECK_DIR}" \
                -Wl,--unresolved-symbols=report-all \
                "$1" ${provide_lua_syms:+-l:libluajit.ld}
        }
        find_exe_opts=(-executable)
        ;;
    *)
        echo "unsupported operating system: ${os}" 1>&2
        exit 1
        ;;
esac

compiler=()
while [[ "$1" != '--' ]]; do
    compiler+=("$1")
    shift
done
provide_lua_syms="$2"
shift 2

find "$@" -type f "${find_exe_opts[@]}" \
    -exec sh -c "file --brief --mime \"\$@\" | grep -Eq '^${binary_mime_rx};'" sh '{}' \; \
    -print | sort | (
    exit_code=0
    while read -r -d $'\n' binary; do
        printf '%s%s%s… ' "${GREEN}" "${binary}" "${RESET}"
        if output="$(libcheck "${binary}" 2>&1)"; then
            printf '%s%s%s\n%s\n' "${OK}" OK "${RESET}" "${output}"
        else
            printf '%s%s%s\n%s\n' "${KO}" ERROR "${RESET}" "${output}"
            exit_code=2
        fi
    done
    exit ${exit_code}
)

# vim: sw=4
