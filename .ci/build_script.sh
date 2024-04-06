#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_HOME=/home/ko
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

test -d "${HOME}/.ccache" || mkdir "${HOME}/.ccache"
echo "using cache dir: ${HOME}/.ccache."

travis_retry make fetchthirdparty TARGET=

docker-make() {
    local cmdlist=(
        'source /home/ko/.bashrc'
        'cd /home/ko/base'
        'sudo chown -R ko:ko .'
        "make $(printf '%q ' "$@")"
    )
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run --rm -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "$(printf '%s && ' "${cmdlist[@]}")true"
}

makeargs=(
    TARGET="${TARGET}"
)
if [[ -z "${DOCKER_IMG}" ]]; then
    make "${makeargs[@]}" "$@"
else
    docker-make "${makeargs[@]}" VERBOSE=1 "$@"
fi
