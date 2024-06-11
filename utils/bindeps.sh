#!/usr/bin/env bash

set -eo pipefail

if [[ -n "${CLICOLOR_FORCE}" ]] || [[ -t 1 ]]; then
    GREEN=$'\033[32;1m'
    RESET=$'\033[0m'
else
    GREEN=''
    RESET=''
fi

os="$(uname -s)"
case "${os}" in
    Darwin)
        binary_mime_rx='application/x-mach-binary'
        bindeps() {
            otool -L "$1" | grep -E $'^\t'
            otool -l "$1" | sed -n -e '/^ *cmd LC_RPATH$/!d' -e ':_loop' -e 'n;/^ *path /!b_loop' -e 'p'
        }
        find_exe_opts=(-perm -300)
        ;;
    Linux)
        binary_mime_rx='application/x-(executable|pie-executable|sharedlib)'
        bindeps() {
            readelf -d "$1" | grep -wE '^readelf|NEEDED|RPATH|SONAME'
        }
        find_exe_opts=(-executable)
        ;;
    *)
        echo "unsupported operating system: ${os}" 1>&2
        exit 1
        ;;
esac

find "$@" -type f "${find_exe_opts[@]}" \
    -exec sh -c "file --brief --mime \"\$@\" | grep -Eq '^${binary_mime_rx};'" sh '{}' \; \
    -print | sort | while read -r -d $'\n' binary; do
    printf '%s%s%s\n' "${GREEN}" "${binary}" "${RESET}"
    bindeps "${binary}"
done

# vim: sw=4
