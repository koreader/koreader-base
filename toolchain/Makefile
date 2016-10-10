SHELL:=/bin/bash


SDK_DL_URL=https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
SDK_TARBALL=android-sdk_r24.4.1-linux.tgz
SDK_SUM="978ee9da3dda10fb786709b7c2e924c0"
SDK_DIR=android-sdk-linux

android-sdk:
	[ -e $(SDK_TARBALL) ] || wget $(SDK_DL_URL)
	CHECKSUM=`md5sum $(SDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(SDK_SUM) ]] || \
		 { echo "$(SDK_TARBALL) has the wrong checksum!"; exit 1; }
	tar xvf $(SDK_TARBALL)
	rm -f $(SDK_TARBALL)


NDK_DL_URL=https://dl.google.com/android/repository/android-ndk-r12b-linux-x86_64.zip
NDK_TARBALL=android-ndk-r12b-linux-x86_64.zip
NDK_SUM="1d1a5ee71a5123be01e0dd9adb5df80d"
NDK_DIR=android-ndk-r12b

android-ndk:
	[ -e $(NDK_TARBALL) ] || wget $(NDK_DL_URL)
	CHECKSUM=`md5sum $(NDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(NDK_SUM) ]] || \
		 { echo "$(NDK_TARBALL) has the wrong checksum!"; exit 1; }
	unzip $(NDK_TARBALL)
	rm -f $(NDK_TARBALL)
