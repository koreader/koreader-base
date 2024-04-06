#!/bin/sh

set -ex

which ccache
ccache --version
ccache --zero-stats
# TODO: reduce once a more recent version of ccache with
# zstd support and compression enabled by default is used.
ccache --max-size=1G
ccache -p # `-p`: equivalent to `--show-config` (not supported with ancient versions)
