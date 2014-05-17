#include "cdecl.h"
#include <stdlib.h>
#include <locale.h>
#include "libintl.h"

cdecl_func(setlocale)
cdecl_func(bindtextdomain)
cdecl_func(textdomain)
cdecl_func(gettext)
cdecl_func(setenv)

cdecl_const(LC_ALL)

