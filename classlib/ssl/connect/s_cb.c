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

static STRINT_PAIR cert_type_list[] = {
    {"RSA sign", TLS_CT_RSA_SIGN},
    {"DSA sign", TLS_CT_DSS_SIGN},
    {"RSA fixed DH", TLS_CT_RSA_FIXED_DH},
    {"DSS fixed DH", TLS_CT_DSS_FIXED_DH},
    {"ECDSA sign", TLS_CT_ECDSA_SIGN},
    {"RSA fixed ECDH", TLS_CT_RSA_FIXED_ECDH},
    {"ECDSA fixed ECDH", TLS_CT_ECDSA_FIXED_ECDH},
    {"GOST01 Sign", TLS_CT_GOST01_SIGN},
    {"GOST12 Sign", TLS_CT_GOST12_SIGN},
    {NULL}
};

static void ssl_print_client_cert_types(BIO *bio, SSL *s)
{
    const unsigned char *p;
    int i;
    int cert_type_num = SSL_get0_certificate_types(s, &p);
    if (!cert_type_num)
        return;
    BIO_puts(bio, "Client Certificate Types: ");
    for (i = 0; i < cert_type_num; i++) {
        unsigned char cert_type = p[i];
        const char *cname = lookup((int)cert_type, cert_type_list, NULL);

        if (i)
            BIO_puts(bio, ", ");
        if (cname != NULL)
            BIO_puts(bio, cname);
        else
            BIO_printf(bio, "UNKNOWN (%d),", cert_type);
    }
    BIO_puts(bio, "\n");
}

int ssl_print_point_formats(BIO *out, SSL *s)
{
    int i, nformats;
    const char *pformats;
    nformats = SSL_get0_ec_point_formats(s, &pformats);
    if (nformats <= 0)
        return 1;
    BIO_puts(out, "Supported Elliptic Curve Point Formats: ");
    for (i = 0; i < nformats; i++, pformats++) {
        if (i)
            BIO_puts(out, ":");
        switch (*pformats) {
        case TLSEXT_ECPOINTFORMAT_uncompressed:
            BIO_puts(out, "uncompressed");
            break;

        case TLSEXT_ECPOINTFORMAT_ansiX962_compressed_prime:
            BIO_puts(out, "ansiX962_compressed_prime");
            break;

        case TLSEXT_ECPOINTFORMAT_ansiX962_compressed_char2:
            BIO_puts(out, "ansiX962_compressed_char2");
            break;

        default:
            BIO_printf(out, "unknown(%d)", (int)*pformats);
            break;

        }
    }
    BIO_puts(out, "\n");
    return 1;
}

int ssl_print_groups(BIO *out, SSL *s, int noshared)
{
    int i, ngroups, *groups, nid;
    const char *gname;

    ngroups = SSL_get1_groups(s, NULL);
    if (ngroups <= 0)
        return 1;
    groups = OPENSSL_malloc(ngroups * sizeof(int));
    SSL_get1_groups(s, groups);

    BIO_puts(out, "Supported Elliptic Groups: ");
    for (i = 0; i < ngroups; i++) {
        if (i)
            BIO_puts(out, ":");
        nid = groups[i];
        /* If unrecognised print out hex version */
        if (nid & TLSEXT_nid_unknown) {
            BIO_printf(out, "0x%04X", nid & 0xFFFF);
        } else {
            /* TODO(TLS1.3): Get group name here */
            /* Use NIST name for curve if it exists */
            gname = EC_curve_nid2nist(nid);
            if (gname == NULL)
                gname = OBJ_nid2sn(nid);
            BIO_printf(out, "%s", gname);
        }
    }
    OPENSSL_free(groups);
    if (noshared) {
        BIO_puts(out, "\n");
        return 1;
    }
    BIO_puts(out, "\nShared Elliptic groups: ");
    ngroups = SSL_get_shared_group(s, -1);
    for (i = 0; i < ngroups; i++) {
        if (i)
            BIO_puts(out, ":");
        nid = SSL_get_shared_group(s, i);
        /* TODO(TLS1.3): Convert for DH groups */
        gname = EC_curve_nid2nist(nid);
        if (gname == NULL)
            gname = OBJ_nid2sn(nid);
        BIO_printf(out, "%s", gname);
    }
    if (ngroups == 0)
        BIO_puts(out, "NONE");
    BIO_puts(out, "\n");
    return 1;
}

