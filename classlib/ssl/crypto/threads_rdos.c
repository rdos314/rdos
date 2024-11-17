/*
 * Copyright 2016-2020 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */


#include "rdos.h"
#include <openssl/crypto.h>

#if defined(OPENSSL_THREADS) && !defined(CRYPTO_TDEBUG) && defined(OPENSSL_SYS_RDOS)

CRYPTO_RWLOCK *CRYPTO_THREAD_lock_new(void)
{
    CRYPTO_RWLOCK *lock;
    struct RdosFutex *hptr;

    lock = OPENSSL_zalloc(sizeof(struct RdosFutex));
    hptr = (struct RdosFutex *)lock;
    RdosInitFutex(hptr, "SSL");

    return lock;
}

int CRYPTO_THREAD_read_lock(CRYPTO_RWLOCK *lock)
{
    struct RdosFutex *hptr = (struct RdosFutex *)lock;
    RdosEnterFutex(hptr);
    return 1;
}

int CRYPTO_THREAD_write_lock(CRYPTO_RWLOCK *lock)
{
    struct RdosFutex *hptr = (struct RdosFutex *)lock;
    RdosEnterFutex(hptr);
    return 1;
}

int CRYPTO_THREAD_unlock(CRYPTO_RWLOCK *lock)
{
    struct RdosFutex *hptr = (struct RdosFutex *)lock;
    RdosLeaveFutex(hptr);
    return 1;
}

void CRYPTO_THREAD_lock_free(CRYPTO_RWLOCK *lock)
{
    struct RdosFutex *hptr = (struct RdosFutex *)lock;

    if (lock == NULL)
        return;

    RdosResetFutex(hptr);
    OPENSSL_free(lock);

    return;
}

#  define ONCE_UNINITED     0
#  define ONCE_ININIT       1
#  define ONCE_DONE         2

int CRYPTO_THREAD_run_once(CRYPTO_ONCE *once, void (*init)(void))
{
    int result;

    if (once->state == ONCE_DONE)
        return 1;

    do
    {
        result = RdosXchg(&once->state, ONCE_ININIT);
        if (result == ONCE_UNINITED)
        {
            once->thread = RdosGetThreadHandle();
            init();
            once->state = ONCE_DONE;
            once->thread = 0;
            return 1;
        }

        if (result == ONCE_ININIT && once->thread == RdosGetThreadHandle())
            return 1;

    } while (result == ONCE_ININIT);

    return (once->state == ONCE_DONE);
}

int CRYPTO_THREAD_init_local(CRYPTO_THREAD_LOCAL *key, void (*cleanup)(void *))
{
    *key = RdosAllocateTls();
    if (*key < 0)
        return 0;

    return 1;
}

void *CRYPTO_THREAD_get_local(CRYPTO_THREAD_LOCAL *key)
{
    return RdosGetTls(*key);
}

int CRYPTO_THREAD_set_local(CRYPTO_THREAD_LOCAL *key, void *val)
{
    RdosSetTls(*key, val);
    return 1;
}

int CRYPTO_THREAD_cleanup_local(CRYPTO_THREAD_LOCAL *key)
{
    RdosFreeTls(*key);
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
