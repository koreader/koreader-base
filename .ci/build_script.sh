#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

docker-make() {
    local cmdlist=(
        'source /home/ko/.bashrc'
        'cd /home/ko/base'
        'sudo chown -R ko:ko .'
        "env MAKEFLAGS='${MAKEFLAGS}' make $(printf '%q ' "$@")"
    )
    if [[ -z "${CCACHE_DIR}" ]]; then
        CCACHE_DIR="$(ccache --get-config cache_dir)"
    fi
    mkdir -p "${CCACHE_DIR}"
    echo "using host cache dir: ${CCACHE_DIR}"
    sudo chmod -R 777 "${CCACHE_DIR}"
    DOCKER_HOME=/home/ko
    DOCKER_CCACHE_DIR="${DOCKER_HOME}/.cache/ccache"
    echo "using docker cache dir: ${DOCKER_CCACHE_DIR}"
    docker run --rm -t \
        -e CCACHE_DIR="${DOCKER_CCACHE_DIR}" \
        -v "${CCACHE_DIR}:${DOCKER_CCACHE_DIR}" \
        -v "${PWD}:${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "$(printf '%s && ' "${cmdlist[@]}")true"
}

if [[ -z "${DOCKER_IMG}" ]]; then
    make TARGET="${TARGET}" "$@"
else
    docker-make TARGET="${TARGET}" VERBOSE=1 "$@"
fi

# vim: sw=4
