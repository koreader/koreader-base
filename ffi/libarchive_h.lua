-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
static const int AE_IFMT = 61440;
static const int AE_IFREG = 32768;
static const int AE_IFLNK = 40960;
static const int AE_IFSOCK = 49152;
static const int AE_IFCHR = 8192;
static const int AE_IFBLK = 24576;
static const int AE_IFDIR = 16384;
static const int AE_IFIFO = 4096;
static const int ARCHIVE_OK = 0;
void archive_entry_free(struct archive_entry *);
struct archive_entry *archive_entry_new(void);
void archive_entry_set_filetype(struct archive_entry *, unsigned int);
void archive_entry_set_mtime(struct archive_entry *, long int, long int);
void archive_entry_set_pathname(struct archive_entry *, const char *);
void archive_entry_set_perm(struct archive_entry *, unsigned int);
void archive_entry_set_size(struct archive_entry *, int64_t);
const char *archive_error_string(struct archive *);
int archive_write_add_filter_none(struct archive *);
int archive_write_add_filter_compress(struct archive *);
int archive_write_close(struct archive *);
ssize_t archive_write_data(struct archive *, const void *, size_t);
int archive_write_free(struct archive *);
int archive_write_header(struct archive *, struct archive_entry *);
struct archive *archive_write_new(void);
int archive_write_open_filename(struct archive *, const char *);
int archive_write_set_format_zip(struct archive *);
int archive_write_zip_set_compression_deflate(struct archive *);
int archive_write_zip_set_compression_store(struct archive *);
]]
