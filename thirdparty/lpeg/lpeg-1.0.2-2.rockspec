package = 'LPeg'
version = '1.0.2-2'
source = {
   url = 'http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.2.tar.gz',
   md5 = 'd342571886f1abcb7afe6a83d024d583',
}
description = {
   summary = 'Parsing Expression Grammars For Lua',
   detailed = [[
      LPeg is a new pattern-matching library for Lua, based on Parsing
      Expression Grammars (PEGs). The nice thing about PEGs is that it
      has a formal basis (instead of being an ad-hoc set of features),
      allows an efficient and simple implementation, and does most things
      we expect from a pattern-matching library (and more, as we can
      define entire grammars).
   ]],
   homepage = 'http://www.inf.puc-rio.br/~roberto/lpeg.html',
   maintainer = 'Gary V. Vaughan <gary@vaughan.pe>',
   license = 'MIT/X11'
}
dependencies = {
   'lua >= 5.1'
}
build = {
   patches = {
      ["lpeg-1.0.2-standard-makefile.patch"] = [[
diff -Nuarp lpeg-1.0.2-orig/makefile lpeg-1.0.2/makefile
--- lpeg-1.0.2-orig/makefile    2019-03-11 15:08:29.000000000 +0100
+++ lpeg-1.0.2/makefile 2022-10-16 19:24:30.265054720 +0200
@@ -1,10 +1,8 @@
-LIBNAME = lpeg
-LUADIR = ../lua/
+LIBNAME := lpeg
+LUADIR ?= ../lua/

-COPT = -O2 -DNDEBUG
-# COPT = -g
-
-CWARNS = -Wall -Wextra -pedantic \
+PROJ_CPPFLAGS := -DNDEBUG -I$(LUADIR)
+CWARNS := -Wall -Wextra -pedantic \
        -Waggregate-return \
        -Wcast-align \
        -Wcast-qual \
@@ -18,38 +16,40 @@ CWARNS = -Wall -Wextra -pedantic \
        -Wdeclaration-after-statement \
        -Wmissing-prototypes \
        -Wnested-externs \
-       -Wstrict-prototypes \
-# -Wunreachable-code \
-
+       -Wstrict-prototypes
+COPT := -O2
+CSTD := -std=c99

-CFLAGS = $(CWARNS) $(COPT) -std=c99 -I$(LUADIR) -fPIC
-CC = gcc
+PROJ_CFLAGS := $(COPT) $(CSTD) $(CWARNS) -fPIC
+CC ?= gcc

-FILES = lpvm.o lpcap.o lptree.o lpcode.o lpprint.o
+FILES := lpvm.o lpcap.o lptree.o lpcode.o lpprint.o

 # For Linux
 linux:
-       $(MAKE) lpeg.so "DLLFLAGS = -shared -fPIC"
+       $(MAKE) lpeg.so "DLLFLAGS = -shared"

 # For Mac OS
 macosx:
        $(MAKE) lpeg.so "DLLFLAGS = -bundle -undefined dynamic_lookup"

 lpeg.so: $(FILES)
-       env $(CC) $(DLLFLAGS) $(FILES) -o lpeg.so
+       $(CC) $(PROJ_CPPFLAGS) -I$(LUA_INCDIR) $(CPPFLAGS) $(PROJ_CFLAGS) $(CFLAGS) $(DLLFLAGS) $(LIBFLAG) $(LDFLAGS) $(FILES) -o lpeg.so -L$(LUA_LIBDIR) $(LUALIB) $(LIBS)

 $(FILES): makefile

+install: lpeg.so re.lua
+       cp lpeg.so $(INST_LIBDIR)
+       cp re.lua $(INST_LUADIR)
+
 test: test.lua re.lua lpeg.so
        ./test.lua

 clean:
        rm -f $(FILES) lpeg.so

-
 lpcap.o: lpcap.c lpcap.h lptypes.h
 lpcode.o: lpcode.c lptypes.h lpcode.h lptree.h lpvm.h lpcap.h
 lpprint.o: lpprint.c lptypes.h lpprint.h lptree.h lpvm.h lpcap.h
 lptree.o: lptree.c lptypes.h lpcap.h lpcode.h lptree.h lpvm.h lpprint.h
 lpvm.o: lpvm.c lpcap.h lptypes.h lpvm.h lpprint.h lptree.h
-
   ]]
   },
   type = 'make',
   makefile = 'makefile',
}
