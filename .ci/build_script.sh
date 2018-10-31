#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_HOME=/home/ko
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

travis_retry make fetchthirdparty

if [ "$TARGET" = "kobo" ]; then
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c 'source /home/ko/.bashrc && cd /home/ko/base && sudo chown -R ko:ko . && make TARGET=kobo all'
elif [ "$TARGET" = "kindle" ]; then
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c 'source /home/ko/.bashrc && cd /home/ko/base && sudo chown -R ko:ko . && make TARGET=kindle all'
elif [ "$TARGET" = "pocketbook" ]; then
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "source /home/ko/.bashrc && cd /home/ko/base && sudo chown -R ko:ko . && make pocketbook-toolchain && make VERBOSE=1 TARGET=pocketbook all"
elif [ "$TARGET" = "sony-prstux" ]; then
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c "source /home/ko/.bashrc && cd /home/ko/base && sudo chown -R ko:ko . && make VERBOSE=1 TARGET=sony-prstux all"
elif [ "$TARGET" = "cervantes" ]; then
    sudo chmod -R 777 "${HOME}/.ccache"
    docker run -t \
        -v "${HOME}/.ccache:${DOCKER_HOME}/.ccache" \
        -v "$(pwd):${DOCKER_HOME}/base" "${DOCKER_IMG}" \
        /bin/bash -c 'source /home/ko/.bashrc && cd /home/ko/base && sudo chown -R ko:ko . && make TARGET=cervantes all'
else
    make all
fi
