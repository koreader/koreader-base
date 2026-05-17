-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
enum ion_heap_type {
  ION_HEAP_TYPE_SYSTEM,
  ION_HEAP_TYPE_SYSTEM_CONTIG,
  ION_HEAP_TYPE_CARVEOUT,
  ION_HEAP_TYPE_CHUNK,
  ION_HEAP_TYPE_DMA,
  ION_HEAP_TYPE_CUSTOM,
  ION_HEAP_TYPE_SECURE,
};
enum ion_heap_mask {
  ION_HEAP_MASK_SYSTEM = (1 << ION_HEAP_TYPE_SYSTEM),
  ION_HEAP_MASK_SYSTEM_CONTIG = (1 << ION_HEAP_TYPE_SYSTEM_CONTIG),
  ION_HEAP_MASK_CARVEOUT = (1 << ION_HEAP_TYPE_CARVEOUT),
  ION_HEAP_MASK_CHUNK = (1 << ION_HEAP_TYPE_CHUNK),
  ION_HEAP_MASK_DMA = (1 << ION_HEAP_TYPE_DMA),
  ION_HEAP_MASK_CUSTOM = (1 << ION_HEAP_TYPE_CUSTOM),
  ION_HEAP_MASK_SECURE = (1 << ION_HEAP_TYPE_SECURE),
};
typedef int ion_user_handle_t;
struct ion_allocation_data {
  size_t len;
  size_t align;
  unsigned int heap_id_mask;
  unsigned int flags;
  ion_user_handle_t handle;
};
struct ion_fd_data {
  ion_user_handle_t handle;
  int fd;
};
struct ion_handle_data {
  ion_user_handle_t handle;
};
static const unsigned ION_IOC_ALLOC = 3222554880;
static const unsigned ION_IOC_FREE = 3221506305;
static const unsigned ION_IOC_MAP = 3221768450;
]]
