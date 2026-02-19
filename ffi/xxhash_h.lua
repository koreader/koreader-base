-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
typedef struct XXH3_state_s XXH3_state_t;
typedef uint64_t XXH64_hash_t;
typedef enum {
  XXH_OK = 0,
  XXH_ERROR = 1,
} XXH_errorcode;
XXH3_state_t *XXH3_createState(void) __attribute__((malloc));
XXH_errorcode XXH3_freeState(XXH3_state_t *);
XXH_errorcode XXH3_64bits_reset(XXH3_state_t *);
XXH_errorcode XXH3_64bits_update(XXH3_state_t *, const void *, size_t);
XXH64_hash_t XXH3_64bits_digest(const XXH3_state_t *) __attribute__((pure));
]]
