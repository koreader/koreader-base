#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_HOME=/home/ko
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

if [[ -z "${CCACHE_DIR}" ]]; then
    CCACHE_DIR="${HOME}/.ccache"
fi

mkdir -p "${CCACHE_DIR}"
echo "using cache dir: ${CCACHE_DIR}"

PROCS="$(getconf _NPROCESSORS_ONLN)"
if [[ -r /sys/fs/cgroup/cpu/cpu.shares ]]; then
    CG_PROCS=$(($(cat /sys/fs/cgroup/cpu/cpu.shares) / 1024))
    echo "running under cgroups, allocated vs physical cores: ${CG_PROCS} / ${PROCS}"
    PARALLEL_JOBS=$((CG_PROCS + (CG_PROCS + 1) / 2))
    PARALLEL_LOAD="${PROCS}"
else
    PARALLEL_JOBS=$((PROCS + (PROCS + 1) / 2))
    PARALLEL_LOAD="${PROCS}"
fi
echo "PARALLEL_JOBS: ${PARALLEL_JOBS}"
echo "PARALLEL_LOAD: ${PARALLEL_LOAD}"

travis_retry make fetchthirdparty TARGET=

docker-make() {
    # shellcheck disable=SC2016
    local cmdlist=(
        'source /home/ko/.bashrc'
        'cd /home/ko/base'
        'set -x'
        'sudo apt-get -qq update'
        'sudo apt-get -qq install --no-install-recommends chrpath python3-minimal python3-pip'
        'python3 -m pip install meson'
        'export PATH="$HOME/.local/bin:$PATH"'
        'sudo chown -R ko:ko .'
        'ccache -sz'
        "trap 'ccache -s' EXIT"
        "make $(printf '%q ' "$@")"
    )
    sudo chmod -R 777 "${CCACHE_DIR}"
    docker run --rm -t \
        -v "${CCACHE_DIR}:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "$(printf '%s && ' "${cmdlist[@]}")true"
}

makeargs=(
    PARALLEL_JOBS="${PARALLEL_JOBS}"
    PARALLEL_LOAD="${PARALLEL_LOAD}"
    TARGET="${TARGET}"
)
if [[ -z "${DOCKER_IMG}" ]]; then
    ccache -sz
    trap 'ccache -s' EXIT
    make "${makeargs[@]}" "$@"
else
    docker-make "${makeargs[@]}" VERBOSE=1 "$@"
fi
