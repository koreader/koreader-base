-- Automatically generated with: ffi-cdecl -o ffi/crypto_h.lua -d libcrypto ffi-cdecl/crypto_decl.c

local ffi = require("ffi")

ffi.cdef[[
int PKCS5_PBKDF2_HMAC_SHA1(const char *, int, const unsigned char *, int, int, int, unsigned char *);
]]
