//
//  aes_util.c
//  TestC
//
//  Created by apple on 2022/4/14.
//

#include "aes_util.h"
#include "string.h"
#include "aes_cmac.h"

void cal_sha256(uint8_t *sha256_in, uint8_t len, uint8_t *sha26_out)
{
    struct tc_sha256_state_struct state;
    tc_sha256_init(&state);
    tc_sha256_update(&state, sha256_in, len);
    tc_sha256_final(sha26_out, &state);
    hHex("Key111\t:", sha26_out, 8);
}

void aes_util_cmac (uint8_t *input, unsigned long length, uint8_t *key, uint8_t *mac_value) {
    aes_cmac(input, length, key, mac_value);
}

//int aes_cmac(const uint8_t * const p_key, const uint8_t * const p_msg, uint16_t msg_len, uint8_t * const p_out)
//{
//    struct tc_aes_key_sched_struct sched;
//    struct tc_cmac_struct state;
//
//    if (tc_cmac_setup(&state, p_key, &sched) == 0) {
//        return -1;
//    }
//
//    if (tc_cmac_update(&state, p_msg, msg_len) == 0) {
//        return -1;
//    }
//
//    if (tc_cmac_final(p_out, &state) == 0) {
//        return -1;
//    }
//    hHex("Key\t:ddjdjdjdjjdj:", p_out,8);
//    return 0;
//}

unsigned char *encrypt_ccm(const unsigned char *data, int in_len, int *out_len, const unsigned char *key, int key_size) {
    if (in_len <= 0 || in_len >= MAX_LEN) {
        return NULL;
    }

    if (!data) {
        return NULL;
    }
    // CCM
    int mac_len= 16;
    unsigned char *buff = (unsigned char *) calloc(1, in_len+mac_len);
    unsigned char assoc[12]= {0,0,0,0,0,0,0,0,0,0,0,0};
    unsigned char nonce[12]= {0,0,0,0,0,0,0,0,0,0,0,0};
    aes_encrypt_ccm(data, in_len, assoc, 12, nonce, 12, buff, out_len, mac_len, key, key_size);

    return buff;
}

unsigned char *decrypt_ccm(const unsigned char *data, int in_len, int *out_len, const unsigned char *key, int key_size) {
    if (in_len <= 0 || in_len >= MAX_LEN) {
        return NULL;
    }
    if (!data) {
        return NULL;
    }

    // ccm
    int mac_len= 16;
    int mac_auth;
    unsigned char *buff = (unsigned char *) calloc(1, in_len);
    unsigned char assoc[12]= {0,0,0,0,0,0,0,0,0,0,0,0};
    unsigned char nonce[12]= {0,0,0,0,0,0,0,0,0,0,0,0};
//    printBuf(key, AES_KEY_SIZE/8);
    aes_decrypt_ccm(data, in_len, assoc, 12, nonce, 12, buff, out_len, mac_len, &mac_auth, key, key_size);
    
    return buff;
}

void test(void) {
    uint8_t key[8];
    uint8_t data[8];
    uint8_t randomAA[]= {'A','B','C','D','E','F','G','H'};
    for (int i=0; i<8; i++){
        data[i]= randomAA[i];
    }
    //
    cal_sha256(data, 8, key);
    hHex("Key\t:", key, 8);
}

void hHex(char *word, const uint8_t *data, int len){
    printf("%s:\t",word);
    for (int i=0; i<len; i++){
        printf("%02X ", data[i]);
        printf("\n");
    }
    printf("\n");
}
