#include <lzma.h>

#include "ffi-cdecl.h"

// base {{{

cdecl_const(LZMA_FILTERS_MAX);
cdecl_const(LZMA_STREAM_HEADER_SIZE);

cdecl_c99_type(lzma_vli, uint64_t);
cdecl_type(lzma_allocator);
cdecl_type(lzma_bool);
cdecl_type(lzma_reserved_enum);
cdecl_type(lzma_ret);

// }}}

/// check {{{

cdecl_type(lzma_check);

cdecl_func(lzma_check_size);

/// }}}

/// filter {{{

cdecl_type(lzma_filter);

/// }}}

/// stream {{{

cdecl_type(lzma_stream_flags);

cdecl_func(lzma_stream_flags_compare);
cdecl_func(lzma_stream_footer_decode);
cdecl_func(lzma_stream_footer_encode);
cdecl_func(lzma_stream_header_decode);
cdecl_func(lzma_stream_header_encode);

// }}}

/// index {{{

cdecl_type(lzma_index);
cdecl_type(lzma_index_iter);
cdecl_type(lzma_index_iter_mode);

cdecl_func(lzma_index_append);
cdecl_func(lzma_index_block_count);
cdecl_func(lzma_index_buffer_decode);
cdecl_func(lzma_index_buffer_encode);
cdecl_func(lzma_index_end);
cdecl_func(lzma_index_init);
cdecl_func(lzma_index_iter_init);
cdecl_func(lzma_index_iter_next);
cdecl_func(lzma_index_iter_rewind);
cdecl_func(lzma_index_size);
cdecl_func(lzma_index_stream_count);

/// }}}

/// block {{{

cdecl_type(lzma_block);

cdecl_func(lzma_block_buffer_decode);
cdecl_func(lzma_block_compressed_size);
cdecl_func(lzma_block_header_decode);
cdecl_func(lzma_block_total_size);
cdecl_func(lzma_block_unpadded_size);

/// }}}

//  vim: foldmethod=marker foldlevel=0
