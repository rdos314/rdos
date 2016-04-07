/* ====================================================================
 * Copyright (c) 2010 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use is governed by OpenSSL license.
 * ====================================================================
 */

#include "modes.h"

typedef long long i64;
typedef unsigned long long u64;
# define U64(C) C##ULL

typedef unsigned int u32;
typedef unsigned char u8;



# define GETU32(p)       ((u32)(p)[0]<<24|(u32)(p)[1]<<16|(u32)(p)[2]<<8|(u32)(p)[3])
# define PUTU32(p,v)     ((p)[0]=(u8)((v)>>24),(p)[1]=(u8)((v)>>16),(p)[2]=(u8)((v)>>8),(p)[3]=(u8)(v))

/*- GCM definitions */ typedef struct {
    u64 hi, lo;
} u128;

/*
 * Even though permitted values for TABLE_BITS are 8, 4 and 1, it should
 * never be set to 8 [or 1]. For further information see gcm128.c.
 */
#define TABLE_BITS 4

struct gcm128_context {
    /* Following 6 names follow names in GCM specification */
    union {
        u64 u[2];
        u32 d[4];
        u8 c[16];
        size_t t[16 / sizeof(size_t)];
    } Yi, EKi, EK0, len, Xi, H;
    /*
     * Relative position of Xi, H and pre-computed Htable is used in some
     * assembler modules, i.e. don't change the order!
     */
    u128 Htable[16];
    void (*gmult) (u64 Xi[2], const u128 Htable[16]);
    void (*ghash) (u64 Xi[2], const u128 Htable[16], const u8 *inp,
                   size_t len);
    unsigned int mres, ares;
    block128_f block;
    void *key;
};

struct xts128_context {
    void *key1, *key2;
    block128_f block1, block2;
};

struct ccm128_context {
    union {
        u64 u[2];
        u8 c[16];
    } nonce, cmac;
    u64 blocks;
    block128_f block;
    void *key;
};


typedef union {
    u64 a[2];
    unsigned char c[16];
} OCB_BLOCK;

# define ocb_block16_xor(in1,in2,out) \
    ( (out)->a[0]=(in1)->a[0]^(in2)->a[0], \
      (out)->a[1]=(in1)->a[1]^(in2)->a[1] )

#  define ocb_block16_xor_misaligned ocb_block16_xor

struct ocb128_context {
    /* Need both encrypt and decrypt key schedules for decryption */
    block128_f encrypt;
    block128_f decrypt;
    void *keyenc;
    void *keydec;
    ocb128_f stream;    /* direction dependent */
    /* Key dependent variables. Can be reused if key remains the same */
    size_t l_index;
    size_t max_l_index;
    OCB_BLOCK l_star;
    OCB_BLOCK l_dollar;
    OCB_BLOCK *l;
    /* Must be reset for each session */
    u64 blocks_hashed;
    u64 blocks_processed;
    OCB_BLOCK tag;
    OCB_BLOCK offset_aad;
    OCB_BLOCK sum;
    OCB_BLOCK offset;
    OCB_BLOCK checksum;
};
