-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
static const int LZMA_FILTERS_MAX = 4;
static const int LZMA_STREAM_HEADER_SIZE = 12;
typedef uint64_t lzma_vli;
typedef struct {
  void *(*alloc)(void *, size_t, size_t);
  void (*free)(void *, void *);
  void *opaque;
} lzma_allocator;
typedef unsigned char lzma_bool;
typedef enum {
  LZMA_RESERVED_ENUM = 0,
} lzma_reserved_enum;
typedef enum {
  LZMA_OK = 0,
  LZMA_STREAM_END = 1,
  LZMA_NO_CHECK = 2,
  LZMA_UNSUPPORTED_CHECK = 3,
  LZMA_GET_CHECK = 4,
  LZMA_MEM_ERROR = 5,
  LZMA_MEMLIMIT_ERROR = 6,
  LZMA_FORMAT_ERROR = 7,
  LZMA_OPTIONS_ERROR = 8,
  LZMA_DATA_ERROR = 9,
  LZMA_BUF_ERROR = 10,
  LZMA_PROG_ERROR = 11,
  LZMA_SEEK_NEEDED = 12,
  LZMA_RET_INTERNAL1 = 101,
  LZMA_RET_INTERNAL2 = 102,
  LZMA_RET_INTERNAL3 = 103,
  LZMA_RET_INTERNAL4 = 104,
  LZMA_RET_INTERNAL5 = 105,
  LZMA_RET_INTERNAL6 = 106,
  LZMA_RET_INTERNAL7 = 107,
  LZMA_RET_INTERNAL8 = 108,
} lzma_ret;
typedef enum {
  LZMA_CHECK_NONE = 0,
  LZMA_CHECK_CRC32 = 1,
  LZMA_CHECK_CRC64 = 4,
  LZMA_CHECK_SHA256 = 10,
} lzma_check;
uint32_t lzma_check_size(lzma_check) __attribute__((nothrow, const));
typedef struct {
  lzma_vli id;
  void *options;
} lzma_filter;
typedef struct {
  uint32_t version;
  lzma_vli backward_size;
  lzma_check check;
  lzma_reserved_enum reserved_enum1;
  lzma_reserved_enum reserved_enum2;
  lzma_reserved_enum reserved_enum3;
  lzma_reserved_enum reserved_enum4;
  lzma_bool reserved_bool1;
  lzma_bool reserved_bool2;
  lzma_bool reserved_bool3;
  lzma_bool reserved_bool4;
  lzma_bool reserved_bool5;
  lzma_bool reserved_bool6;
  lzma_bool reserved_bool7;
  lzma_bool reserved_bool8;
  uint32_t reserved_int1;
  uint32_t reserved_int2;
} lzma_stream_flags;
lzma_ret lzma_stream_flags_compare(const lzma_stream_flags *, const lzma_stream_flags *) __attribute__((nothrow, pure));
lzma_ret lzma_stream_footer_decode(lzma_stream_flags *, const uint8_t *) __attribute__((nothrow));
lzma_ret lzma_stream_footer_encode(const lzma_stream_flags *, uint8_t *) __attribute__((nothrow));
lzma_ret lzma_stream_header_decode(lzma_stream_flags *, const uint8_t *) __attribute__((nothrow));
lzma_ret lzma_stream_header_encode(const lzma_stream_flags *, uint8_t *) __attribute__((nothrow));
typedef struct lzma_index_s lzma_index;
typedef struct {
  struct {
    const lzma_stream_flags *flags;
    const void *reserved_ptr1;
    const void *reserved_ptr2;
    const void *reserved_ptr3;
    lzma_vli number;
    lzma_vli block_count;
    lzma_vli compressed_offset;
    lzma_vli uncompressed_offset;
    lzma_vli compressed_size;
    lzma_vli uncompressed_size;
    lzma_vli padding;
    lzma_vli reserved_vli1;
    lzma_vli reserved_vli2;
    lzma_vli reserved_vli3;
    lzma_vli reserved_vli4;
  } stream;
  struct {
    lzma_vli number_in_file;
    lzma_vli compressed_file_offset;
    lzma_vli uncompressed_file_offset;
    lzma_vli number_in_stream;
    lzma_vli compressed_stream_offset;
    lzma_vli uncompressed_stream_offset;
    lzma_vli uncompressed_size;
    lzma_vli unpadded_size;
    lzma_vli total_size;
    lzma_vli reserved_vli1;
    lzma_vli reserved_vli2;
    lzma_vli reserved_vli3;
    lzma_vli reserved_vli4;
    const void *reserved_ptr1;
    const void *reserved_ptr2;
    const void *reserved_ptr3;
    const void *reserved_ptr4;
  } block;
  union {
    const void *p;
    size_t s;
    lzma_vli v;
  } internal[6];
} lzma_index_iter;
typedef enum {
  LZMA_INDEX_ITER_ANY = 0,
  LZMA_INDEX_ITER_STREAM = 1,
  LZMA_INDEX_ITER_BLOCK = 2,
  LZMA_INDEX_ITER_NONEMPTY_BLOCK = 3,
} lzma_index_iter_mode;
lzma_ret lzma_index_append(lzma_index *, const lzma_allocator *, lzma_vli, lzma_vli) __attribute__((nothrow));
lzma_vli lzma_index_block_count(const lzma_index *) __attribute__((nothrow, pure));
lzma_ret lzma_index_buffer_decode(lzma_index **, uint64_t *, const lzma_allocator *, const uint8_t *, size_t *, size_t) __attribute__((nothrow));
lzma_ret lzma_index_buffer_encode(const lzma_index *, uint8_t *, size_t *, size_t) __attribute__((nothrow));
void lzma_index_end(lzma_index *, const lzma_allocator *) __attribute__((nothrow));
lzma_index *lzma_index_init(const lzma_allocator *) __attribute__((nothrow));
void lzma_index_iter_init(lzma_index_iter *, const lzma_index *) __attribute__((nothrow));
lzma_bool lzma_index_iter_next(lzma_index_iter *, lzma_index_iter_mode) __attribute__((nothrow));
void lzma_index_iter_rewind(lzma_index_iter *) __attribute__((nothrow));
lzma_vli lzma_index_size(const lzma_index *) __attribute__((nothrow, pure));
lzma_vli lzma_index_stream_count(const lzma_index *) __attribute__((nothrow, pure));
typedef struct {
  uint32_t version;
  uint32_t header_size;
  lzma_check check;
  lzma_vli compressed_size;
  lzma_vli uncompressed_size;
  lzma_filter *filters;
  uint8_t raw_check[64];
  void *reserved_ptr1;
  void *reserved_ptr2;
  void *reserved_ptr3;
  uint32_t reserved_int1;
  uint32_t reserved_int2;
  lzma_vli reserved_int3;
  lzma_vli reserved_int4;
  lzma_vli reserved_int5;
  lzma_vli reserved_int6;
  lzma_vli reserved_int7;
  lzma_vli reserved_int8;
  lzma_reserved_enum reserved_enum1;
  lzma_reserved_enum reserved_enum2;
  lzma_reserved_enum reserved_enum3;
  lzma_reserved_enum reserved_enum4;
  lzma_bool ignore_check;
  lzma_bool reserved_bool2;
  lzma_bool reserved_bool3;
  lzma_bool reserved_bool4;
  lzma_bool reserved_bool5;
  lzma_bool reserved_bool6;
  lzma_bool reserved_bool7;
  lzma_bool reserved_bool8;
} lzma_block;
lzma_ret lzma_block_buffer_decode(lzma_block *, const lzma_allocator *, const uint8_t *, size_t *, size_t, uint8_t *, size_t *, size_t) __attribute__((nothrow));
lzma_ret lzma_block_compressed_size(lzma_block *, lzma_vli) __attribute__((nothrow));
lzma_ret lzma_block_header_decode(lzma_block *, const lzma_allocator *, const uint8_t *) __attribute__((nothrow));
lzma_vli lzma_block_total_size(const lzma_block *) __attribute__((nothrow, pure));
lzma_vli lzma_block_unpadded_size(const lzma_block *) __attribute__((nothrow, pure));
]]
