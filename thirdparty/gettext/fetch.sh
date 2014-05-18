#!/bin/bash

GETTEXT_TAR="gettext-0.18.3.2.tar.gz"
#GETTEXT_TAR_URL="http://ftp.gnu.org/pub/gnu/gettext/$GETTEXT_TAR"
#GETTEXT_TAR_URL="http://mirrors.kernel.org/gnu/gettext/$GETTEXT_TAR"
GETTEXT_TAR_URL="ftp://aeneas.mit.edu/pub/gnu/gettext/$GETTEXT_TAR"
GETTEXT_TAR_GOOD_SUM=d1a4e452d60eb407ab0305976529a45c18124bd518d976971ac6dc7aa8b4c5d7

function download() {
	wget $GETTEXT_TAR_URL
}

if [ ! -f $GETTEXT_TAR ]; then
    echo "No download file"
	download
else
	GETTEXT_TAR_SUM=`sha256sum gettext-0.18.3.2.tar.gz  | awk '{print $1}'`
	if [ $GETTEXT_TAR_SUM != $GETTEXT_TAR_GOOD_SUM ]; then
		rm $GETTEXT_TAR
		download
	else
		IS_CHECKED=1
	fi
fi

if [ ! $IS_CHECKED ]; then
	GETTEXT_TAR_SUM=`sha256sum gettext-0.18.3.2.tar.gz  | awk '{print $1}'`
	if [ $GETTEXT_TAR_SUM != $GETTEXT_TAR_GOOD_SUM ]; then
		echo "Wrong checksum for gettext source, abort!"
		exit -1
	fi
fi

tar zxf $GETTEXT_TAR
