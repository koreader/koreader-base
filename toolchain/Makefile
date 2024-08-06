.DELETE_ON_ERROR:
.ONESHELL:

SHELL := /bin/bash
.SHELLFLAGS := -xec

TOOLCHAIN_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Sdk tools 26.1.1
SDK_TARBALL = commandlinetools-linux-10406996_latest.zip
SDK_DL_URL = https://dl.google.com/android/repository/$(SDK_TARBALL)

.SECONDARY: $(SDK_TARBALL)

SDK_SUM = 87b485c7283cba69e41c10f05bf832d2fd691552
SDK_DIR = android-sdk-linux

WGET ?= wget --progress=dot:giga

android-sdk: $(TOOLCHAIN_DIR)/$(SDK_DIR)

$(SDK_TARBALL):
	$(WGET) '$(SDK_DL_URL)'
	echo '$(SDK_SUM) $(SDK_TARBALL)' | sha1sum -c -

$(TOOLCHAIN_DIR)/$(SDK_DIR): $(SDK_TARBALL)
	mkdir -p $(SDK_DIR)/cmdline-tools
	cd $(SDK_DIR)/cmdline-tools
	unzip $(TOOLCHAIN_DIR)/$(SDK_TARBALL)
	mv cmdline-tools latest
	cd latest/bin
	yes | ./sdkmanager --update
	yes | ./sdkmanager --licenses
	./sdkmanager 'platform-tools' 'build-tools;34.0.0' 'platforms;android-30'
	./sdkmanager --uninstall 'emulator' # Installed automatically but we don't need it.
	rm -f $(TOOLCHAIN_DIR)/$(SDK_TARBALL)

# NDK r15c
NDK_DIR = android-ndk-r23c
NDK_TARBALL = $(NDK_DIR)-linux.zip
NDK_DL_URL = https://dl.google.com/android/repository/$(NDK_TARBALL)
NDK_SUM = e5053c126a47e84726d9f7173a04686a71f9a67a

.SECONDARY: $(NDK_TARBALL)

android-ndk: $(TOOLCHAIN_DIR)/$(NDK_DIR)

$(NDK_TARBALL):
	$(WGET) '$(NDK_DL_URL)'
	echo '$(NDK_SUM) $(NDK_TARBALL)' | sha1sum -c -

$(TOOLCHAIN_DIR)/$(NDK_DIR): $(NDK_TARBALL)
	unzip $(NDK_TARBALL)
	# Trim the fat.
	rm -vrf $(NDK_DIR)/toolchains/renderscript
	rm -vrf $(NDK_DIR)/toolchains/llvm/prebuilt/linux-x86_64/bin/*1[67]-clang*
	rm -vrf $(NDK_DIR)/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/*/1[67]
	if which hardlink; then
	  hardlink $(NDK_DIR)
	fi
	rm -f $(NDK_TARBALL)

android: android-sdk android-ndk
