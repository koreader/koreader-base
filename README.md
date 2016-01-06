## koreader-base [![Build Status][travis-icon]][travis-link]

This is the base framework for creating document readers like KOReader,
an e-ink device oriented reader application for various document formats.

It's using the MuPDF library (see http://mupdf.com/), djvulibre library,
CREngine library, libk2pdfopt library and it is scripted using Lua (see
http://www.lua.org/). To gain good speed at that, it uses the LuaJIT compiler.

It all started as the KindlePDFviewer application, which has since been
greatly enhanced and now reflects this in having a new name, KOReader.

The code is distributed under the GNU AGPL v3 license (read the [COPYING](COPYING) file).

## Building

Follow these steps:

* automatically fetch thirdparty sources with Makefile:
		* make sure you have patch, wget, unzip, git and svn installed
		* run `make fetchthirdparty`.

* run `make TARGET=kindle5` or `make TARGET=kindlepw2` for touch based Kindle devices.

* run `make TARGET=kindle-legacy` for Kindle DXG/2/3/4 devices.

* or run `make TARGET=kobo` for Kobo devices.

* or run `make TARGET=pocketbook` for pocketbook devices.

* or run `make TARGET=android` for Android devices.

* or run `make TARGET=win32` for Windows.

* or run `make TARGET=generic-arm` for generic ARM devices.

* or run `make TARGET=ubuntu-touch` for Ubuntu Touch.

* or run `make` for emulator on Linux.

## Use ccache

Ccache can speed up recompilation by caching previous compilations and detecting
when the same compilation is being done again. In other words, it will decrease
build time when the source have been built. Ccache support has been added to
KOReader's build system. Before using it, you need to install a ccache in your
system.

* in ubuntu use:`sudo apt-get install ccache`
* in fedora use:`sudo yum install ccache`
* install from source:
  * get latest ccache source from http://ccache.samba.org/download.html
  * unarchieve the source package in a directory
  * cd to that directory and use:`./configure && make && sudo make install`
* to disable ccache, use `export USE_NO_CCACHE=1` before make.
* for more detail about ccache. visit:

http://ccache.samba.org

Device emulation
================

The code also features a device emulation. You need SDL headers and library
for this. It allows to develop on a standard PC and saves precious development
time. It might also compose the most unfriendly desktop PDF reader, depending
on your view.

If you are using Fedora Core Linux, do `yum install SDL SDL-devel`.
If you are using Ubuntu, install `libsdl-dev1.2` package.

Alternatively, SDL2 is supported, too.

By default, the build system builds in "emulation mode", so following is all
you need to build the emulator:

```
make
```

The emulator uses 800x600 as the default resolution. It can be
changed at runtime by changing the following environment variables:

```
EMULATE_READER_W=746 EMULATE_READER_H=1024
```

KOReader supports "viewports", i.e. displaying only in a rectangular
excerpt of the screen. This is useful on devices where the framebuffer
is larger than the area that is actually visible. In order to simulate
such a viewport using the emulator, specify a specially crafted environment
variable:
```
EMULATE_READER_VIEWPORT="{x=50,w=600,y=10,h=680}"
```

You can also simulate e-ink refresh with the emulator. When active, only
refreshed areas of the screen are actually updated and you also get a visual
inverse flash feedback. In order to activate that mode, set an environment
variable to the number of milliseconds you want the flash to endure:
```
EMULATE_READER_FLASH=100
```

[travis-icon]:https://travis-ci.org/koreader/koreader-base.png?branch=master
[travis-link]:https://travis-ci.org/koreader/koreader-base

