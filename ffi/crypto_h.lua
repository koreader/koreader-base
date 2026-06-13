-- Automatically generated with ffi-cdecl.

require("ffi").cdef[[
typedef struct engine_st ENGINE;
typedef struct evp_cipher_st EVP_CIPHER;
typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
int PKCS5_PBKDF2_HMAC_SHA1(const char *, int, const unsigned char *, int, int, int, unsigned char *);
EVP_CIPHER_CTX *EVP_CIPHER_CTX_new(void);
void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *);
int EVP_CIPHER_CTX_set_padding(EVP_CIPHER_CTX *, int);
int EVP_CIPHER_block_size(const EVP_CIPHER *);
int EVP_DecryptInit_ex(EVP_CIPHER_CTX *, const EVP_CIPHER *, ENGINE *, const unsigned char *, const unsigned char *);
int EVP_DecryptUpdate(EVP_CIPHER_CTX *, unsigned char *, int *, const unsigned char *, int);
int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *, unsigned char *, int *);
const EVP_CIPHER *EVP_aes_128_ecb(void);
const EVP_CIPHER *EVP_aes_192_ecb(void);
const EVP_CIPHER *EVP_aes_256_ecb(void);
]]
