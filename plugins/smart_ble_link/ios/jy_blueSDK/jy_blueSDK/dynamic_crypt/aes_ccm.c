#include "stdlib.h"
#include "memory.h"
#include "stdio.h"
#include "aes.h"
#include "aes_ccm.h"

#define TRUE  1
#define FALSE 0

static void xor_buf(const uint8_t in[], uint8_t out[], int len)
{
	int idx;

	for (idx = 0; idx < len; idx++)
		out[idx] ^= in[idx];
}

void increment_iv(uint8_t iv[], int counter_size)
{
	int idx;

	// Use counter_size bytes at the end of the IV as the big-endian integer to increment.
	for (idx = AES_BLOCKSIZE - 1; idx >= AES_BLOCKSIZE - counter_size; idx--) {
		iv[idx]++;
		if (iv[idx] != 0 || idx == AES_BLOCKSIZE - counter_size)
			break;
	}
}

int aes_encrypt_cbc_mac1(const uint8_t in[], int in_len, uint8_t out[],  uint8_t key[], int keysize, const uint8_t iv[])
{
	uint8_t buf_in[AES_BLOCKSIZE], buf_out[AES_BLOCKSIZE], iv_buf[AES_BLOCKSIZE];
	int blocks, idx;
	aes_ctx_t *ctx;

	if (in_len % AES_BLOCKSIZE != 0)
//		return(FALSE);
        return 0;

	ctx = AES_ctx_alloc((uint8_t *)key, keysize/8);
	blocks = in_len / AES_BLOCKSIZE;

	memcpy(iv_buf, iv, AES_BLOCKSIZE);

	for (idx = 0; idx < blocks; idx++) {
		memcpy(buf_in, &in[idx * AES_BLOCKSIZE], AES_BLOCKSIZE);
		xor_buf(iv_buf, buf_in, AES_BLOCKSIZE);
		//aes_encrypt(buf_in, buf_out, key, keysize);
		AES_encrypt(ctx, buf_in, buf_out);
		memcpy(iv_buf, buf_out, AES_BLOCKSIZE);
		// Do not output all encrypted blocks.
	}

	memcpy(out, buf_out, AES_BLOCKSIZE);   // Only output the last block.
	free(ctx);
//	return(TRUE);
    return  1;
}

void aes_encrypt_ctr(const uint8_t in[], int in_len, uint8_t out[], const uint8_t key[], int keysize, const uint8_t iv[])
{
	size_t idx = 0, last_block_length;
	uint8_t iv_buf[AES_BLOCKSIZE], out_buf[AES_BLOCKSIZE];
	aes_ctx_t *ctx;

	if (in != out)
		memcpy(out, in, in_len);

	memcpy(iv_buf, iv, AES_BLOCKSIZE);
	last_block_length = in_len - AES_BLOCKSIZE;

	ctx = AES_ctx_alloc((uint8_t *)key, keysize/8);
	if (in_len > AES_BLOCKSIZE) {
		for (idx = 0; idx < last_block_length; idx += AES_BLOCKSIZE) {
			//aes_encrypt(iv_buf, out_buf, key, keysize);
			AES_encrypt(ctx, iv_buf, out_buf);
			xor_buf(out_buf, &out[idx], AES_BLOCKSIZE);
			increment_iv(iv_buf, AES_BLOCKSIZE);
		}
	}

	//aes_encrypt(iv_buf, out_buf, key, keysize);
	AES_encrypt(ctx, iv_buf, out_buf);
	xor_buf(out_buf, &out[idx], in_len - idx);   // Use the Most Significant bytes.
	free(ctx);
}

void aes_decrypt_ctr(const uint8_t in[], int in_len, uint8_t out[], const uint8_t key[], int keysize, const uint8_t iv[])
{
	// CTR encryption is its own inverse function.
	aes_encrypt_ctr(in, in_len, out, key, keysize, iv);
}

