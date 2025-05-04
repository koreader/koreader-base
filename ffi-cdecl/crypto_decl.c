#include <openssl/evp.h>

#include "ffi-cdecl.h"

cdecl_func(PKCS5_PBKDF2_HMAC_SHA1)
cdecl_func(EVP_CIPHER_CTX_new);
cdecl_func(EVP_CIPHER_CTX_free);
cdecl_func(EVP_CIPHER_CTX_set_padding);
cdecl_func(EVP_CIPHER_block_size);
cdecl_func(EVP_DecryptInit_ex);
cdecl_func(EVP_DecryptUpdate);
cdecl_func(EVP_DecryptFinal_ex);
cdecl_func(EVP_aes_128_ecb);
cdecl_func(EVP_aes_192_ecb);
cdecl_func(EVP_aes_256_ecb);
