--[[--
LuaJIT FFI wrapper for libcrypto (OpenSSL).

@module ffi.crypto
]]

local ffi = require("ffi")
require("ffi/crypto_h")

local libcrypto = ffi.loadlib("crypto", "57")
local crypto = {}

function crypto.pbkdf2_hmac_sha1(pass, salt, iterations, key_len)
    local buf = ffi.new("char[?]", key_len)
    local res = libcrypto.PKCS5_PBKDF2_HMAC_SHA1(pass, #pass, salt, #salt, iterations, key_len, buf)
    assert(res == 1)
    return ffi.string(buf, key_len)
end

function crypto.pkcs7_unpad(content, length, block_size)
    if length <= 0 or (length % block_size) ~= 0 then
        return nil
    end

    local padding_length = content[length - 1] -- index is zero-based here
    if padding_length <= 0 or padding_length > block_size then
        return nil
    end

    return ffi.string(content, length - padding_length)
end

function crypto.get_aes_ecb_cipher(block_size)
    if block_size == 16 then
        return libcrypto.EVP_aes_128_ecb()
    elseif block_size == 24 then
        return libcrypto.EVP_aes_192_ecb()
    elseif block_size == 32 then
        return libcrypto.EVP_aes_256_ecb()
    else
        return nil
    end
end

function crypto.get_cipher_block_size(cipher)
    return libcrypto.EVP_CIPHER_block_size(cipher)
end

function crypto.evp_decrypt(cipher, input, key, iv)
    if cipher == nil then
        return nil
    end

    local context = libcrypto.EVP_CIPHER_CTX_new()
    if context == nil then
        return nil
    end

    if libcrypto.EVP_DecryptInit_ex(context, cipher, nil, key, iv) ~= 1 then
        libcrypto.EVP_CIPHER_CTX_free(context)
        return nil
    end

    if libcrypto.EVP_CIPHER_CTX_set_padding(context, 0) ~= 1 then
        libcrypto.EVP_CIPHER_CTX_free(context)
        return nil
    end

    local block_size = crypto.get_cipher_block_size(cipher)
    local output = ffi.new("char[?]", #input + block_size)
    local output_length = ffi.new("int[1]")
    if libcrypto.EVP_DecryptUpdate(context, output, output_length, input, #input) ~= 1 then
        libcrypto.EVP_CIPHER_CTX_free(context)
        return nil
    end

    output_length = output_length[0]
    local final_length = ffi.new("int[1]")
    if libcrypto.EVP_DecryptFinal_ex(context, output + output_length, final_length) ~= 1 then
        libcrypto.EVP_CIPHER_CTX_free(context)
        return nil
    end
    output_length = output_length + final_length[0]

    libcrypto.EVP_CIPHER_CTX_free(context)

    return output, output_length
end

return crypto
