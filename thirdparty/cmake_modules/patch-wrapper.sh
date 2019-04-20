#!/bin/sh

# Depends on input from stdin

patch -p1 -N

exit_status=$?

if [ $exit_status -eq 0 ]; then
    # Patch applied successfully
    exit 0
elif [ $exit_status -eq 1 ]; then
    echo "Previously applied patch, ignoring."
    exit 0
fi

exit $?
