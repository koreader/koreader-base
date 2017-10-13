#!/usr/bin/env bash

# install 32 bit libz package for NDK build
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install zlib1g:i386 libc6-dev-i386 linux-libc-dev:i386

if [ "$NDKREV" = "r11c" ]; then
    curl -L "http://dl.google.com/android/repository/android-ndk-${NDKREV}-linux-x86_64.zip" -O
    echo "extracting android ndk"
    unzip -q "android-ndk-${NDKREV}-linux-x86_64.zip"
elif [ "$NDKREV" = "r12b" ]; then
    wget "https://dl.google.com/android/repository/android-ndk-${NDKREV}-linux-x86_64.zip"
    echo "extracting android ndk"
    unzip -q "android-ndk-${NDKREV}-linux-x86_64.zip"
elif [ "$NDKREV" = "r15c" ]; then
    wget "https://dl.google.com/android/repository/android-ndk-${NDKREV}-linux-x86_64.zip"
    echo "extracting android ndk"
    unzip -q "android-ndk-${NDKREV}-linux-x86_64.zip"
fi

NDK=$(pwd)/android-ndk-${NDKREV}
export NDK
export PATH=$PATH:${NDK}
make android-toolchain
