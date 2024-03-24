#!/bin/sh

set -e

if [ -r "$1" ]; then
    touch "$1"
    exit
fi

{
    printf "%s:" "$2"
    exec find "$3" \
        -type d -path '*/.*' -prune -o \
        -type f -not -name '.*' -not -path '*[ 	:~()=;]*' -print0 |
        xargs -0 printf ' %s'
} >"$1"

# vim: sw=4
