#!/usr/bin/env bash

# install 32 bit libz package for NDK build
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install zlib1g:i386 libc6-dev-i386 linux-libc-dev:i386

if [ "$NDKREV" = "r9c" ]; then
    curl -L http://dl.google.com/android/ndk/android-ndk-${NDKREV}-linux-x86_64.tar.bz2 -O
    echo "extracting android ndk"
    bzip2 -dc android-ndk-${NDKREV}-linux-x86_64.tar.bz2 | tar xf -
elif [ "$NDKREV" = "r11c" ]; then
    curl -L http://dl.google.com/android/repository/android-ndk-${NDKREV}-linux-x86_64.zip -O
    echo "extracting android ndk"
    unzip -q android-ndk-${NDKREV}-linux-x86_64.zip
elif [ "$NDKREV" = "r12b" ]; then
    wget https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
    echo "extracting android ndk"
    unzip -q android-ndk-${NDKREV}-linux-x86_64.zip
fi

export NDK=`pwd`/android-ndk-${NDKREV}
export PATH=$PATH:${NDK}
make android-toolchain
