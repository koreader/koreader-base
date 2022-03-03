#!/usr/bin/env bash

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${CI_DIR}/common.sh"

if [ "$TARGET" = "android" ]; then
    if [ -f build/arm-linux-androideabi/luajit ]; then
        echo "ERROR: android build should not include luajit binary."
        exit 1
    fi
elif [ "$EMULATE_READER" = "1" ]; then
    # install tesseract trained language data for testing OCR functionality
    travis_retry wget https://src.fedoraproject.org/repo/pkgs/tesseract/tesseract-ocr-3.02.eng.tar.gz/3562250fe6f4e76229a329166b8ae853/tesseract-ocr-3.02.eng.tar.gz
    tar zxf tesseract-ocr-3.02.eng.tar.gz
    export TESSDATA_PREFIX
    cd build/* && TESSDATA_PREFIX=$(pwd)/data && mkdir -p data/tessdata
    mv ../../tesseract-ocr/tessdata/* data/tessdata/ && cd ../../ || exit
    # fetch font for base test
    travis_retry wget https://github.com/koreader/koreader-fonts/raw/master/droid/DroidSansMono.ttf
    export OUTPUT_DIR
    if [ -n "${KODEBUG+x}" ]; then
        KODEBUG_SUFFIX=-debug
    fi
    OUTPUT_DIR=$(ls -d ./build/x86_64-*linux-gnu${KODEBUG_SUFFIX})
    mkdir -p "${OUTPUT_DIR}/fonts/droid/"
    cp DroidSansMono.ttf "${OUTPUT_DIR}/fonts/droid/DroidSansMono.ttf"
    # finally make test
    travis_retry make test
fi

echo "test passed."
