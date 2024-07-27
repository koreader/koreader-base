#!/usr/bin/env python3

import os
import platform
import sys


def iself(path):
    with open(path, 'rb') as fp:
        return fp.read(4) == b'\x7FELF'

def ismacho(path):
    if path.endswith('.tbd'):
        return True
    with open(path, 'rb') as fp:
        # NOTE: check for 64-bits little endian binaries only.
        return fp.read(4) in b'\xcf\xfa\xed\xfe'

def any_darwin_bin(paths):
    return any(
        p.endswith('.dylib') or p.endswith('.tbd')
        or (os.path.isfile(p) and ismacho(p))
        for p in paths
    )

def binfind(pathlist, darwin=None):
    if darwin is None:
        darwin = platform.system() == 'Darwin'
    isbin = ismacho if darwin else iself
    for path in pathlist:
        if not os.path.isdir(path):
            assert os.path.isfile(path), path
            if isbin(path):
                yield path
        for dirpath, _dirnames, filenames in os.walk(path):
            for entry in filenames:
                entry = os.path.join(dirpath, entry)
                if os.access(entry, os.X_OK) and isbin(entry):
                    yield entry


def main(args, darwin=None):
    if darwin is None:
        darwin = platform.system() == 'Darwin' or any_darwin_bin(args)
    print('\n'.join(sorted(binfind(args, darwin=darwin))))

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
