#!/bin/sh

set -e

if [ $# -eq 0 ]; then
    echo "Patch file(s) required as argument(s)."
    exit 1
fi

for patch in "$@"; do
    echo "* Applying ${patch} . . ."
    # Reverse patch will succeed if the patch is already applied.
    # In case of failure, it means we should try to apply the patch.
    if ! patch -R -p1 -N --dry-run --input="${patch}" >/dev/null 2>&1; then
        # Now patch for real.
        patch -p1 -N --input="${patch}"
    fi
done
