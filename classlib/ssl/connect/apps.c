/*
 * Copyright 1995-2022 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
# include <sys/stat.h>
# include <fcntl.h>
#include <ctype.h>
#include <errno.h>
#include <openssl/err.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pem.h>
#include <openssl/pkcs12.h>
#include <openssl/ui.h>
#include <openssl/safestack.h>
# include <openssl/engine.h>
# include <openssl/rsa.h>
#include <openssl/bn.h>
#include <openssl/ssl.h>
#include "apps.h"

typedef struct {
    const char *name;
    unsigned long flag;
    unsigned long mask;
} NAME_EX_TBL;

static UI_METHOD *ui_method = NULL;
static const UI_METHOD *ui_fallback_method = NULL;

void* app_malloc(int sz, const char *what)
{
    void *vp = OPENSSL_malloc(sz);

    if (vp == NULL) {
        BIO_printf(bio_err, "%s: Could not allocate %d bytes for %s\n",
                opt_getprog(), sz, what);
        ERR_print_errors(bio_err);
        exit(1);
    }
    return vp;
}

