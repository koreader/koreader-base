#!/usr/bin/env python3

import dataclasses
import itertools
import functools
import os
import platform
import shutil
import subprocess
import sys

from binfind import any_darwin_bin, binfind


if os.environ.get('CLICOLOR_FORCE', '') or sys.stderr.isatty():
    ANSI_STATUS = '\033[32;1m'
    ANSI_RESET = '\033[0m'
else:
    ANSI_STATUS = ''
    ANSI_RESET = ''


@functools.lru_cache
def which(*names):
    assert names
    for candidate in names:
        exe = shutil.which(candidate)
        if exe is not None:
            return exe
    raise FileNotFoundError(names[0])


@dataclasses.dataclass
class LibraryInfo:
    soname    : str  = None
    needed    : list = dataclasses.field(default_factory=list)
    rpath     : str  = None
    runpath   : str  = None
    provides  : list = dataclasses.field(default_factory=set)
    unresolved: list = dataclasses.field(default_factory=set)
    upneeded  : list = dataclasses.field(default_factory=list)
    reexport  : list = dataclasses.field(default_factory=list)


def elfinfo(library, readelf=None):
    output = iter(subprocess.check_output((
        readelf or which('readelf', 'llvm-readelf'),
        '--dyn-syms', '--dynamic', '--wide', library,
    )).decode().strip().splitlines())
    def skip_until(prefix):
        for line in output:
            if line.startswith(prefix):
                return
    # Dynamic section at offset 0x4b7b60 contains 33 entries:
    #   Tag        Type                         Name/Value
    # 0x0000000000000001 (NEEDED)             Shared library: [libfreetype.so.6]
    # 0x000000000000000e (SONAME)             Library soname: [libwrap-mupdf.so]
    # 0x000000000000000f (RPATH)              Library rpath: [$ORIGIN:$ORIGIN/libs]
    # 0x000000000000000c (INIT)               0x4b000
    # 0x000000000000000d (FINI)               0x29e154
    # 0x0000000000000019 (INIT_ARRAY)         0x4a5e10
    skip_until('Dynamic section ')
    # Skip headers.
    next(output)
    info = LibraryInfo()
    for line in itertools.takewhile(bool, output): # stop at first empty line
        fields = line.split(None, 2)
        if not fields[1].startswith('(') or not fields[1].endswith(')'):
            continue
        kind = fields[1][1:-1].lower()
        if not kind in {'needed', 'rpath', 'runpath', 'soname'}:
            continue
        value = fields[2]
        if kind in {'needed', 'rpath', 'soname'}:
            value = value.split(': [', 1)
            assert len(value) == 2 and value[1].endswith(']'), value
            value = value[1][:-1]
        if kind == 'needed':
            getattr(info, kind).append(value)
        else:
            assert getattr(info, kind) is None, (kind, info)
            setattr(info, kind, value)
    # Symbol table '.dynsym' contains 282 entries:
    #    Num:    Value          Size Type    Bind   Vis      Ndx Name
    #      0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND
    #      1: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND log10@GLIBC_2.2.5 (2)
    #      4: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND FT_Set_Transform
    skip_until('Symbol table \'.dynsym\'')
    # Skip headers.
    next(output)
    for line in itertools.takewhile(bool, output): # stop at first empty line
        fields = line.split()
        assert 7 <= len(fields) <= 9, fields
        if len(fields) == 7:
            continue
        bind, _, ndx, name = fields[4:8]
        if bind == 'LOCAL':
            continue
        if ndx == 'UND':
            if bind == 'WEAK':
                continue
            info.unresolved.add(name)
        else:
            info.provides.add(name)
    # Handle versioned default symbols.
    for name, version in  tuple(
        s.split('@@', 1) for s in info.provides if '@@' in s
    ):
        for sym in (name, name + '@' + version):
            assert sym not in info.provides, sym
            info.provides.add(sym)
    return info

