#!/usr/bin/env python3

from io import StringIO
import contextlib
import functools
import itertools
import os
import platform
import re
import sys
import textwrap

from binfind import any_darwin_bin, binfind
from bininfo import elfinfo, machoinfo, dumpinfo


if os.environ.get('CLICOLOR_FORCE', '') or sys.stderr.isatty():
    ANSI_CODE = {
        'error' : '\033[31;1m',
        'header': '\033[32;1m',
        'ko'    : '\33[31m',
        'notice': '\033[34;1m',
        'ok'    : '\33[32m',
        'reset' : '\033[0m',
    }
else:
    ANSI_CODE = {
        'error' : '',
        'header': '',
        'ko'    : '',
        'notice': '',
        'ok'    : '',
        'reset' : '',
    }

def colored(color, s):
    return ''.join((ANSI_CODE[color], s, ANSI_CODE['reset']))

def first_letter(s):
    return re.match(r'_*.?', s).group()

def wrap(s, indent=0, width=60):
    indent = ' ' * indent
    return '\n'.join(textwrap.TextWrapper(
        break_long_words=False, break_on_hyphens=False,
        initial_indent=indent, subsequent_indent=indent,
        width=width,
    ).wrap(s))


class BinCheck:

    def __init__(self, darwin=None, ld_path=(), tbd_dir=None, glibc_version_max=None):
        if darwin is None:
            darwin = platform.system() == 'Darwin'
        self.darwin = darwin
        self.ld_path = ld_path
        self.preloaded = set()
        self.loaded = {}
        self.errors = 0
        if self.darwin:
            if tbd_dir is None:
                if platform.system() != 'Darwin':
                    tbd_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), 'bincheck/darwin'))
                else:
                    tbd_dir = '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk'
            self.tbd_dir = tbd_dir
            self.library_info = functools.lru_cache(machoinfo)
            assert glibc_version_max is None
            self.glibc_version_max = None
        else:
            self.tbd_dir = None
            self.library_info = functools.lru_cache(elfinfo)
            self.glibc_version_max = glibc_version_max

    def find_library(self, path):
        if self.darwin and path.startswith('@rpath/'):
            path = path[7:]
        if '/' in path:
            assert os.path.isabs(path), path
            if os.path.exists(path):
                return path
            if self.darwin:
                # *sigh*:
                # > New in macOS Big Sur 11.0.1, the system ships with a built-in
                # > dynamic linker cache of all system-provided libraries. As part of
                # > this change, copies of dynamic libraries are no longer present on
                # > the filesystem. Code that attempts to check for dynamic library
                # > presence by looking for a file at a path or enumerating a
                # > directory will fail. Instead, check for library presence by
                # > attempting to dlopen() the path, which will correctly check for
                # > the library in the cache. (62986286)
                tbd_path = os.path.join(self.tbd_dir, os.path.splitext(path)[0][1:] + '.tbd')
                if os.path.exists(tbd_path):
                    return tbd_path
            raise FileNotFoundError(path)
        if '$' in path:
            # Not supported for now.
            raise ValueError(path)
        for entry in self.ld_path:
            if '$' in entry:
                # Not supported for now.
                raise ValueError(entry)
            entry = os.path.join(entry, path)
            if os.path.exists(entry):
                return entry
        raise FileNotFoundError(path)

    def preload(self, library):
        self.preloaded.update(self.load_library(library))

    @functools.lru_cache
    def load_library(self, library):
        try:
            path = self.find_library(library)
        except FileNotFoundError:
            self.errors += 1
            print(colored('notice', library))
            print(colored('error', '  MISSING'))
            return set()
        path = os.path.realpath(path)
        if path in self.loaded:
            return self.loaded[path]
        info = self.library_info(path)
        if self.glibc_version_max is not None and (info.soname or '').startswith('libc.so'):
            provides = set()
            for s in info.provides:
                m = re.search(r'@GLIBC_(\d+\.\d+)$', s)
                if m is None or tuple(map(int, m.group(1).split('.'))) <= self.glibc_version_max:
                    provides.add(s)
            info.provides = provides
        self.loaded[path] = provides = set(info.provides)
        if not path.endswith('.tbd'):
            for exp in info.reexport:
                provides.update(self.load_library(exp))
        unresolved = info.unresolved - self.preloaded
        for need in info.needed:
            unresolved -= self.load_library(need)
        for need in info.upneeded:
            unresolved -= self.load_library(need)
        print(colored('notice', library))
        if library != path:
            print('  FILE      :', path)
        dumpinfo(info)
        if unresolved:
            print(colored('error', '  UNRESOLVED') + ':')
            for _key, group in itertools.groupby(sorted(unresolved), first_letter):
                print(wrap('  '.join(group), indent=4))
            self.errors += 1
        return provides

    def reset(self):
        self.errors = 0
        self.loaded.clear()
        self.load_library.cache_clear()

    def load(self, path, preload=()):
        self.reset()
        for p in preload:
            self.preload(os.path.abspath(p))
        self.load_library(os.path.abspath(path))


def main(args, darwin=None, debug=None):
    if darwin is None:
        darwin = any_darwin_bin(args) or None
    if debug is None:
        debug = 'pdb' in sys.modules
    assert len(args) >= 2
    glibc_version_max = None
    while args and args[0].startswith('-'):
        opt = args.pop(0)
        if opt == '--glibc-version-max':
            glibc_version_max = tuple(map(int, args.pop(0).split('.')))
        else:
            raise ValueError(opt)
    ld_path = []
    preload = []
    for path in args.pop(0).split(':'):
        (preload if os.path.isfile(path) else ld_path).append(path)
    bincheck = BinCheck(ld_path=ld_path, darwin=darwin, glibc_version_max=glibc_version_max)
    exit_code = 0
    for binary in sorted(binfind(args, darwin=darwin)):
        traces = StringIO()
        print(colored('header', binary) + ': ', end='')
        if debug:
            print()
            bincheck.load(binary, preload=preload)
        else:
            sys.stdout.flush()
            with contextlib.redirect_stdout(traces), contextlib.redirect_stderr(traces):
                bincheck.load(binary, preload=preload)
        ok = bincheck.errors == 0
        if ok:
            print(colored('ok', 'OK'))
        else:
            print(colored('ko', 'KO'))
        if not ok:
            exit_code = 1
            traces = traces.getvalue().strip()
            if traces:
                print(traces)
    return exit_code

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
