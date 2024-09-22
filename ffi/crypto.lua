--[[--
LuaJIT FFI wrapper for libcrypto (OpenSSL).

@module ffi.crypto
]]

local ffi = require("ffi")
require("ffi/crypto_h")

local libcrypto = ffi.loadlib("crypto", "1.1")
local crypto = {}

function crypto.pbkdf2_hmac_sha1(pass, salt, iterations, key_len)
    local buf = ffi.new("char[?]", key_len)
    local res = libcrypto.PKCS5_PBKDF2_HMAC_SHA1(pass, #pass, salt, #salt, iterations, key_len, buf)
    assert(res == 1)
    return ffi.string(buf, key_len)
end

return crypto
