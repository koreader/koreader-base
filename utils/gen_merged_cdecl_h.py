#!/usr/bin/env python3

from collections import defaultdict
from pathlib import Path
import itertools
import re
import sys


CDECL_MARKER_RX = re.compile(r'// cdecl_(\w+)')


def extract_cdefs(file):
    line_iter = iter(file.read_text(encoding='utf-8').split('\n'))
    while next(line_iter) != 'require("ffi").cdef[[':
        pass
    cdef_dict = defaultdict(list)
    tag = None
    line_number = 0
    while True:
        line = next(line_iter)
        line_number += 1
        if line == ']]':
            break
        m = CDECL_MARKER_RX.fullmatch(line)
        if m is not None:
            tag = m.group(1)
            continue
        if tag is None:
            raise ValueError(f'unmarked cdecl, starting line {line_number}: {line}')
        cdef_dict[tag].append(line)
    return { t: '\n'.join(c) for t, c in cdef_dict.items() }

def consecutive_version_ranges(version_set, all_versions):
    range_list = []
    for version in all_versions:
        if version in version_set:
            range_list.append(version)
        elif range_list:
            yield range_list
            range_list = []
    if range_list:
        yield range_list


def main():
    # Check arguments.
    args = sys.argv[1:]
    assert len(args) >= 6
    output_file = Path(args.pop(0))
    prolog_file = Path(args.pop(0))
    target_variable = args.pop(0)
    input_dir = Path(args.pop(0))
    assert input_dir.is_dir()
    all_versions = sorted(set(args))
    int_versions = all(v.isdigit() for v in all_versions)
    if not int_versions:
        all_versions = { v: 1 << n for n, v in enumerate(all_versions) }
    # Parse all cdefs.
    stem = Path(output_file).stem
    version_cdefs = {
        v: extract_cdefs(input_dir / f'{stem}_{v}.lua')
        for v in all_versions
    }
    # Order and merge cdefs.
    taglist = []
    for version, cdef_dict in version_cdefs.items():
        position = 0
        for tag in cdef_dict:
            try:
                position = taglist.index(tag, position)
            except ValueError:
                taglist.insert(position, tag)
            position += 1
    taglist = [(tag, defaultdict(set)) for tag in taglist]
    for tag, tag_cdef_dict in taglist:
        for version, cdef_dict in version_cdefs.items():
            try:
                cdef = cdef_dict[tag]
            except KeyError:
                continue
            tag_cdef_dict[cdef].add(version)
    # Generate prolog.
    prolog = Path(prolog_file).read_text(encoding='utf-8')
    format_args = [sys.argv[0]]
    if int_versions:
        format_args.append(', '.join(map(str, all_versions)))
    else:
        format_args.append(', '.join(f'{v}={i:#x}' for v, i in all_versions.items()))
    output = [prolog.format(*format_args)]
    # Generate cdefs blocks.
    for version_set_list, group in itertools.groupby(taglist, key=lambda i: list(i[1].values())):
        group = tuple(group)
        need_end = False
        output.append('\n')
        for n, version_set in enumerate(version_set_list):
            block = len(version_set) != len(all_versions)
            if block:
                test_list = []
                if_comment = None
                if int_versions:
                    for version_list in consecutive_version_ranges(version_set, all_versions):
                        if len(version_list) == 1:
                            version = version_list[0]
                            test_list.append(f'{target_variable} == {version}')
                        else:
                            min_version = min(*version_list)
                            max_version = max(*version_list)
                            test_list.append(f'{min_version} <= {target_variable} and {target_variable} <= {max_version}')
                else:
                    version_list = sorted(version_set)
                    if_comment = '|'.join(version_list)
                    value = sum(all_versions[v] for v in version_set)
                    if len(version_list) == 1:
                        test_list.append(f'{target_variable} == {value:#x}')
                    else:
                        test_list.append(f'bit.band({target_variable}, {value:#x}) ~= 0')
                output.append('if' if n == 0 else 'elseif')
                if if_comment:
                    output.append(f' --[[ {if_comment} ]]')
                output.extend((' ', ' or '.join(test_list), ' then\n'))
                need_end = True
            cdef_list = [
                cdef
                for __, cdef_dict in group
                for cdef, cdef_version_set in cdef_dict.items()
                if cdef_version_set == version_set
            ]
            if len(cdef_list) > 1 or '\n' in cdef_list[0]:
                separator = '\n'
            else:
                separator = ' '
            output.extend(('ffi.cdef[[', separator))
            for cdef in cdef_list:
                output.extend((cdef, separator))
            output.append(']]\n')
        if need_end:
            output.append('end\n')
    # Save output.
    output_file.write_text(''.join(output), encoding='utf-8')


if __name__ == '__main__':
    main()
