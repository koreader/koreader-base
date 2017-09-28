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
	pushd android-sdk-linux/tools && \
		./android update sdk --all -u --filter "platform-tools,build-tools-26.0.1,android-14,android-19" && \
		popd
	rm -f $(SDK_TARBALL)


NDK_DL_URL=https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip
NDK_TARBALL=android-ndk-r15c-linux-x86_64.zip
NDK_SUM="0bf02d4e8b85fd770fd7b9b2cdec57f9441f27a2"
NDK_DIR=android-ndk-r15c

android-ndk:
	[ -e $(NDK_TARBALL) ] || wget $(NDK_DL_URL)
	CHECKSUM=`sha1sum $(NDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(NDK_SUM) ]] || \
		 { echo "$(NDK_TARBALL) has the wrong checksum!"; exit 1; }
	unzip $(NDK_TARBALL)
	rm -f $(NDK_TARBALL)
