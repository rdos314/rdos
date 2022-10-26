/*
 * Copyright 1995-2021 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

/* callback functions used by s_client, s_server, and s_time */
#include <stdio.h>
#include <stdlib.h>
#include <string.h> /* for memcpy() and strcmp() */
#include "apps.h"
#include <openssl/err.h>
#include <openssl/rand.h>
#include <openssl/x509.h>
#include <openssl/ssl.h>
#include <openssl/bn.h>
# include <openssl/dh.h>
#include "s_apps.h"

#define COOKIE_SECRET_LENGTH    16


static unsigned char cookie_secret[COOKIE_SECRET_LENGTH];
static int cookie_initialized = 0;
static BIO *bio_keylog = NULL;

static const char *lookup(int val, const STRINT_PAIR* list, const char* def)
{
    for ( ; list->name; ++list)
        if (list->retval == val)
            return list->name;
    return def;
}

