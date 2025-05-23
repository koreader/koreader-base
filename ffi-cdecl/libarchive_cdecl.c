// FIXME: ffi-cdecl is not doing the right thing when using:
//
// typedef int64_t la_int64_t;
// typedef ssize_t la_ssize_t;
//
#include <sys/types.h>
#include <stdint.h>
#define __LA_INT64_T_DEFINED
#define la_int64_t int64_t
#define __LA_SSIZE_T_DEFINED
#define la_ssize_t ssize_t

#include <archive.h>
#include <archive_entry.h>

#include "ffi-cdecl.h"

cdecl_const(AE_IFREG)
cdecl_const(AE_IFLNK)
cdecl_const(AE_IFSOCK)
cdecl_const(AE_IFCHR)
cdecl_const(AE_IFBLK)
cdecl_const(AE_IFDIR)
cdecl_const(AE_IFIFO)

cdecl_const(ARCHIVE_EOF)
cdecl_const(ARCHIVE_FAILED)
cdecl_const(ARCHIVE_OK)

cdecl_const(ARCHIVE_EXTRACT_SECURE_NODOTDOT)
cdecl_const(ARCHIVE_EXTRACT_SECURE_SYMLINKS)

cdecl_const(ARCHIVE_READDISK_NO_ACL)
cdecl_const(ARCHIVE_READDISK_NO_FFLAGS)
cdecl_const(ARCHIVE_READDISK_NO_SPARSE)
cdecl_const(ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS)
cdecl_const(ARCHIVE_READDISK_NO_XATTR)

cdecl_func(archive_entry_filetype)
cdecl_func(archive_entry_free)
cdecl_func(archive_entry_new)
cdecl_func(archive_entry_pathname)
cdecl_func(archive_entry_set_filetype)
cdecl_func(archive_entry_set_gid)
cdecl_func(archive_entry_set_mtime)
cdecl_func(archive_entry_set_pathname)
cdecl_func(archive_entry_set_perm)
cdecl_func(archive_entry_set_size)
cdecl_func(archive_entry_set_uid)
cdecl_func(archive_entry_size)

cdecl_func(archive_error_string)
cdecl_func(archive_free)

cdecl_func(archive_read_close)
cdecl_func(archive_read_data)
cdecl_func(archive_read_data_block)
cdecl_func(archive_read_extract2)
cdecl_func(archive_read_new)
cdecl_func(archive_read_next_header2)
cdecl_func(archive_read_open_filename)
cdecl_func(archive_read_support_filter_all)
cdecl_func(archive_read_support_format_all)

cdecl_func(archive_read_disk_descend)
cdecl_func(archive_read_disk_new)
cdecl_func(archive_read_disk_open)
cdecl_func(archive_read_disk_set_behavior)

cdecl_func(archive_write_add_filter_by_name)
cdecl_func(archive_write_close)
cdecl_func(archive_write_data)
cdecl_func(archive_write_disk_new)
cdecl_func(archive_write_disk_set_options)
cdecl_func(archive_write_header)
cdecl_func(archive_write_new)
cdecl_func(archive_write_open_filename)
cdecl_func(archive_write_set_format_by_name)

cdecl_func(archive_write_zip_set_compression_deflate)
cdecl_func(archive_write_zip_set_compression_store)