def machoinfo(library, nm=None, otool=None):
    if library.endswith('.tbd'):
        return tbdinfo(library)
    # […]
    # Section
    #   sectname __text
    #    segname __TEXT
    #       addr 0x0000000000005104
    #       size 0x00000000001e57b8
    #     offset 20740
    #      align 2^2 (4)
    #     reloff 0
    #     nreloc 0
    #      flags 0x80000400
    #  reserved1 0
    #  reserved2 0
    # […]
    # Load command 4
    #           cmd LC_ID_DYLIB
    #       cmdsize 48
    #          name @rpath/libwrap-mupdf.so (offset 24)
    #    time stamp 1 Thu Jan  1 01:00:01 1970
    #       current version 0.0.0
    # compatibility version 0.0.0
    # […]
    # Load command 11
    #           cmd LC_LOAD_DYLIB
    #       cmdsize 56
    #          name @rpath/libfreetype.6.dylib (offset 24)
    #    time stamp 2 Thu Jan  1 01:00:02 1970
    #       current version 6.20.1
    # compatibility version 6.0.0
    # […]
    load_command = None
    load_command_list = []
    for line in subprocess.check_output((
        otool or which('llvm-otool', 'otool'),
        '-lX', library,
    )).decode().strip().splitlines():
        if line.startswith('Load command'):
            load_command = {}
            load_command_list.append(load_command)
            continue
        if line.startswith('Mach') or line.startswith('Section'):
            load_command = None
            continue
        if load_command is None:
            continue
        key, val = line.split(None, 1)
        load_command[key] = val
    info = LibraryInfo()
    for load_command in load_command_list:
        key = {
            'LC_ID_DYLIB'         : 'soname',
            'LC_RPATH'            : 'rpath',
            'LC_LOAD_DYLIB'       : 'needed',
            'LC_LOAD_WEAK_DYLIB'  : 'needed',
            # Yes, it's a thing, dependency cycles…
            'LC_LOAD_UPWARD_DYLIB': 'upneeded',
            # Export symbols from this lib too.
            'LC_REEXPORT_DYLIB'   : 'reexport',
        }.get(load_command['cmd'])
        if key is None:
            continue
        if key == 'rpath':
            val = load_command['path']
        else:
            val = load_command['name']
        val = val.rsplit('(', 1)[0].strip()
        if key == 'soname':
            assert info.soname is None, (val, info)
            info.soname = val
        elif key == 'rpath':
            info.rpath = ':'.join(filter(None, (info.rpath, val)))
        else:
            getattr(info, key).append(val)
    for line in subprocess.check_output((
        nm or which('llvm-nm', 'nm'),
        '-P', library,
    )).decode().strip().splitlines():
        fields = line.split()
        sym, kind = fields[:2]
        if kind == 'U':
            info.unresolved.add(sym)
        elif kind in 'ABCDIST':
            info.provides.add(sym)
    return info

def tbdinfo(path):
    # pylint: disable=import-outside-toplevel
    from ruamel.yaml import YAML
    yaml = YAML(typ='safe')
    yaml.Constructor.add_constructor('!tapi-tbd', yaml.Constructor.construct_mapping)
    info = LibraryInfo()
    # FIXME: honor `targets`.
    with open(path, 'rb') as fp:
        for n, tbd in enumerate(yaml.load_all(fp)):
            if 'install-name' in tbd:
                if n == 0:
                    info.soname = tbd['install-name']
                else:
                    info.reexport.append(tbd['install-name'])
            for exports in tbd.get('exports', []) + tbd.get('reexports', []):
                info.provides.update(exports.get('weak-symbols', ()))
                info.provides.update(exports.get('symbols', ()))
                info.provides.update('_OBJC_EHTYPE_$_' + s for s in exports.get('objc-eh-types', ()))
                for klass in exports.get('objc-classes', ()):
                    info.provides.add('_OBJC_CLASS_$_' + klass)
                    info.provides.add('_OBJC_METACLASS_$_' + klass)
    return info

def dumpinfo(info):
    if info.soname is not None:
        print('  SONAME    :', info.soname)
    if info.rpath is not None:
        print('  RPATH     :', info.rpath)
    if info.runpath is not None:
        print('  RUNPATH   :', info.runpath)
    for need in info.needed:
        print('  NEEDED    :', need)
    for export in info.upneeded:
        print('  UPNEEDED  :', export)
    for export in info.reexport:
        print('  REEXPORT  :', export)


def main(args, darwin=None):
    if darwin is None:
        darwin = platform.system() == 'Darwin' or any_darwin_bin(args)
    bininfo = machoinfo if darwin else elfinfo
    for binary in sorted(binfind(args, darwin=darwin)):
        print(''.join((ANSI_STATUS, binary, ANSI_RESET, ':')))
        dumpinfo(bininfo(binary))

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
