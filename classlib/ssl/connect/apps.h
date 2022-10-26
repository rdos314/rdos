/*
 * Copyright 1995-2019 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#ifndef OSSL_APPS_H
# define OSSL_APPS_H

# include "e_os.h" /* struct timeval for DTLS */
# include "internal/nelem.h"
# include <assert.h>

# include <sys/types.h>
#  include <sys/stat.h>
#  include <fcntl.h>

# include <openssl/e_os2.h>
# include <openssl/ossl_typ.h>
# include <openssl/bio.h>
# include <openssl/x509.h>
# include <openssl/conf.h>
# include <openssl/txt_db.h>
# include <openssl/engine.h>
# include <openssl/ocsp.h>
# include <signal.h>

#  define openssl_fdset(a,b) FD_SET(a, b)

/*
 * quick macro when you need to pass an unsigned char instead of a char.
 * this is true for some implementations of the is*() functions, for
 * example.
 */
#define _UC(c) ((unsigned char)(c))


#define IS_NO_PROT_FLAG(o) \
 (o == OPT_S_NOSSL3 || o == OPT_S_NOTLS1 || o == OPT_S_NOTLS1_1 \
  || o == OPT_S_NOTLS1_2 || o == OPT_S_NOTLS1_3)


#endif
