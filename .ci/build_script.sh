#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_HOME=/home/ko
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

test -d "${HOME}/.ccache" || mkdir "${HOME}/.ccache"
echo "using cache dir: ${HOME}/.ccache."

PROCS="$(getconf _NPROCESSORS_ONLN)"
if [[ -r /sys/fs/cgroup/cpu/cpu.shares ]]; then
    CG_PROCS=$(($(cat /sys/fs/cgroup/cpu/cpu.shares) / 1024))
    echo "running under cgroups, allocated vs physical cores: ${CG_PROCS} / ${PROCS}"
    PARALLEL_JOBS=$((CG_PROCS * 2))
    PARALLEL_LOAD="${PROCS}"
else
    PARALLEL_JOBS=$((PROCS * 2))
    PARALLEL_LOAD="${PROCS}"
fi
echo "PARALLEL_JOBS: ${PARALLEL_JOBS}"
echo "PARALLEL_LOAD: ${PARALLEL_LOAD}"

travis_retry make fetchthirdparty PARALLEL_JOBS=1 PARALLEL_LOAD=1 TARGET=

docker-make() {
    travis_retry make fetch-cmake PARALLEL_JOBS=1 PARALLEL_LOAD=1 TARGET=
    local cmdlist=(
        'source /home/ko/.bashrc'
        'cd /home/ko/base'
        'sudo chown -R ko:ko .'
        'ccache -sz'
        "trap 'ccache -s' EXIT"
        "make CMAKE=cmake/bin/cmake $(printf '%q ' "$@")"
    )
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run --rm -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "$(printf '%s && ' "${cmdlist[@]}")true"
}

makeargs=(
    # -j/-l for the outer invocation, and PARALLEL_LOAD/PARALLEL_LOAD
    # set too to prevent values from being overriden on older make
    # versions who don't advertise -j/-l in MAKEFLAGS.
    "-j${PARALLEL_JOBS}" PARALLEL_JOBS="${PARALLEL_JOBS}"
    "-l${PARALLEL_LOAD}" PARALLEL_LOAD="${PARALLEL_LOAD}"
    TARGET="${TARGET}"
)
if [[ -z "${DOCKER_IMG}" ]]; then
    ccache -sz
    trap 'ccache -s' EXIT
    make "${makeargs[@]}" "$@"
else
    VERBOSE=
    case "${TARGET}" in
    'pocketbook') VERBOSE=1 ;;
    'sony-prstux') VERBOSE=1 ;;
    esac
    docker-make "${makeargs[@]}" VERBOSE="${VERBOSE}" "$@"
fi
