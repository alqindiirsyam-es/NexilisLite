// Production note: disabled AES mode declarations and legacy scaffolding were removed to document the active configuration only.

#ifndef _AES_H_
#define _AES_H_

// CBC remains the active AES mode used by this SDK wrapper.
#ifndef CBC
#define CBC 1
#endif

#define AES256 1
#define AES_BLOCKLEN 16

#if defined(AES256) && (AES256 == 1)
#define AES_KEYLEN 32
#define AES_keyExpSize 240
#endif

void initCND(void);
uint16_t abN(uint8_t *inpBytes, const uint16_t nInpLen, uint8_t *outBytes, uint8_t *aUint8Key);
uint16_t abD(uint8_t *inpBytes, const uint16_t nInpLen, uint8_t *outBytes, uint8_t *aUint8Key, const uint8_t nRemoveTI);

#endif //_AES_H_