int ssl_print_tmp_key(BIO *out, SSL *s)
{
    EVP_PKEY *key;

    if (!SSL_get_peer_tmp_key(s, &key))
        return 1;
    BIO_puts(out, "Server Temp Key: ");
    switch (EVP_PKEY_id(key)) {
    case EVP_PKEY_RSA:
        BIO_printf(out, "RSA, %d bits\n", EVP_PKEY_bits(key));
        break;

    case EVP_PKEY_DH:
        BIO_printf(out, "DH, %d bits\n", EVP_PKEY_bits(key));
        break;
    case EVP_PKEY_EC:
        {
            EC_KEY *ec = EVP_PKEY_get1_EC_KEY(key);
            int nid;
            const char *cname;
            nid = EC_GROUP_get_curve_name(EC_KEY_get0_group(ec));
            EC_KEY_free(ec);
            cname = EC_curve_nid2nist(nid);
            if (cname == NULL)
                cname = OBJ_nid2sn(nid);
            BIO_printf(out, "ECDH, %s, %d bits\n", cname, EVP_PKEY_bits(key));
        }
    break;
    default:
        BIO_printf(out, "%s, %d bits\n", OBJ_nid2sn(EVP_PKEY_id(key)),
                   EVP_PKEY_bits(key));
    }
    EVP_PKEY_free(key);
    return 1;
}

long bio_dump_callback(BIO *bio, int cmd, const char *argp,
                       int argi, long argl, long ret)
{
    BIO *out;

    out = (BIO *)BIO_get_callback_arg(bio);
    if (out == NULL)
        return ret;

    if (cmd == (BIO_CB_READ | BIO_CB_RETURN)) {
        BIO_printf(out, "read from %p [%p] (%lu bytes => %ld (0x%lX))\n",
                   (void *)bio, (void *)argp, (unsigned long)argi, ret, ret);
        BIO_dump(out, argp, (int)ret);
        return ret;
    } else if (cmd == (BIO_CB_WRITE | BIO_CB_RETURN)) {
        BIO_printf(out, "write to %p [%p] (%lu bytes => %ld (0x%lX))\n",
                   (void *)bio, (void *)argp, (unsigned long)argi, ret, ret);
        BIO_dump(out, argp, (int)ret);
    }
    return ret;
}


static STRINT_PAIR ssl_versions[] = {
    {"SSL 3.0", SSL3_VERSION},
    {"TLS 1.0", TLS1_VERSION},
    {"TLS 1.1", TLS1_1_VERSION},
    {"TLS 1.2", TLS1_2_VERSION},
    {"TLS 1.3", TLS1_3_VERSION},
    {"DTLS 1.0", DTLS1_VERSION},
    {"DTLS 1.0 (bad)", DTLS1_BAD_VER},
    {NULL}
};

static STRINT_PAIR alert_types[] = {
    {" close_notify", 0},
    {" end_of_early_data", 1},
    {" unexpected_message", 10},
    {" bad_record_mac", 20},
    {" decryption_failed", 21},
    {" record_overflow", 22},
    {" decompression_failure", 30},
    {" handshake_failure", 40},
    {" bad_certificate", 42},
    {" unsupported_certificate", 43},
    {" certificate_revoked", 44},
    {" certificate_expired", 45},
    {" certificate_unknown", 46},
    {" illegal_parameter", 47},
    {" unknown_ca", 48},
    {" access_denied", 49},
    {" decode_error", 50},
    {" decrypt_error", 51},
    {" export_restriction", 60},
    {" protocol_version", 70},
    {" insufficient_security", 71},
    {" internal_error", 80},
    {" inappropriate_fallback", 86},
    {" user_canceled", 90},
    {" no_renegotiation", 100},
    {" missing_extension", 109},
    {" unsupported_extension", 110},
    {" certificate_unobtainable", 111},
    {" unrecognized_name", 112},
    {" bad_certificate_status_response", 113},
    {" bad_certificate_hash_value", 114},
    {" unknown_psk_identity", 115},
    {" certificate_required", 116},
    {NULL}
};

static STRINT_PAIR handshakes[] = {
    {", HelloRequest", SSL3_MT_HELLO_REQUEST},
    {", ClientHello", SSL3_MT_CLIENT_HELLO},
    {", ServerHello", SSL3_MT_SERVER_HELLO},
    {", HelloVerifyRequest", DTLS1_MT_HELLO_VERIFY_REQUEST},
    {", NewSessionTicket", SSL3_MT_NEWSESSION_TICKET},
    {", EndOfEarlyData", SSL3_MT_END_OF_EARLY_DATA},
    {", EncryptedExtensions", SSL3_MT_ENCRYPTED_EXTENSIONS},
    {", Certificate", SSL3_MT_CERTIFICATE},
    {", ServerKeyExchange", SSL3_MT_SERVER_KEY_EXCHANGE},
    {", CertificateRequest", SSL3_MT_CERTIFICATE_REQUEST},
    {", ServerHelloDone", SSL3_MT_SERVER_DONE},
    {", CertificateVerify", SSL3_MT_CERTIFICATE_VERIFY},
    {", ClientKeyExchange", SSL3_MT_CLIENT_KEY_EXCHANGE},
    {", Finished", SSL3_MT_FINISHED},
    {", CertificateUrl", SSL3_MT_CERTIFICATE_URL},
    {", CertificateStatus", SSL3_MT_CERTIFICATE_STATUS},
    {", SupplementalData", SSL3_MT_SUPPLEMENTAL_DATA},
    {", KeyUpdate", SSL3_MT_KEY_UPDATE},
    {", NextProto", SSL3_MT_NEXT_PROTO},
    {", MessageHash", SSL3_MT_MESSAGE_HASH},
    {NULL}
};

