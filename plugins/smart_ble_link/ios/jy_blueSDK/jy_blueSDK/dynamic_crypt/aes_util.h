//
//  aes_util.h
//  TestC
//
//  Created by apple on 2022/4/14.
//

#ifndef aes_util_h
#define aes_util_h
#include "stdint.h"
#include "string.h"
#include "stdio.h"
#include "stdlib.h"

#include "aes.h"
#include "aes_cbc.h"
#include "aes_cmac.h"
#include "aes_ccm.h"
#include "sha256.h"

#include "aes_ccm.h"
void cal_sha256(uint8_t *sha256_in, uint8_t len, uint8_t *sha26_out);
void aes_util_cmac (uint8_t *input, unsigned long length, uint8_t *key, uint8_t *mac_value);
void test(void);
void hHex(char *word, const uint8_t *data, int len);
//void aes_encrypt(const uint8_t *dataIn, int inLen, uint8_t *dataOut, int outLen, const uint8_t *key);
//void aes_decrypt(const uint8_t *dataIn, int inLen, uint8_t *dataOut, int outLen, const uint8_t *key);
unsigned char *encrypt_ccm(const unsigned char *data, int in_len, int *out_len, const unsigned char *key, int key_size);
unsigned char *decrypt_ccm(const unsigned char *data, int in_len, int *out_len, const unsigned char *key, int key_size);

#endif /* aes_util_h */
