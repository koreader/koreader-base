project('koreader-testrunner', version: '0.1')

kodir = get_option('prefix')
testdir = 'spec'

fs = import('fs')

bash = find_program('bash')
find = find_program('find')
sort = find_program('sort')
luajit = find_program(kodir / 'luajit')

_testroot = kodir / testdir
foreach _testpath : run_command(
  bash, '-o', 'pipefail', '-c',
  '"$1" -L "$2" -type f "(" -name "*_bench.lua" -o -name "*_spec.lua" ")" | "$3"',
  '--', find, _testroot, sort,
  check: true,
).stdout().strip('\n').split('\n')
  assert(_testpath.startswith(_testroot))
  # Fugly, but no `str.length()`…
  _testpath = _testpath.replace(_testroot + '/', '')
  _parts = _testpath.split('/')
  _suite = _parts[0]
  assert(_suite != '')
  _is_bench = _parts[-1].endswith('_bench.lua')
  if _is_bench
    _test = _parts[-1].substring(0, -10)
    # message('benchmark:', _suite, _test)
  else
    _test = _parts[-1].substring(0, -9)
    _id = _suite / _test
    # message('test:', _suite, _test)
  endif
  _args = [
    '-e', 'require "busted.runner" {standalone = false}', '/dev/null',
    '--output=gtest', '-Xoutput=--color',
    '--run=' + _suite,
    testdir / _testpath,
  ]
  _env = environment()
  _env.set('KO_HOME', meson.current_build_dir() / '_'.join(_suite, _test))
  # Don't fail the testsuite on ASAN detected leaks.
  _env.prepend('LSAN_OPTIONS', 'exitcode=0', separator: ' ')
  if _is_bench
    benchmark(
      _test,
      luajit,
      args: _args,
      env: _env,
      protocol: 'exitcode',
      suite: _suite,
      timeout: 0,
      workdir: fs.parent(luajit.full_path()),
    )
  else
    test(
      _test,
      luajit,
      args: _args,
      env: _env,
      protocol: 'exitcode',
      suite: _suite,
      timeout: 5 * 60,
      workdir: fs.parent(luajit.full_path()),
    )
  endif
endforeach
