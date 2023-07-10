SHELL:=/bin/bash

TOOLCHAIN_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Sdk tools 26.1.1
SDK_TARBALL=sdk-tools-linux-4333796.zip
SDK_DL_URL=https://dl.google.com/android/repository/$(SDK_TARBALL)

SDK_SUM="aa190cfd7299cd6a1c687355bb2764e4"
SDK_DIR=android-sdk-linux

WGET?=wget --progress=dot:giga

android-sdk: $(TOOLCHAIN_DIR)/$(SDK_DIR)

$(TOOLCHAIN_DIR)/$(SDK_DIR):
	[ -e $(SDK_TARBALL) ] || $(WGET) $(SDK_DL_URL)
	CHECKSUM=`md5sum $(SDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(SDK_SUM) ]] || \
		 { echo "$(SDK_TARBALL) has the wrong checksum!"; exit 1; }

	mkdir -pv $(SDK_DIR)
	mv -v $(SDK_TARBALL) $(SDK_DIR)
	unzip $(SDK_DIR)/$(SDK_TARBALL) -d $(SDK_DIR)
	pushd $(SDK_DIR)/tools/bin && \
		yes | ./sdkmanager --update && \
		yes | ./sdkmanager --licenses && \
		./sdkmanager "platform-tools" "build-tools;30.0.2" "platforms;android-30" "patcher;v4" && \
		popd
	rm -f $(SDK_DIR)/$(SDK_TARBALL)

# NDK r15c
NDK_DIR=android-ndk-r23c
NDK_TARBALL=$(NDK_DIR)-linux.zip
NDK_DL_URL=https://dl.google.com/android/repository/$(NDK_TARBALL)
NDK_SUM="e5053c126a47e84726d9f7173a04686a71f9a67a"

android-ndk: $(TOOLCHAIN_DIR)/$(NDK_DIR)

$(TOOLCHAIN_DIR)/$(NDK_DIR):
	[ -e $(NDK_TARBALL) ] || $(WGET) $(NDK_DL_URL)
	CHECKSUM=`sha1sum $(NDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(NDK_SUM) ]] || \
		 { echo "$(NDK_TARBALL) has the wrong checksum!"; exit 1; }
	unzip $(NDK_TARBALL)
	rm -f $(NDK_TARBALL)

android: android-sdk android-ndk
