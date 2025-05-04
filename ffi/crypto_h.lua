-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
typedef struct evp_cipher_st EVP_CIPHER;
typedef struct engine_st ENGINE;

int PKCS5_PBKDF2_HMAC_SHA1(const char *, int, const unsigned char *, int, int, int, unsigned char *);
EVP_CIPHER_CTX *EVP_CIPHER_CTX_new();
void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *a);
int EVP_CIPHER_CTX_set_padding(EVP_CIPHER_CTX *c, int pad);
int EVP_CIPHER_block_size(const EVP_CIPHER *cipher);
int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *cipher, ENGINE *impl, const unsigned char *key, const unsigned char *iv);
int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl, const unsigned char *in, int inl);
int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *outm, int *outl);
const EVP_CIPHER *EVP_aes_128_ecb();
const EVP_CIPHER *EVP_aes_192_ecb();
const EVP_CIPHER *EVP_aes_256_ecb();
]]
