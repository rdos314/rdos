/*
 * Copyright 2016-2020 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */


#include "rdosdev.h"
#include "rdos.h"
#include <openssl/crypto.h>


int AllocateTls();
#pragma aux AllocateTls value [eax]

void FreeTls(int entry);
#pragma aux FreeTls parm routine [ecx]

void *GetTls(int entry);
#pragma aux GetTls parm routine [ecx] value [dx eax]

void SetTls(int entry, void *val);
#pragma aux SetTls parm routine [ecx] [dx eax]


#if defined(OPENSSL_THREADS) && !defined(CRYPTO_TDEBUG) && defined(OPENSSL_SYS_RDOS)

CRYPTO_RWLOCK *CRYPTO_THREAD_lock_new(void)
{
    CRYPTO_RWLOCK *lock;
    struct TKernelSection *hptr;

    lock = OPENSSL_zalloc(sizeof(struct TKernelSection));
    hptr = (struct TKernelSection *)lock;
    RdosInitKernelSection(hptr);    

    return lock;
}

int CRYPTO_THREAD_read_lock(CRYPTO_RWLOCK *lock)
{
    struct TKernelSection *hptr = (struct TKernelSection *)lock;
    RdosEnterKernelSection(hptr);
    return 1;
}

int CRYPTO_THREAD_write_lock(CRYPTO_RWLOCK *lock)
{
    struct TKernelSection *hptr = (struct TKernelSection *)lock;
    RdosEnterKernelSection(hptr);
    return 1;
}

int CRYPTO_THREAD_unlock(CRYPTO_RWLOCK *lock)
{
    struct TKernelSection *hptr = (struct TKernelSection *)lock;
    RdosLeaveKernelSection(hptr);
    return 1;
}

void CRYPTO_THREAD_lock_free(CRYPTO_RWLOCK *lock)
{
    if (lock == NULL)
        return;

    OPENSSL_free(lock);

    return;
}

#  define ONCE_UNINITED     0
#  define ONCE_ININIT       1
#  define ONCE_DONE         2

int CRYPTO_THREAD_run_once(CRYPTO_ONCE *once, void (*init)(void))
{
    short int flags;

    if (once->state == ONCE_DONE)
        return 1;

    do 
    {
        flags = RdosRequestSpinlock(&once->lock);
            
        if (once->state == ONCE_UNINITED) 
        {
            once->state = ONCE_ININIT;
            once->thread = RdosGetThreadHandle();
            RdosReleaseSpinlock(&once->lock, flags);
            init();
            once->state = ONCE_DONE;
            return 1;
        }
        else
        {
            RdosReleaseSpinlock(&once->lock, flags);

            if (once->state == ONCE_ININIT && once->thread == RdosGetThreadHandle())
                return 1;
            else
                RdosWaitMilli(10);
        }
    } while (once->state == ONCE_ININIT);

    return 1;
}

int CRYPTO_THREAD_init_local(CRYPTO_THREAD_LOCAL *key, void (*cleanup)(void *))
{
    *key = AllocateTls();
    if (*key < 0)
        return 0;

    return 1;
}

void *CRYPTO_THREAD_get_local(CRYPTO_THREAD_LOCAL *key)
{
    return GetTls(*key);
}

int CRYPTO_THREAD_set_local(CRYPTO_THREAD_LOCAL *key, void *val)
{
    SetTls(*key, val);
    return 1;
}

int CRYPTO_THREAD_cleanup_local(CRYPTO_THREAD_LOCAL *key)
{
    FreeTls(*key);
    return 1;
}

CRYPTO_THREAD_ID CRYPTO_THREAD_get_current_id(void)
{
    return RdosGetThreadHandle();
}

int CRYPTO_THREAD_compare_id(CRYPTO_THREAD_ID a, CRYPTO_THREAD_ID b)
{
    return (a == b);
}

int CRYPTO_atomic_add(int *val, int amount, int *ret, CRYPTO_RWLOCK *lock)
{
    *val += amount;
    *ret  = *val;
    return 1;
}

int openssl_init_fork_handlers(void)
{
    return 0;
}

int openssl_get_fork_id(void)
{
    return 0;
}
#endif
