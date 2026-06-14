#include <xxhash.h>

cdecl_type(XXH3_state_t);
cdecl_type(XXH64_hash_t);

cdecl_type(XXH_errorcode);

cdecl_func(XXH3_createState);
cdecl_func(XXH3_freeState);
cdecl_func(XXH3_64bits_reset);
cdecl_func(XXH3_64bits_update);
cdecl_func(XXH3_64bits_digest);
