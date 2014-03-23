## Koreader-base [![Build Status][travis-icon]][travis-link]

This is the base framework for creating document readers like Koreader,
an e-ink device oriented reader application for various document formats.

It's using the muPDF library (see http://mupdf.com/), djvulibre library,
CREngine library, libk2pdfopt library and it is scripted using Lua (see
http://www.lua.org/). To gain good speed at that, it uses the LuaJIT compiler.

It all started as the KindlePDFviewer application, which has since been
greatly enhanced and now reflects this in having a new name, Koreader.

The application is distributed under the GNU AGPL v3 license (read the [COPYING](COPYING) file).

## Building

Follow these steps:

* fetch thirdparty sources
	* manually fetch all the thirdparty sources:
		* install muPDF sources into subfolder "mupdf"
		* install muPDF third-party sources (see muPDF homepage) into a new
		subfolder "mupdf/thirdparty"
		* install libDjvuLibre sources into subfolder "djvulibre"
		* install CREngine sources into subfolder "kpvcrlib/crengine"
		* install LuaJit sources into subfolder "luajit-2.0"
		* install popen_noshell sources into subfolder "popen-noshell"
		* install libk2pdfopt sources into subfolder "libk2pdfopt"

	* automatically fetch thirdparty sources with Makefile:
		* make sure you have patch, wget, unzip, git and svn installed
		* run `make fetchthirdparty`.

* adapt Makefile to your needs

* run `make thirdparty`. This will build MuPDF (plus the libraries it depends
  on), libDjvuLibre, CREngine, libk2pdfopt and LuaJIT.

* run `make`. This will build the koreaderbase application which is a Lua
  interpreter offering the koreader-base API to Lua scripts.

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
* after using ccache, make a clean build will only take 15sec. Enjoy!
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

To build in "emulation mode", you need to run make like this:

```
make clean cleanthirdparty
EMULATE_READER=1 make thirdparty koreader-base
```

By default emulator will provide a resolution of 800x600. It can be
changed at runtime by changing environment variables:

```
EMULATE_READER_W=746 EMULATE_READER_H=1024 koreader-base
```

[travis-icon]:https://travis-ci.org/koreader/koreader-base.png?branch=master
[travis-link]:https://travis-ci.org/koreader/koreader-base

