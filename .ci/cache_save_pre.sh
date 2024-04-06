#!/bin/sh

set -ex

ccache --cleanup >/dev/null
ccache --show-stats
