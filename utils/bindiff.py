#!/usr/bin/env python3

from subprocess import check_output
import os
import re
import sys

from bininfo import elfinfo, which


if os.environ.get('CLICOLOR_FORCE', '') or sys.stderr.isatty():
    ANSI_REDS = (
        '\033[48;5;52m',
        '\033[48;5;88m',
        '\033[48;5;124m',
        '\033[48;5;160m',
    )
    ANSI_GREENS = (
        '\033[48;5;22m',
        '\033[48;5;28m',
        '\033[48;5;34m',
        '\033[48;5;40m',
    )
    ANSI_RESET = '\033[0m'
else:
    ANSI_REDS = ('', '', '', '')
    ANSI_GREENS = ('', '', '', '')
    ANSI_RESET = ''


def demangle(symdict):
    cxxfilt = which('c++filt', 'llvm-cxxfilt')
    old_names = list(symdict)
    new_names = check_output((cxxfilt,), encoding='utf-8', input='\n'.join(old_names)).strip().split('\n')
    assert len(old_names) == len(new_names)
    demangled = {}
    for old, new in zip(old_names, new_names):
        assert old not in demangled
        demangled[old] = new
    return {
        new: symdict[old]._replace(name=new)
        for old, new in demangled.items()
    }

def naturalsize(size, delta=False, pad=0):
    for color, chunk, suffix, precision in (
        (1, 2**30, 'GB', 1),
        (2, 2**20, 'MB', 1),
        (3, 2**10, 'KB', 1),
    ):
        if abs(size) >= chunk:
            break
    else:
        color, chunk, suffix, precision = 0, 1, '   B', 0
    color = ANSI_REDS[color] if size >= 0 else ANSI_GREENS[color]
    fmt = '%'
    if delta:
        fmt += '+'
    fmt += '.*f %s'
    s = fmt % (precision, size / chunk, suffix)
    if pad:
        s = '%*s' % (pad, s)
    left = len(s) - len(s.lstrip()) - 1
    s = color + ' ' * left + ANSI_RESET + ' ' + s.lstrip()
    return s

def main(args):
    assert 2 <= len(args)
    old = elfinfo(args[0], full=True)
    new = elfinfo(args[1], full=True)
    old_symbols = demangle(old.symbols)
    new_symbols = demangle(new.symbols)
    if len(args) >= 3:
        for a in args[2:]:
            pattern, repl = a.split('/')
            rx = re.compile(pattern)
            old_symbols = {
                rx.sub(repl, name): sym
                for name, sym in old_symbols.items()
            }
            new_symbols = {
                rx.sub(repl, name): sym
                for name, sym in new_symbols.items()
            }
    def format_sym(s):
        return '{}  {:6} {:6} {}'.format(naturalsize(s.size, delta=True, pad=12), s.kind, s.bind, s.name)
    removed = set(old_symbols) - set(new_symbols)
    if removed:
        removed = [old_symbols[s] for s in removed]
        print('Removed:', naturalsize(-sum(s.size for s in removed), delta=True))
        print()
        for s in sorted(removed):
            print(format_sym(s._replace(size=-s.size)))
        print()
    added = set(new_symbols) - set(old_symbols)
    if added:
        added = [new_symbols[s] for s in added]
        print('Added:', naturalsize(sum(s.size for s in added), delta=True))
        print()
        for s in sorted(added):
            print(format_sym(s))
        print()
    common = set(new_symbols) & set(old_symbols)
    if common:
        old_common = [old_symbols[s] for s in common]
        new_common = [new_symbols[s] for s in common]
        old_size = sum(s.size for s in old_common)
        new_size = sum(s.size for s in new_common)
        print('In common:', naturalsize(new_size - old_size, delta=True))
        for s in sorted(common):
            old_sym = old_symbols[s]
            new_sym = new_symbols[s]
            size_delta = new_sym.size - old_sym.size
            if size_delta:
                print(format_sym(new_sym._replace(size=size_delta)))

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
