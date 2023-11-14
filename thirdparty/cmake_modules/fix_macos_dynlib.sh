#!/bin/bash

if [[ $# -lt 1 ]]; then
    cat <<EOF
USAGE: $0 LIBRARY_DIR:LIBRARY_FILE+

Example: $0 common:build/common/ssl.so libs:build/libs/libcrypto.1.1.dylib libs:build/libs/libssl.1.1.dylib
EOF
    exit 1
fi

target_libdir="${1%%:*}"
target_libname="${1##*/}"
target_library="${1#*:}"
shift 1

for library in "$@"; do
    libdir="${library%%:*}"
    libname="${library##*/}"
    libpath="${libdir}/${libname}"
    path="$(otool -L "${target_library}" | grep "[ /]${libname} " | awk '{print $1}')"
    if [[ "${path}" != "${libpath}" ]]; then
        install_name_tool -change "${path}" "${libpath}" "${target_library}"
    fi
done

target_libid="${target_libdir}/${target_libname}"
id="$(otool -DX "${target_library}")"
if [[ "${id}" != "${target_libid}" ]]; then
    install_name_tool -id "${target_libid}" "${target_library}"
fi
