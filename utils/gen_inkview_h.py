#!/usr/bin/env python3

from collections import defaultdict
from pathlib import Path
import itertools
import sys
import textwrap


def extract_cdefs(file):
    line_iter = iter(file.read_text(encoding='utf-8').split('\n'))
    while next(line_iter) != 'ffi.cdef[[':
        pass
    cdef_list = []
    while True:
        line = next(line_iter)
        if line == ']]':
            break
        cdef = line
        if cdef.endswith('{'):
            while True:
                line = next(line_iter)
                cdef += '\n' + line
                if line.startswith('}') and line.endswith(';'):
                    break
        cdef_list.append(cdef)
    return cdef_list

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
    assert len(args) >= 4
    output_file = Path(args.pop(0))
    input_dir = Path(args.pop(0))
    assert input_dir.is_dir()
    all_versions = sorted(set(args))
    # Parse all cdefs.
    cdef_versions = defaultdict(set)
    version_cdefs = {}
    for version in all_versions:
        cdef_list = []
        for cdef in extract_cdefs(input_dir / f'inkview_h_{version}.lua'):
            cdef_versions[cdef].add(version)
            cdef_list.append(cdef)
        version_cdefs[version] = cdef_list
    common_cdefs = [
        cdef
        for cdef, versions in cdef_versions.items()
        if len(versions) == len(all_versions)
    ]
    version_cdefs_iter = [iter(version_cdefs[version]) for version in all_versions]
    # Order and merge cdefs.
    common_cdefs.append(None)
    output_cdefs = []
    for cdef in common_cdefs:
        specific_cdefs_list = [[] for version in all_versions]
        for version, cdefs_iter, cdef_list in zip(all_versions, version_cdefs_iter, specific_cdefs_list):
            for next_cdef in cdefs_iter:
                if next_cdef == cdef:
                    break
                for version_set, other_cdef in reversed(list(itertools.chain(*specific_cdefs_list))):
                    if next_cdef == other_cdef:
                        version_set.add(version)
                        break
                else:
                    cdef_list.append(({version}, next_cdef))
        output_cdefs.extend(itertools.chain(*specific_cdefs_list))
        if cdef is not None:
            output_cdefs.append((set(), cdef))
    # Generate output, grouping cdefs by target version(s)..
    output = [textwrap.dedent('''\
        -- Automatically generated with {0}.

        local ffi = require("ffi")
        local C = ffi.C

        local target_version
        for __, version in ipairs{{ {1} }} do
            if C.POCKETBOOK_VERSION >= version then
                target_version = version
            end
        end
        if not target_version then
            error("unsupported PocketBook software version: " .. tonumber(C.POCKETBOOK_VERSION))
        end
        print("target PocketBook software version: " ..  target_version)

        require "ffi/posix_h"
        '''.format(
            sys.argv[0],
            ', '.join(map(str, all_versions)),
        )
     )]
    for version_set, group in itertools.groupby(output_cdefs, key=lambda i:i[0]):
        cdef_list = list(i[1] for i in group)
        output.append('\n')
        if version_set:
            test_list = []
            for version_list in consecutive_version_ranges(version_set, all_versions):
                if len(version_list) == 1:
                    version = version_list[0]
                    test_list.append(f'target_version == {version}')
                else:
                    min_version = min(*version_list)
                    max_version = max(*version_list)
                    test_list.append(f'{min_version} <= target_version and target_version <= {max_version}')
            output.extend(('if ', ' or '.join(test_list), ' then\n'))
        if len(cdef_list) > 1 or '\n' in cdef_list[0]:
            separator = '\n'
        else:
            separator = ' '
        output.extend(('ffi.cdef[[', separator))
        for cdef in cdef_list:
            output.extend((cdef, separator))
        output.append(']]\n')
        if version_set:
            output.append('end\n')
    # Save output.
    output_file.write_text(''.join(output), encoding='utf-8')


if __name__ == '__main__':
    main()
