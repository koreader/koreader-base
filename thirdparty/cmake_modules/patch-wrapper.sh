#!/bin/sh

if [ $# -eq 0 ]; then
    echo "Patch file required as argument."
    exit 1
fi

PATCH_FILE="$1"
echo "* Applying ${PATCH_FILE} . . ."

# Reverse patch will succeed if the patch is already applied.
# In case of failure, it means we should try to apply the patch.
if ! patch -R -p1 -N --dry-run <"${PATCH_FILE}" >/dev/null 2>&1; then
    # Now patch for real.
    patch -p1 -N <"${PATCH_FILE}"
    exit $?
fi
