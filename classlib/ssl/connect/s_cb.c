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

VERIFY_CB_ARGS verify_args = { -1, 0, X509_V_OK, 0 };

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

static void nodes_print(const char *name, STACK_OF(X509_POLICY_NODE) *nodes)
{
    X509_POLICY_NODE *node;
    int i;

    BIO_printf(bio_err, "%s Policies:", name);
    if (nodes) {
        BIO_puts(bio_err, "\n");
        for (i = 0; i < sk_X509_POLICY_NODE_num(nodes); i++) {
            node = sk_X509_POLICY_NODE_value(nodes, i);
            X509_POLICY_NODE_print(bio_err, node, 2);
        }
    } else {
        BIO_puts(bio_err, " <empty>\n");
    }
}


static void policies_print(X509_STORE_CTX *ctx)
{
    X509_POLICY_TREE *tree;
    int explicit_policy;
    tree = X509_STORE_CTX_get0_policy_tree(ctx);
    explicit_policy = X509_STORE_CTX_get_explicit_policy(ctx);

    BIO_printf(bio_err, "Require explicit Policy: %s\n",
               explicit_policy ? "True" : "False");

    nodes_print("Authority", X509_policy_tree_get0_policies(tree));
    nodes_print("User", X509_policy_tree_get0_user_policies(tree));
}

int verify_callback(int ok, X509_STORE_CTX *ctx)
{
    X509 *err_cert;
    int err, depth;

    err_cert = X509_STORE_CTX_get_current_cert(ctx);
    err = X509_STORE_CTX_get_error(ctx);
    depth = X509_STORE_CTX_get_error_depth(ctx);

    if (!verify_args.quiet || !ok) {
        BIO_printf(bio_err, "depth=%d ", depth);
        if (err_cert != NULL) {
            X509_NAME_print_ex(bio_err,
                               X509_get_subject_name(err_cert),
                               0, get_nameopt());
            BIO_puts(bio_err, "\n");
        } else {
            BIO_puts(bio_err, "<no cert>\n");
        }
    }
    if (!ok) {
        BIO_printf(bio_err, "verify error:num=%d:%s\n", err,
                   X509_verify_cert_error_string(err));
        if (verify_args.depth < 0 || verify_args.depth >= depth) {
            if (!verify_args.return_error)
                ok = 1;
            verify_args.error = err;
        } else {
            ok = 0;
            verify_args.error = X509_V_ERR_CERT_CHAIN_TOO_LONG;
        }
    }
    switch (err) {
    case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT:
        BIO_puts(bio_err, "issuer= ");
        X509_NAME_print_ex(bio_err, X509_get_issuer_name(err_cert),
                           0, get_nameopt());
        BIO_puts(bio_err, "\n");
        break;
    case X509_V_ERR_CERT_NOT_YET_VALID:
    case X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD:
        BIO_printf(bio_err, "notBefore=");
        ASN1_TIME_print(bio_err, X509_get0_notBefore(err_cert));
        BIO_printf(bio_err, "\n");
        break;
    case X509_V_ERR_CERT_HAS_EXPIRED:
    case X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD:
        BIO_printf(bio_err, "notAfter=");
        ASN1_TIME_print(bio_err, X509_get0_notAfter(err_cert));
        BIO_printf(bio_err, "\n");
        break;
    case X509_V_ERR_NO_EXPLICIT_POLICY:
        if (!verify_args.quiet)
            policies_print(ctx);
        break;
    }
    if (err == X509_V_OK && ok == 2 && !verify_args.quiet)
        policies_print(ctx);
    if (ok && !verify_args.quiet)
        BIO_printf(bio_err, "verify return:%d\n", ok);
    return ok;
}

