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

docker-make() {
    local cmdlist=(
        'source /home/ko/.bashrc'
        'cd /home/ko/base'
        'sudo chown -R ko:ko .'
        "env MAKEFLAGS='${MAKEFLAGS}' make $(printf '%q ' "$@")"
    )
    sudo chmod -R 777 "${CCACHE_DIR}"
    docker run --rm -t \
        -v "${CCACHE_DIR}:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "$(printf '%s && ' "${cmdlist[@]}")true"
}

if [[ -z "${DOCKER_IMG}" ]]; then
    make TARGET="${TARGET}" "$@"
else
    docker-make TARGET="${TARGET}" VERBOSE=1 "$@"
fi
