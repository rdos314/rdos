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

void app_RAND_load_conf(CONF *c, const char *section);
void app_RAND_write(void);

extern char *default_config_file;
extern BIO *bio_in;
extern BIO *bio_out;
extern BIO *bio_err;
extern const unsigned char tls13_aes128gcmsha256_id[];
extern const unsigned char tls13_aes256gcmsha384_id[];
extern BIO_ADDR *ourpeer;

BIO_METHOD *apps_bf_prefix(void);
/*
 * The control used to set the prefix with BIO_ctrl()
 * We make it high enough so the chance of ever clashing with the BIO library
 * remains unlikely for the foreseeable future and beyond.
 */
#define PREFIX_CTRL_SET_PREFIX  (1 << 15)
/*
 * apps_bf_prefix() returns a dynamically created BIO_METHOD, which we
 * need to destroy at some point.  When created internally, it's stored
 * in an internal pointer which can be freed with the following function
 */
void destroy_prefix_method(void);


#define IS_NO_PROT_FLAG(o) \
 (o == OPT_S_NOSSL3 || o == OPT_S_NOTLS1 || o == OPT_S_NOTLS1_1 \
  || o == OPT_S_NOTLS1_2 || o == OPT_S_NOTLS1_3)



/*
 * A string/int pairing; widely use for option value lookup, hence the
 * name OPT_PAIR. But that name is misleading in s_cb.c, so we also use
 * the "generic" name STRINT_PAIR.
 */
typedef struct string_int_pair_st {
    const char *name;
    int retval;
} OPT_PAIR, STRINT_PAIR;

typedef struct args_st {
    int size;
    int argc;
    char **argv;
} ARGS;



# define PW_MIN_LENGTH 4
typedef struct pw_cb_data {
    const void *password;
    const char *prompt_info;
} PW_CB_DATA;

/*
 * Sets the file to load the Certificate Transparency log list from.
 * If path is NULL, loads from the default file path.
 * Returns 1 on success, 0 otherwise.
 */
__owur int ctx_set_ctlog_list_file(SSL_CTX *ctx, const char *path);

OCSP_RESPONSE *process_responder(OCSP_REQUEST *req,
                                 const char *host, const char *path,
                                 const char *port, int use_ssl,
                                 STACK_OF(CONF_VALUE) *headers,
                                 int req_timeout);



extern char *psk_key;

/* See OPT_FMT_xxx, above. */
/* On some platforms, it's important to distinguish between text and binary
 * files.  On some, there might even be specific file formats for different
 * contents.  The FORMAT_xxx macros are meant to express an intent with the
 * file being read or created.
 */
# define B_FORMAT_TEXT   0x8000
# define FORMAT_UNDEF    0
# define FORMAT_TEXT    (1 | B_FORMAT_TEXT)     /* Generic text */
# define FORMAT_BINARY   2                      /* Generic binary */
# define FORMAT_BASE64  (3 | B_FORMAT_TEXT)     /* Base64 */
# define FORMAT_ASN1     4                      /* ASN.1/DER */
# define FORMAT_PEM     (5 | B_FORMAT_TEXT)
# define FORMAT_PKCS12   6
# define FORMAT_SMIME   (7 | B_FORMAT_TEXT)
# define FORMAT_ENGINE   8                      /* Not really a file format */
# define FORMAT_PEMRSA  (9 | B_FORMAT_TEXT)     /* PEM RSAPubicKey format */
# define FORMAT_ASN1RSA  10                     /* DER RSAPubicKey format */
# define FORMAT_MSBLOB   11                     /* MS Key blob format */
# define FORMAT_PVK      12                     /* MS PVK file format */
# define FORMAT_HTTP     13                     /* Download using HTTP */
# define FORMAT_NSS      14                     /* NSS keylog format */

typedef struct verify_options_st {
    int depth;
    int quiet;
    int error;
    int return_error;
} VERIFY_CB_ARGS;

extern VERIFY_CB_ARGS verify_args;

#endif
