#!/usr/bin/env python3

import os, pty, sys

os.environ['TERM'] = 'xterm-256color'
status = pty.spawn(sys.argv[1:])
if os.WIFEXITED(status):
    exit(os.WEXITSTATUS(status))
if os.WIFSIGNALED(status):
    exit(-os.WTERMSIG(status))
raise ValueError(status)