void msg_cb(int write_p, int version, int content_type, const void *buf,
            size_t len, SSL *ssl, void *arg)
{
    BIO *bio = arg;
    const char *str_write_p = write_p ? ">>>" : "<<<";
    const char *str_version = lookup(version, ssl_versions, "???");
    const char *str_content_type = "", *str_details1 = "", *str_details2 = "";
    const unsigned char* bp = buf;

    if (version == SSL3_VERSION ||
        version == TLS1_VERSION ||
        version == TLS1_1_VERSION ||
        version == TLS1_2_VERSION ||
        version == TLS1_3_VERSION ||
        version == DTLS1_VERSION || version == DTLS1_BAD_VER) {
        switch (content_type) {
        case 20:
            str_content_type = ", ChangeCipherSpec";
            break;
        case 21:
            str_content_type = ", Alert";
            str_details1 = ", ???";
            if (len == 2) {
                switch (bp[0]) {
                case 1:
                    str_details1 = ", warning";
                    break;
                case 2:
                    str_details1 = ", fatal";
                    break;
                }
                str_details2 = lookup((int)bp[1], alert_types, " ???");
            }
            break;
        case 22:
            str_content_type = ", Handshake";
            str_details1 = "???";
            if (len > 0)
                str_details1 = lookup((int)bp[0], handshakes, "???");
            break;
        case 23:
            str_content_type = ", ApplicationData";
            break;
        }
    }

    BIO_printf(bio, "%s %s%s [length %04lx]%s%s\n", str_write_p, str_version,
               str_content_type, (unsigned long)len, str_details1,
               str_details2);

    if (len > 0) {
        size_t num, i;

        BIO_printf(bio, "   ");
        num = len;
        for (i = 0; i < num; i++) {
            if (i % 16 == 0 && i > 0)
                BIO_printf(bio, "\n   ");
            BIO_printf(bio, " %02x", ((const unsigned char *)buf)[i]);
        }
        if (i < len)
            BIO_printf(bio, " ...");
        BIO_printf(bio, "\n");
    }
    (void)BIO_flush(bio);
}

static STRINT_PAIR tlsext_types[] = {
    {"server name", TLSEXT_TYPE_server_name},
    {"max fragment length", TLSEXT_TYPE_max_fragment_length},
    {"client certificate URL", TLSEXT_TYPE_client_certificate_url},
    {"trusted CA keys", TLSEXT_TYPE_trusted_ca_keys},
    {"truncated HMAC", TLSEXT_TYPE_truncated_hmac},
    {"status request", TLSEXT_TYPE_status_request},
    {"user mapping", TLSEXT_TYPE_user_mapping},
    {"client authz", TLSEXT_TYPE_client_authz},
    {"server authz", TLSEXT_TYPE_server_authz},
    {"cert type", TLSEXT_TYPE_cert_type},
    {"supported_groups", TLSEXT_TYPE_supported_groups},
    {"EC point formats", TLSEXT_TYPE_ec_point_formats},
    {"SRP", TLSEXT_TYPE_srp},
    {"signature algorithms", TLSEXT_TYPE_signature_algorithms},
    {"use SRTP", TLSEXT_TYPE_use_srtp},
    {"heartbeat", TLSEXT_TYPE_heartbeat},
    {"session ticket", TLSEXT_TYPE_session_ticket},
    {"renegotiation info", TLSEXT_TYPE_renegotiate},
    {"signed certificate timestamps", TLSEXT_TYPE_signed_certificate_timestamp},
    {"TLS padding", TLSEXT_TYPE_padding},
    {"key share", TLSEXT_TYPE_key_share},
    {"supported versions", TLSEXT_TYPE_supported_versions},
    {"psk", TLSEXT_TYPE_psk},
    {"psk kex modes", TLSEXT_TYPE_psk_kex_modes},
    {"certificate authorities", TLSEXT_TYPE_certificate_authorities},
    {"post handshake auth", TLSEXT_TYPE_post_handshake_auth},
    {NULL}
};

