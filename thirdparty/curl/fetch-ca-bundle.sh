#!/bin/sh

output="$1"
outdir="$(dirname "${output}")"

mkdir -p "${outdir}" && curl \
    --etag-compare "${output}.etag" \
    --etag-save "${output}.etag" \
    --output "${output}" \
    --retry 3 \
    https://curl.se/ca/cacert.pem
code=$?

if [ ${code} -ne 0 ]; then
    if [ -r "${output}" ]; then
        code=0
        severity=WARNING
    else
        severity=ERROR
    fi
    printf '\033[31;1m%s:\033[0m failed to fetch “%s”\n' "${severity}" "${output}" 1>&2
fi

exit ${code}

# vim: sw=4