void ccm_prepare_first_format_blk(uint8_t buf[], int assoc_len, int payload_len, int payload_len_store_size, int mac_len, const uint8_t nonce[], int nonce_len)
{
	// Set the flags for the first byte of the first block.
	buf[0] = ((((mac_len - 2) / 2) & 0x07) << 3) | ((payload_len_store_size - 1) & 0x07);
	if (assoc_len > 0)
		buf[0] += 0x40;
	// Format the rest of the first block, storing the nonce and the size of the payload.
	memcpy(&buf[1], nonce, nonce_len);
	memset(&buf[1 + nonce_len], 0, AES_BLOCKSIZE - 1 - nonce_len);
	buf[15] = payload_len & 0x000000FF;
	buf[14] = (payload_len >> 8) & 0x000000FF;
}

void ccm_format_assoc_data(uint8_t buf[], int *end_of_buf, const uint8_t assoc[], int assoc_len)
{
	int pad;

	buf[*end_of_buf + 1] = assoc_len & 0x00FF;
	buf[*end_of_buf] = (assoc_len >> 8) & 0x00FF;
	*end_of_buf += 2;
	memcpy(&buf[*end_of_buf], assoc, assoc_len);
	*end_of_buf += assoc_len;
	pad = *end_of_buf % AES_BLOCKSIZE;
	if (pad != 0)
		pad = AES_BLOCKSIZE - pad;
	//pad = AES_BLOCK_SIZE - (*end_of_buf % AES_BLOCK_SIZE); /*BUG?*/
	memset(&buf[*end_of_buf], 0, pad);
	*end_of_buf += pad;
}

void ccm_format_payload_data(uint8_t buf[], int *end_of_buf, const uint8_t payload[], int payload_len)
{
	int pad;

	memcpy(&buf[*end_of_buf], payload, payload_len);
	*end_of_buf += payload_len;
	pad = *end_of_buf % AES_BLOCKSIZE;
	if (pad != 0)
		pad = AES_BLOCKSIZE - pad;
	memset(&buf[*end_of_buf], 0, pad);
	*end_of_buf += pad;
}

void ccm_prepare_first_ctr_blk(uint8_t counter[], const uint8_t nonce[], int nonce_len, int payload_len_store_size)
{
	memset(counter, 0, AES_BLOCKSIZE);
	counter[0] = (payload_len_store_size - 1) & 0x07;
	memcpy(&counter[1], nonce, nonce_len);
}

int aes_encrypt_ccm(const uint8_t payload[], int payload_len, const uint8_t assoc[], unsigned short assoc_len,
                    const uint8_t nonce[], unsigned short nonce_len, uint8_t out[], int *out_len,
                    int mac_len, const uint8_t key_str[], int keysize)
{
	uint8_t temp_iv[AES_BLOCKSIZE], counter[AES_BLOCKSIZE], mac[16], *buf;
	int end_of_buf, payload_len_store_size;
//	aes_ctx_t *ctx;

	if (mac_len != 4 && mac_len != 6 && mac_len != 8 && mac_len != 10 &&
	   mac_len != 12 && mac_len != 14 && mac_len != 16)
		return(FALSE);

	if (nonce_len < 7 || nonce_len > 13)
		return(FALSE);

	if (assoc_len > 32768 /* = 2^15 */)
		return(FALSE);

	buf = (uint8_t*)malloc(payload_len + assoc_len + 48 /*Round both payload and associated data up a block size and add an extra block.*/);
	if (! buf)
		return(FALSE);

	// Prepare the key for usage.
//	ctx = AES_ctx_alloc((uint8_t *)key_str, keysize);
//	aes_key_setup(key_str, key, keysize);

	// Format the first block of the formatted data.
	payload_len_store_size = AES_BLOCKSIZE - 1 - nonce_len;
	ccm_prepare_first_format_blk(buf, assoc_len, payload_len, payload_len_store_size, mac_len, nonce, nonce_len);
	end_of_buf = AES_BLOCKSIZE;

	// Format the Associated Data, aka, assoc[].
	ccm_format_assoc_data(buf, &end_of_buf, assoc, assoc_len);

	// Format the Payload, aka payload[].
	ccm_format_payload_data(buf, &end_of_buf, payload, payload_len);

	// Create the first counter block.
	ccm_prepare_first_ctr_blk(counter, nonce, nonce_len, payload_len_store_size);

	// Perform the CBC operation with an IV of zeros on the formatted buffer to calculate the MAC.
	memset(temp_iv, 0, AES_BLOCKSIZE);
	aes_encrypt_cbc_mac1(buf, end_of_buf, mac, key_str, keysize, temp_iv);

	// Copy the Payload and MAC to the output buffer.
	memcpy(out, payload, payload_len);
	memcpy(&out[payload_len], mac, mac_len);

	// Encrypt the Payload with CTR mode with a counter starting at 1.
	memcpy(temp_iv, counter, AES_BLOCKSIZE);
	temp_iv[15]= 1;
//	increment_iv(temp_iv, AES_BLOCK_SIZE - 1 - mac_len);   // Last argument is the byte size of the counting portion of the counter block. /*BUG?*/
	aes_encrypt_ctr(out, payload_len, out, key_str, keysize, temp_iv);

	// Encrypt the MAC with CTR mode with a counter starting at 0.
	aes_encrypt_ctr(&out[payload_len], mac_len, &out[payload_len], key_str, keysize, counter);

	free(buf);
	*out_len = payload_len + mac_len;

	return(TRUE);
}

