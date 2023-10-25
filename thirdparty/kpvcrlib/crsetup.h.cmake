#ifndef CRSETUP_H_INCLUDED
#define CRSETUP_H_INCLUDED

/// Yes, even on macOS (Windows is unsupported)…
#define LINUX 1
#define _LINUX 1

#cmakedefine _DEBUG           1
#cmakedefine DISABLE_CLOEXEC  1
#cmakedefine HAVE_OFF64_T     1
#ifdef HAVE_OFF64_T
# define _LARGEFILE64_SOURCE  1
#endif

/// Compression.
#define USE_ZLIB                             1
#define USE_ZSTD                             1
#define ZIP_STREAM_BUFFER_SIZE               0x40000   // 256.0 KiB

/// Documents cache.
#define DOCUMENT_CACHING_MIN_SIZE            0x10000   //  64.0 KiB
#define DOCUMENT_CACHING_SIZE_THRESHOLD      0x100000  //   1.0 MiB

/// Document formats.
#define CHM_SUPPORT_ENABLED                  1
#define CR3_ANTIWORD_PATCH                   1
#define ENABLE_ANTIWORD                      1

/// Files.
#define LVLONG_FILE_SUPPORT                  0
#define USE_ANSI_FILES                       1
#define FILE_STREAM_BUFFER_SIZE              0x20000

/// I18N
#define CR_EMULATE_GETTEXT                   1

/// Images.
#define ARBITRARY_IMAGE_SCALE_ENABLED        1
#define MAX_IMAGE_SCALE_MUL                  2
#define USE_GIF                              1
#define USE_LIBJPEG                          1
#define USE_LIBPNG                           1
#define USE_LIBWEBP                          1
#define USE_LUNASVG                          1
#define USE_NANOSVG                          0  // better SVG support via LunaSVG

/// Miscellaneous.
#define MATHML_SUPPORT                       1
#define USE_SRELL_REGEX                      1

/// Output buffer.
#define COLOR_BACKBUFFER                     1
#define CR_INTERNAL_PAGE_ORIENTATION         1
#define GRAY_BACKBUFFER_BITS                 2
#define GRAY_INVERSE                         0

/// Skin support.
// FIXME: to be removed once we stop compiling `crskin.cpp`.
#define MAX_SKIN_IMAGE_CACHE_ITEM_UNPACKED_SIZE         (80*80*4)
#define MAX_SKIN_IMAGE_CACHE_ITEM_RAM_COPY_PACKED_SIZE  10000

/// System.
#define CR_USE_THREADS                       0
#define LDOM_USE_OWN_MEM_MAN                 1

/// Text.
#define ALLOW_KERNING                        1
#define GLYPH_CACHE_SIZE                     0x40000   // 256.0 KiB
#define USE_BITMAP_FONTS                     0
#define USE_FONTCONFIG                       0
#define USE_FREETYPE                         1
#define USE_FRIBIDI                          1
#define USE_GLYPHCACHE_HASHTABLE             0
#define USE_HARFBUZZ                         1
#define USE_LIBUNIBREAK                      1
#define USE_LIMITED_FONT_SIZES_SET           0
#define USE_UTF8PROC                         1
#define USE_WIN32_FONTS                      0

#endif//CRSETUP_H_INCLUDED
