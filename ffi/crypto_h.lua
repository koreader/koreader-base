-- Automatically generated with ffi-cdecl.

local ffi = require("ffi")

ffi.cdef[[
int PKCS5_PBKDF2_HMAC_SHA1(const char *, int, const unsigned char *, int, int, int, unsigned char *);
struct evp_cipher_ctx_st *EVP_CIPHER_CTX_new(void);
void EVP_CIPHER_CTX_free(struct evp_cipher_ctx_st *);
int EVP_CIPHER_CTX_set_padding(struct evp_cipher_ctx_st *, int);
int EVP_CIPHER_block_size(const struct evp_cipher_st *);
int EVP_DecryptInit_ex(struct evp_cipher_ctx_st *, const struct evp_cipher_st *, struct engine_st *, const unsigned char *, const unsigned char *);
int EVP_DecryptUpdate(struct evp_cipher_ctx_st *, unsigned char *, int *, const unsigned char *, int);
int EVP_DecryptFinal_ex(struct evp_cipher_ctx_st *, unsigned char *, int *);
const struct evp_cipher_st *EVP_aes_128_ecb(void);
const struct evp_cipher_st *EVP_aes_192_ecb(void);
const struct evp_cipher_st *EVP_aes_256_ecb(void);
]]