int aes_decrypt_ccm(const uint8_t ciphertext[], int ciphertext_len, const uint8_t assoc[], unsigned short assoc_len,
                    const uint8_t nonce[], unsigned short nonce_len, uint8_t plaintext[], int *plaintext_len,
                    int mac_len, int *mac_auth, const uint8_t key_str[], int keysize)
{
	uint8_t temp_iv[AES_BLOCKSIZE], counter[AES_BLOCKSIZE], mac[16], mac_buf[16], *buf;
	int end_of_buf, plaintext_len_store_size;

	if (ciphertext_len <= mac_len)
		return(FALSE);

	buf = (uint8_t*)malloc(assoc_len + ciphertext_len /*ciphertext_len = plaintext_len + mac_len*/ + 48);
	if (! buf)
		return(FALSE);

	// Prepare the key for usage.
	//aes_key_setup(key_str, key, keysize);

	// Copy the plaintext and MAC to the output buffers.
	*plaintext_len = ciphertext_len - mac_len;
	plaintext_len_store_size = AES_BLOCKSIZE - 1 - nonce_len;
	memcpy(plaintext, ciphertext, *plaintext_len);
	memcpy(mac, &ciphertext[*plaintext_len], mac_len);

	// Prepare the first counter block for use in decryption.
	ccm_prepare_first_ctr_blk(counter, nonce, nonce_len, plaintext_len_store_size);

	// Decrypt the Payload with CTR mode with a counter starting at 1.
	memcpy(temp_iv, counter, AES_BLOCKSIZE);
	temp_iv[15]= 1;
//	increment_iv(temp_iv, AES_BLOCK_SIZE - 1 - mac_len);   // (AES_BLOCK_SIZE - 1 - mac_len) is the byte size of the counting portion of the counter block.
	aes_decrypt_ctr(plaintext, *plaintext_len, plaintext, key_str, keysize, temp_iv);

	// Setting mac_auth to NULL disables the authentication check.
	if (mac_auth != NULL) {
		// Decrypt the MAC with CTR mode with a counter starting at 0.
		aes_decrypt_ctr(mac, mac_len, mac, key_str, keysize, counter);

		// Format the first block of the formatted data.
		plaintext_len_store_size = AES_BLOCKSIZE - 1 - nonce_len;
		ccm_prepare_first_format_blk(buf, assoc_len, *plaintext_len, plaintext_len_store_size, mac_len, nonce, nonce_len);
		end_of_buf = AES_BLOCKSIZE;

		// Format the Associated Data into the authentication buffer.
		ccm_format_assoc_data(buf, &end_of_buf, assoc, assoc_len);

		// Format the Payload into the authentication buffer.
		ccm_format_payload_data(buf, &end_of_buf, plaintext, *plaintext_len);

		// Perform the CBC operation with an IV of zeros on the formatted buffer to calculate the MAC.
		memset(temp_iv, 0, AES_BLOCKSIZE);
		aes_encrypt_cbc_mac1(buf, end_of_buf, mac_buf, key_str, keysize, temp_iv);

		// Compare the calculated MAC against the MAC embedded in the ciphertext to see if they are the same.
		if (! memcmp(mac, mac_buf, mac_len)) {
			*mac_auth = TRUE;
		}
		else {
			*mac_auth = FALSE;
			memset(plaintext, 0, *plaintext_len);
		}
	}

	free(buf);

	return(TRUE);
}

