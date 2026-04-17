#ifndef AES_CCM_H
#define AES_CCM_H

#include "string.h"
#include "stdlib.h"

int aes_encrypt_cbc_mac1(const uint8_t in[],      // plaintext
                        int in_len,        // Must be a multiple of AES_BLOCK_SIZE
                        uint8_t out[],           // Output MAC
                        uint8_t key[],     // From the key setup
                        int keysize,          // Bit length of the key, 128, 192, or 256
                        const uint8_t iv[]);     // IV, must be AES_BLOCK_SIZE bytes long

void aes_encrypt_ctr(const uint8_t in[],         // Plaintext
                     int in_len,           // Any byte length
                     uint8_t out[],              // Ciphertext, same length as plaintext
                     const uint8_t key[],        // From the key setup
                     int keysize,             // Bit length of the key, 128, 192, or 256
                     const uint8_t iv[]);        // IV, must be AES_BLOCK_SIZE bytes long

void aes_decrypt_ctr(const uint8_t in[],         // Ciphertext
                     int in_len,           // Any byte length
                     uint8_t out[],              // Plaintext, same length as ciphertext
                     const uint8_t key[],        // From the key setup
                     int keysize,             // Bit length of the key, 128, 192, or 256
                     const uint8_t iv[]);        // IV, must be AES_BLOCK_SIZE bytes long
                     
int aes_encrypt_ccm(const uint8_t plaintext[],              // IN  - Plaintext.
                    int plaintext_len,                  // IN  - Plaintext length.
                    const uint8_t associated_data[],        // IN  - Associated Data included in authentication, but not encryption.
                    unsigned short associated_data_len,  // IN  - Associated Data length in bytes.
                    const uint8_t nonce[],                  // IN  - The Nonce to be used for encryption.
                    unsigned short nonce_len,            // IN  - Nonce length in bytes.
                    uint8_t ciphertext[],                   // OUT - Ciphertext, a concatination of the plaintext and the MAC.
                    int *ciphertext_len,                // OUT - The length of the ciphertext, always plaintext_len + mac_len.
                    int mac_len,                        // IN  - The desired length of the MAC, must be 4, 6, 8, 10, 12, 14, or 16.
                    const uint8_t key[],                    // IN  - The AES key for encryption.
                    int keysize);                        // IN  - The length of the key in bits. Valid values are 128, 192, 256.

int aes_decrypt_ccm(const uint8_t ciphertext[],             // IN  - Ciphertext, the concatination of encrypted plaintext and MAC.
                    int ciphertext_len,                 // IN  - Ciphertext length in bytes.
                    const uint8_t assoc[],                  // IN  - The Associated Data, required for authentication.
                    unsigned short assoc_len,            // IN  - Associated Data length in bytes.
                    const uint8_t nonce[],                  // IN  - The Nonce to use for decryption, same one as for encryption.
                    unsigned short nonce_len,            // IN  - Nonce length in bytes.
                    uint8_t plaintext[],                    // OUT - The plaintext that was decrypted. Will need to be large enough to hold ciphertext_len - mac_len.
                    int *plaintext_len,                 // OUT - Length in bytes of the output plaintext, always ciphertext_len - mac_len .
                    int mac_len,                        // IN  - The length of the MAC that was calculated.
                    int *mac_auth,                       // OUT - TRUE if authentication succeeded, FALSE if it did not. NULL pointer will ignore the authentication.
                    const uint8_t key[],                    // IN  - The AES key for decryption.
                    int keysize);                        // IN  - The length of the key in BITS. Valid values are 128, 192, 256.
                    
#endif //AESWITHPUREC_AES_UTIL_H

