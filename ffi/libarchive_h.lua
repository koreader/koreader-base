-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
typedef int64_t la_int64_t;
typedef ssize_t la_ssize_t;
static const int AE_IFREG = 32768;
static const int AE_IFLNK = 40960;
static const int AE_IFSOCK = 49152;
static const int AE_IFCHR = 8192;
static const int AE_IFBLK = 24576;
static const int AE_IFDIR = 16384;
static const int AE_IFIFO = 4096;
static const int ARCHIVE_EOF = 1;
static const int ARCHIVE_FAILED = -25;
static const int ARCHIVE_OK = 0;
static const int ARCHIVE_EXTRACT_SECURE_NODOTDOT = 512;
static const int ARCHIVE_EXTRACT_SECURE_SYMLINKS = 256;
static const int ARCHIVE_READDISK_NO_ACL = 32;
static const int ARCHIVE_READDISK_NO_FFLAGS = 64;
static const int ARCHIVE_READDISK_NO_SPARSE = 128;
static const int ARCHIVE_READDISK_NO_TRAVERSE_MOUNTS = 8;
static const int ARCHIVE_READDISK_NO_XATTR = 16;
unsigned int archive_entry_filetype(struct archive_entry *);
void archive_entry_free(struct archive_entry *);
struct archive_entry *archive_entry_new(void);
const char *archive_entry_pathname(struct archive_entry *);
void archive_entry_set_filetype(struct archive_entry *, unsigned int);
void archive_entry_set_gid(struct archive_entry *, la_int64_t);
void archive_entry_set_mtime(struct archive_entry *, long int, long int);
void archive_entry_set_pathname(struct archive_entry *, const char *);
void archive_entry_set_perm(struct archive_entry *, unsigned int);
void archive_entry_set_size(struct archive_entry *, la_int64_t);
void archive_entry_set_uid(struct archive_entry *, la_int64_t);
la_int64_t archive_entry_size(struct archive_entry *);
const char *archive_error_string(struct archive *);
int archive_free(struct archive *);
int archive_read_close(struct archive *);
la_ssize_t archive_read_data(struct archive *, void *, size_t);
int archive_read_data_block(struct archive *, const void **, size_t *, la_int64_t *);
int archive_read_extract2(struct archive *, struct archive_entry *, struct archive *);
struct archive *archive_read_new(void);
int archive_read_next_header2(struct archive *, struct archive_entry *);
int archive_read_open_filename(struct archive *, const char *, size_t);
int archive_read_support_filter_all(struct archive *);
int archive_read_support_format_all(struct archive *);
int archive_read_disk_descend(struct archive *);
struct archive *archive_read_disk_new(void);
int archive_read_disk_open(struct archive *, const char *);
int archive_read_disk_set_behavior(struct archive *, int);
int archive_write_add_filter_by_name(struct archive *, const char *);
int archive_write_close(struct archive *);
la_ssize_t archive_write_data(struct archive *, const void *, size_t);
struct archive *archive_write_disk_new(void);
int archive_write_disk_set_options(struct archive *, int);
int archive_write_header(struct archive *, struct archive_entry *);
struct archive *archive_write_new(void);
int archive_write_open_filename(struct archive *, const char *);
int archive_write_set_format_by_name(struct archive *, const char *);
int archive_write_zip_set_compression_deflate(struct archive *);
int archive_write_zip_set_compression_store(struct archive *);
]]
