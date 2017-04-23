#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_HOME=/home/ko
source "${CI_DIR}/common.sh"

travis_retry make fetchthirdparty

if [ "$TARGET" = kobo ]; then
    chmod -R 777 $HOME/.ccache
    docker run -t \
        -v "${HOME}"/.ccache:${DOCKER_HOME}/.ccache \
        -v `pwd`:${DOCKER_HOME}/base ${DOCKER_IMG} \
        /bin/bash -c 'source /home/ko/.bashrc && cd /home/ko/base && make TARGET=kobo all'
elif [ "$TARGET" = kindle ]; then
    chmod -R 777 $HOME/.ccache
    docker run -t \
        -v "${HOME}"/.ccache:${DOCKER_HOME}/.ccache \
        -v `pwd`:${DOCKER_HOME}/base ${DOCKER_IMG} \
        /bin/bash -c 'source /home/ko/.bashrc && cd /home/ko/base && make TARGET=kindle all'
elif [ "$TARGET" = pocketbook ]; then
    chmod -R 777 $HOME/.ccache
    docker run -t \
        -v "${HOME}"/.ccache:${DOCKER_HOME}/.ccache \
        -v `pwd`:${DOCKER_HOME}/base ${DOCKER_IMG} \
        /bin/bash -c "source /home/ko/.bashrc && cd /home/ko/base && make pocketbook-toolchain && make VERBOSE=1 TARGET=pocketbook all"
else
    make all
fi
