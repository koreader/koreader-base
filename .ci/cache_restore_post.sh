#!/bin/sh

set -ex

which ccache
ccache --version
ccache --zero-stats
ccache -p # `-p`: equivalent to `--show-config` (not supported with ancient versions)