/* from rfc8446 4.2.3. + gost (https://tools.ietf.org/id/draft-smyshlyaev-tls12-gost-suites-04.html) */
static STRINT_PAIR signature_tls13_scheme_list[] = {
    {"rsa_pkcs1_sha1",         0x0201 /* TLSEXT_SIGALG_rsa_pkcs1_sha1 */},
    {"ecdsa_sha1",             0x0203 /* TLSEXT_SIGALG_ecdsa_sha1 */},
/*  {"rsa_pkcs1_sha224",       0x0301    TLSEXT_SIGALG_rsa_pkcs1_sha224}, not in rfc8446 */
/*  {"ecdsa_sha224",           0x0303    TLSEXT_SIGALG_ecdsa_sha224}      not in rfc8446 */
    {"rsa_pkcs1_sha256",       0x0401 /* TLSEXT_SIGALG_rsa_pkcs1_sha256 */},
    {"ecdsa_secp256r1_sha256", 0x0403 /* TLSEXT_SIGALG_ecdsa_secp256r1_sha256 */},
    {"rsa_pkcs1_sha384",       0x0501 /* TLSEXT_SIGALG_rsa_pkcs1_sha384 */},
    {"ecdsa_secp384r1_sha384", 0x0503 /* TLSEXT_SIGALG_ecdsa_secp384r1_sha384 */},
    {"rsa_pkcs1_sha512",       0x0601 /* TLSEXT_SIGALG_rsa_pkcs1_sha512 */},
    {"ecdsa_secp521r1_sha512", 0x0603 /* TLSEXT_SIGALG_ecdsa_secp521r1_sha512 */},
    {"rsa_pss_rsae_sha256",    0x0804 /* TLSEXT_SIGALG_rsa_pss_rsae_sha256 */},
    {"rsa_pss_rsae_sha384",    0x0805 /* TLSEXT_SIGALG_rsa_pss_rsae_sha384 */},
    {"rsa_pss_rsae_sha512",    0x0806 /* TLSEXT_SIGALG_rsa_pss_rsae_sha512 */},
    {"ed25519",                0x0807 /* TLSEXT_SIGALG_ed25519 */},
    {"ed448",                  0x0808 /* TLSEXT_SIGALG_ed448 */},
    {"rsa_pss_pss_sha256",     0x0809 /* TLSEXT_SIGALG_rsa_pss_pss_sha256 */},
    {"rsa_pss_pss_sha384",     0x080a /* TLSEXT_SIGALG_rsa_pss_pss_sha384 */},
    {"rsa_pss_pss_sha512",     0x080b /* TLSEXT_SIGALG_rsa_pss_pss_sha512 */},
    {"gostr34102001",          0xeded /* TLSEXT_SIGALG_gostr34102001_gostr3411 */},
    {"gostr34102012_256",      0xeeee /* TLSEXT_SIGALG_gostr34102012_256_gostr34112012_256 */},
    {"gostr34102012_512",      0xefef /* TLSEXT_SIGALG_gostr34102012_512_gostr34112012_512 */},
    {NULL}
};

/* from rfc5246 7.4.1.4.1. */
static STRINT_PAIR signature_tls12_alg_list[] = {
    {"anonymous", TLSEXT_signature_anonymous /* 0 */},
    {"RSA",       TLSEXT_signature_rsa       /* 1 */},
    {"DSA",       TLSEXT_signature_dsa       /* 2 */},
    {"ECDSA",     TLSEXT_signature_ecdsa     /* 3 */},
    {NULL}
};

/* from rfc5246 7.4.1.4.1. */
static STRINT_PAIR signature_tls12_hash_list[] = {
    {"none",   TLSEXT_hash_none   /* 0 */},
    {"MD5",    TLSEXT_hash_md5    /* 1 */},
    {"SHA1",   TLSEXT_hash_sha1   /* 2 */},
    {"SHA224", TLSEXT_hash_sha224 /* 3 */},
    {"SHA256", TLSEXT_hash_sha256 /* 4 */},
    {"SHA384", TLSEXT_hash_sha384 /* 5 */},
    {"SHA512", TLSEXT_hash_sha512 /* 6 */},
    {NULL}
};

void tlsext_cb(SSL *s, int client_server, int type,
               const unsigned char *data, int len, void *arg)
{
    BIO *bio = arg;
    const char *extname = lookup(type, tlsext_types, "unknown");

    BIO_printf(bio, "TLS %s extension \"%s\" (id=%d), len=%d\n",
               client_server ? "server" : "client", extname, type, len);
    BIO_dump(bio, (const char *)data, len);
    (void)BIO_flush(bio);
}

