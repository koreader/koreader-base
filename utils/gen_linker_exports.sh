#!/usr/bin/env bash

set -eo pipefail

debug=0

[[ $# -gt 3 ]]

linker="$1"
link_args="$2"
exports_script="$3"
shift 3

linker_version="$("${linker}" -v 2>&1)"
case "${linker_version}" in
    *PROJECT:ld64-* | *PROJECT:dyld-* | *PROJECT:ld-*)
        symarg='-u _%s\n'
        vsarg='-exported_symbols_list %s\n'
        vsfmt='export'
        ;;
    GNU\ ld\ * | mold\ *)
        symarg='--require-defined=%s\n'
        vsarg='--version-script=%s\n'
        vsfmt='version'
        ;;
    GNU\ gold | LLD\ *)
        symarg='--undefined=%s\n'
        vsarg='--version-script=%s\n'
        vsfmt='version'
        ;;
    *)
        # symarg=''
        # vsarg=''
        # vsfmt='blank'
        echo "unsupported linker: ${linker} [${linker_version}]" 1>&2
        exit 1
        ;;
esac

if [[ ${debug} -eq 1 ]]; then
    echo "symarg: ${symarg}"
    echo "vsarg: ${vsarg}"
    echo "vsfmt: ${vsfmt}"
fi

out="$(sed -E -n -e 's,^[[:space:]]*cdecl_(func|var)\(([^)]+)\)[[:space:]]*(/[/*].*)?$,\2,p' "$@" | sort -u)"
read -r -d '' -a symbols <<<"${out}" || true

if [[ ${debug} -eq 1 ]]; then
    echo "symbols: [${#symbols[@]}]"
    printf '%s\n' "${symbols[@]}"
fi

{
    # shellcheck disable=SC2059
    printf -- "${symarg}" "${symbols[@]}"
    # shellcheck disable=SC2059
    printf -- "${vsarg}" "${exports_script}"
} >"${link_args}"

if [[ ${debug} -eq 1 ]]; then
    echo "${link_args}:"
    cat "${link_args}"
fi

case "${vsfmt}" in
    blank)
        touch "${exports_script}"
        ;;
    export)
        {
            printf '_%s\n' "${symbols[@]}"
        } >"${exports_script}"
        ;;
    version)
        {
            printf '{\nglobal:\n'
            printf '  %s;\n' "${symbols[@]}"
            printf 'local: *;\n};\n'
        } >"${exports_script}"
        ;;
    *)
        echo "unsupported export script format: ${vsfmt}" 1>&2
        exit 1
        ;;
esac

if [[ ${debug} -eq 1 ]]; then
    echo "${exports_script}:"
    cat "${exports_script}"
fi

# vim: sw=4
