#!/usr/bin/env bash

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6-dev-i386 linux-libc-dev:i386

sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
