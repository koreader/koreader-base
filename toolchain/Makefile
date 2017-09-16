SHELL:=/bin/bash


SDK_DL_URL=https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
SDK_TARBALL=sdk-tools-linux-3859397.zip
SDK_SUM="444e22ce8ca0f67353bda4b85175ed3731cae3ffa695ca18119cbacef1c1bea0"
SDK_DIR=android-sdk-linux

android-sdk:
	[ -e $(SDK_TARBALL) ] || wget $(SDK_DL_URL)
	CHECKSUM=`sha256sum $(SDK_TARBALL) | awk '{ print $$1 }'`; \
		 [[ "$$CHECKSUM" = $(SDK_SUM) ]] || \
		 { echo "$(SDK_TARBALL) has the wrong checksum!"; exit 1; }
	[ -e android-sdk-linux ] || { mkdir android-sdk-linux && \
		pushd android-sdk-linux && unzip ../$(SDK_TARBALL) && popd; }
	# broken nonsense in the SDK as usual; error message if you don't do this
	[ -e ~/.android/repositories.cfg ] || touch ~/.android/repositories.cfg
	pushd android-sdk-linux/tools/bin && \
	yes | ./sdkmanager --licenses && \
	./sdkmanager "build-tools;26.0.1" "platform-tools" "platforms;android-14" "platforms;android-16" && \
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
