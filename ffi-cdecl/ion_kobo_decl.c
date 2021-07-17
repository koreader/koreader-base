#include <linux/ioctl.h>
// specialized ION headers
#include "include/ion-kobo.h"

#include "ffi-cdecl.h"

cdecl_type(ion_user_handle_t)
cdecl_struct(ion_allocation_data)
cdecl_struct(ion_fd_data)
cdecl_struct(ion_handle_data)

cdecl_const(ION_IOC_ALLOC)
cdecl_const(ION_IOC_FREE)
cdecl_const(ION_IOC_MAP)

cdecl_enum(ion_heap_mask)
