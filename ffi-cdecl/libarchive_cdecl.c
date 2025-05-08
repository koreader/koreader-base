#include <archive.h>
#include <archive_entry.h>

#include "ffi-cdecl.h"

cdecl_const(AE_IFMT)
cdecl_const(AE_IFREG)
cdecl_const(AE_IFLNK)
cdecl_const(AE_IFSOCK)
cdecl_const(AE_IFCHR)
cdecl_const(AE_IFBLK)
cdecl_const(AE_IFDIR)
cdecl_const(AE_IFIFO)

cdecl_const(ARCHIVE_OK)

cdecl_func(archive_entry_free)
cdecl_func(archive_entry_new)
cdecl_func(archive_entry_set_filetype)
cdecl_func(archive_entry_set_mtime)
cdecl_func(archive_entry_set_pathname)
cdecl_func(archive_entry_set_perm)
cdecl_func(archive_entry_set_size)

cdecl_func(archive_error_string)

cdecl_func(archive_write_add_filter_none)
cdecl_func(archive_write_add_filter_compress)
cdecl_func(archive_write_close)
cdecl_func(archive_write_data)
cdecl_func(archive_write_free)
cdecl_func(archive_write_header)
cdecl_func(archive_write_new)
cdecl_func(archive_write_open_filename)
cdecl_func(archive_write_set_format_zip)

cdecl_func(archive_write_zip_set_compression_deflate)
cdecl_func(archive_write_zip_set_compression_store)
