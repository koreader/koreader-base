Koreader-base
=============

This is the base framework for creating document readers like Koreader,
an e-ink device oriented reader application for various document formats.

It's using the muPDF library (see http://mupdf.com/), djvulibre library,
CREngine library and it is scripted using Lua (see http://www.lua.org/).
To gain good speed at that, it uses the LuaJIT compiler.

It all started as the KindlePDFviewer application, which has since been
greatly enhanced and now reflects this in having a new name, Koreader.

The application is licensed under the GPLv3 (see COPYING file).


Building
========

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

	* automatically fetch thirdparty sources with Makefile:
		* make sure you have patch, wget, unzip, git and svn installed
		* run `make fetchthirdparty`.

* adapt Makefile to your needs

* run `make thirdparty`. This will build MuPDF (plus the libraries it depends
  on), libDjvuLibre, CREngine and LuaJIT.

* run `make`. This will build the koreaderbase application which is a Lua
  interpreter offering the koreader-base API to Lua scripts.


Device emulation
================

The code also features a device emulation. You need SDL headers and library
for this. It allows to develop on a standard PC and saves precious development
time. It might also compose the most unfriendly desktop PDF reader, depending
on your view.

If you are using Fedora Core Linux, do `yum install SDL SDL-devel`.
If you are using Ubuntu, install `libsdl-dev1.2` package.

To build in "emulation mode", you need to run make like this:
	make clean cleanthirdparty
	EMULATE_READER=1 make thirdparty koreader-base

By default emulation will provide a resolution of 824x1200. It can be
specified at compile time, this is example for 600x800:

```
EMULATE_READER_W=600 EMULATE_READER_H=800 EMULATE_READER=1 make kpdfview
```

