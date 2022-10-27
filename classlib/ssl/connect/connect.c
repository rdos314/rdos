/*
 * Copyright 1995-2021 The OpenSSL Project Authors. All Rights Reserved.
 * Copyright 2005 Nokia. All rights reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

#include "e_os.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <openssl/e_os2.h>
#include <openssl/x509.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/ocsp.h>
#include <openssl/bn.h>
#include <openssl/async.h>
#include <openssl/srp.h>
#include <openssl/ct.h>
#include "internal/sockets.h"

#define PORT            "4433"
#define PROTOCOL        "tcp"

#define openssl_fdset(a,b) FD_SET(a, b)

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

/* numbers in us */
# define DGRAM_RCV_TIMEOUT         250000
# define DGRAM_SND_TIMEOUT         250000

typedef struct ssl_excert_st SSL_EXCERT;

#undef BUFSIZZ
#define BUFSIZZ 1024*8
#define S_CLIENT_IRC_READ_TIMEOUT 8

typedef struct string_int_pair_st {
    const char *name;
    int retval;
} STRINT_PAIR;

typedef struct verify_options_st {
    int depth;
    int quiet;
    int error;
    int return_error;
} VERIFY_CB_ARGS;

VERIFY_CB_ARGS verify_args = { -1, 0, X509_V_OK, 0 };

/* Default PSK identity and key */
static char *psk_identity = "Client_identity";

/*
 * quick macro when you need to pass an unsigned char instead of a char.
 * this is true for some implementations of the is*() functions, for
 * example.
 */
#define _UC(c) ((unsigned char)(c))

/* This is a context that we pass to callbacks */
typedef struct tlsextctx_st {
    BIO *biodebug;
    int ack;
} tlsextctx;

/* This is a context that we pass to all callbacks */
typedef struct srp_arg_st {
    char *srppassin;
    char *srplogin;
    int msg;                    /* copy from c_msg */
    int debug;                  /* copy from c_debug */
    int amp;                    /* allow more groups */
    int strength;               /* minimal size for N */
} SRP_ARG;

# define SRP_NUMBER_ITERATIONS_FOR_PRIME 64

/* This the context that we pass to next_proto_cb */
typedef struct tlsextnextprotoctx_st {
    unsigned char *data;
    size_t len;
    int status;
} tlsextnextprotoctx;

static tlsextnextprotoctx next_proto;


static int c_debug = 0;
static int c_showcerts = 0;
static char *keymatexportlabel = NULL;
static int keymatexportlen = 20;
static BIO *bio_c_out = NULL;
static int c_quiet = 0;
static char *sess_out = NULL;
static SSL_SESSION *psksess = NULL;

static void print_stuff(BIO *berr, SSL *con, int full);
static int ocsp_resp_cb(SSL *s, void *arg);
static int ldap_ExtendedResponse_parse(const char *buf, long rem);
static int is_dNS_name(const char *host);

char *default_config_file = NULL;
char *psk_key = NULL;
BIO *bio_in = NULL;
BIO *bio_out = NULL;
BIO *bio_err = NULL;

static unsigned long nmflag = 0;
static char nmflag_set = 0;

static char prog[40];

/*
 * Return the simple name of the program; removing various platform gunk.
 */

char *opt_progname(const char *argv0)
{
    const char *p;

    /* Could use strchr, but this is like the ones above. */
    for (p = argv0 + strlen(argv0); --p > argv0;)
        if (*p == '/') {
            p++;
            break;
        }
    strncpy(prog, p, sizeof(prog) - 1);
    prog[sizeof(prog) - 1] = '\0';
    return prog;
}

char *opt_getprog(void)
{
    return prog;
}

unsigned long get_nameopt(void)
{
    return (nmflag_set) ? nmflag : XN_FLAG_ONELINE;
}

static int istext(int format)
{
    return (format & B_FORMAT_TEXT) == B_FORMAT_TEXT;
}

static BIO *dup_bio_out(int format)
{
    BIO *b = BIO_new_fp(stdout,
                        BIO_NOCLOSE | (istext(format) ? BIO_FP_TEXT : 0));
    return b;
}

static int fileno_stdin(void)
{
    return fileno(stdin);
}

static int fileno_stdout(void)
{
    return fileno(stdout);
}

static int raw_write_stdout(const void *buf, int siz)
{
    return write(fileno_stdout(), buf, siz);
}


static int raw_read_stdin(void *buf, int siz)
{
    return read(fileno_stdin(), buf, siz);
}

void wait_for_async(SSL *s)
{
}

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

static int verify_callback(int ok, X509_STORE_CTX *ctx)
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

static long bio_dump_callback(BIO *bio, int cmd, const char *argp,
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

static void tlsext_cb(SSL *s, int client_server, int type,
               const unsigned char *data, int len, void *arg)
{
    BIO *bio = arg;
    const char *extname = lookup(type, tlsext_types, "unknown");

    BIO_printf(bio, "TLS %s extension \"%s\" (id=%d), len=%d\n",
               client_server ? "server" : "client", extname, type, len);
    BIO_dump(bio, (const char *)data, len);
    (void)BIO_flush(bio);
}


int config_ctx(SSL_CONF_CTX *cctx, STACK_OF(OPENSSL_STRING) *str,
               SSL_CTX *ctx)
{
    int i;

    SSL_CONF_CTX_set_ssl_ctx(cctx, ctx);
    for (i = 0; i < sk_OPENSSL_STRING_num(str); i += 2) {
        const char *flag = sk_OPENSSL_STRING_value(str, i);
        const char *arg = sk_OPENSSL_STRING_value(str, i + 1);
        if (SSL_CONF_cmd(cctx, flag, arg) <= 0) {
            if (arg != NULL)
                BIO_printf(bio_err, "Error with command: \"%s %s\"\n",
                           flag, arg);
            else
                BIO_printf(bio_err, "Error with command: \"%s\"\n", flag);
            ERR_print_errors(bio_err);
            return 0;
        }
    }
    if (!SSL_CONF_CTX_finish(cctx)) {
        BIO_puts(bio_err, "Error finishing context\n");
        ERR_print_errors(bio_err);
        return 0;
    }
    return 1;
}


void print_name(BIO *out, const char *title, X509_NAME *nm,
                unsigned long lflags)
{
    char *buf;
    char mline = 0;
    int indent = 0;

    if (title)
        BIO_puts(out, title);
    if ((lflags & XN_FLAG_SEP_MASK) == XN_FLAG_SEP_MULTILINE) {
        mline = 1;
        indent = 4;
    }
    if (lflags == XN_FLAG_COMPAT) {
        buf = X509_NAME_oneline(nm, 0, 0);
        BIO_puts(out, buf);
        BIO_puts(out, "\n");
        OPENSSL_free(buf);
    } else {
        if (mline)
            BIO_puts(out, "\n");
        X509_NAME_print_ex(out, nm, indent, lflags);
        BIO_puts(out, "\n");
    }
}

static int dump_cert_text(BIO *out, X509 *x)
{
    print_name(out, "subject=", X509_get_subject_name(x), get_nameopt());
    BIO_puts(out, "\n");
    print_name(out, "issuer=", X509_get_issuer_name(x), get_nameopt());
    BIO_puts(out, "\n");

    return 0;
}

static int ssl_print_point_formats(BIO *out, SSL *s)
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

static int ssl_print_groups(BIO *out, SSL *s, int noshared)
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

static int ssl_print_tmp_key(BIO *out, SSL *s)
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

/*
 * Hex encoder for TLSA RRdata, not ':' delimited.
 */
static char *hexencode(const unsigned char *data, size_t len)
{
    static const char *hex = "0123456789abcdef";
    char *out;
    char *cp;
    size_t outlen = 2 * len + 1;
    int ilen = (int) outlen;

    if (outlen < len || ilen < 0 || outlen != (size_t)ilen) {
        BIO_printf(bio_err, "%s: %zu-byte buffer too large to hexencode\n",
                   opt_getprog(), len);
        exit(1);
    }
    cp = out = OPENSSL_malloc(ilen);

    while (len-- > 0) {
        *cp++ = hex[(*data >> 4) & 0x0f];
        *cp++ = hex[*data++ & 0x0f];
    }
    *cp = '\0';
    return out;
}

static void print_verify_detail(SSL *s, BIO *bio)
{
    int mdpth;
    EVP_PKEY *mspki;
    long verify_err = SSL_get_verify_result(s);

    if (verify_err == X509_V_OK) {
        const char *peername = SSL_get0_peername(s);

        BIO_printf(bio, "Verification: OK\n");
        if (peername != NULL)
            BIO_printf(bio, "Verified peername: %s\n", peername);
    } else {
        const char *reason = X509_verify_cert_error_string(verify_err);

        BIO_printf(bio, "Verification error: %s\n", reason);
    }

    if ((mdpth = SSL_get0_dane_authority(s, NULL, &mspki)) >= 0) {
        uint8_t usage, selector, mtype;
        const unsigned char *data = NULL;
        size_t dlen = 0;
        char *hexdata;

        mdpth = SSL_get0_dane_tlsa(s, &usage, &selector, &mtype, &data, &dlen);

        /*
         * The TLSA data field can be quite long when it is a certificate,
         * public key or even a SHA2-512 digest.  Because the initial octets of
         * ASN.1 certificates and public keys contain mostly boilerplate OIDs
         * and lengths, we show the last 12 bytes of the data instead, as these
         * are more likely to distinguish distinct TLSA records.
         */
#define TLSA_TAIL_SIZE 12
        if (dlen > TLSA_TAIL_SIZE)
            hexdata = hexencode(data + dlen - TLSA_TAIL_SIZE, TLSA_TAIL_SIZE);
        else
            hexdata = hexencode(data, dlen);
        BIO_printf(bio, "DANE TLSA %d %d %d %s%s %s at depth %d\n",
                   usage, selector, mtype,
                   (dlen > TLSA_TAIL_SIZE) ? "..." : "", hexdata,
                   (mspki != NULL) ? "signed the certificate" :
                   mdpth ? "matched TA certificate" : "matched EE certificate",
                   mdpth);
        OPENSSL_free(hexdata);
    }
}

static const char *get_sigtype(int nid)
{
    switch (nid) {
    case EVP_PKEY_RSA:
        return "RSA";

    case EVP_PKEY_RSA_PSS:
        return "RSA-PSS";

    case EVP_PKEY_DSA:
        return "DSA";

     case EVP_PKEY_EC:
        return "ECDSA";

     case NID_ED25519:
        return "Ed25519";

     case NID_ED448:
        return "Ed448";

     case NID_id_GostR3410_2001:
        return "gost2001";

     case NID_id_GostR3410_2012_256:
        return "gost2012_256";

     case NID_id_GostR3410_2012_512:
        return "gost2012_512";

    default:
        return NULL;
    }
}

static int do_print_sigalgs(BIO *out, SSL *s, int shared)
{
    int i, nsig, client;
    client = SSL_is_server(s) ? 0 : 1;
    if (shared)
        nsig = SSL_get_shared_sigalgs(s, 0, NULL, NULL, NULL, NULL, NULL);
    else
        nsig = SSL_get_sigalgs(s, -1, NULL, NULL, NULL, NULL, NULL);
    if (nsig == 0)
        return 1;

    if (shared)
        BIO_puts(out, "Shared ");

    if (client)
        BIO_puts(out, "Requested ");
    BIO_puts(out, "Signature Algorithms: ");
    for (i = 0; i < nsig; i++) {
        int hash_nid, sign_nid;
        unsigned char rhash, rsign;
        const char *sstr = NULL;
        if (shared)
            SSL_get_shared_sigalgs(s, i, &sign_nid, &hash_nid, NULL,
                                   &rsign, &rhash);
        else
            SSL_get_sigalgs(s, i, &sign_nid, &hash_nid, NULL, &rsign, &rhash);
        if (i)
            BIO_puts(out, ":");
        sstr = get_sigtype(sign_nid);
        if (sstr)
            BIO_printf(out, "%s", sstr);
        else
            BIO_printf(out, "0x%02X", (int)rsign);
        if (hash_nid != NID_undef)
            BIO_printf(out, "+%s", OBJ_nid2sn(hash_nid));
        else if (sstr == NULL)
            BIO_printf(out, "+0x%02X", (int)rhash);
    }
    BIO_puts(out, "\n");
    return 1;
}

static int ssl_print_sigalgs(BIO *out, SSL *s)
{
    int nid;

    do_print_sigalgs(out, s, 0);
    do_print_sigalgs(out, s, 1);
    if (SSL_get_peer_signature_nid(s, &nid) && nid != NID_undef)
        BIO_printf(out, "Peer signing digest: %s\n", OBJ_nid2sn(nid));

    if (SSL_get_peer_signature_type_nid(s, &nid))
        BIO_printf(out, "Peer signature type: %s\n", get_sigtype(nid));

    return 1;
}

enum range { OPT_X_ENUM };

static void print_raw_cipherlist(SSL *s)
{
    const unsigned char *rlist;
    static const unsigned char scsv_id[] = { 0, 0xFF };
    size_t i, rlistlen, num;
    if (!SSL_is_server(s))
        return;
    num = SSL_get0_raw_cipherlist(s, NULL);
    OPENSSL_assert(num == 2);
    rlistlen = SSL_get0_raw_cipherlist(s, &rlist);
    BIO_puts(bio_err, "Client cipher list: ");
    for (i = 0; i < rlistlen; i += num, rlist += num) {
        const SSL_CIPHER *c = SSL_CIPHER_find(s, rlist);
        if (i)
            BIO_puts(bio_err, ":");
        if (c != NULL) {
            BIO_puts(bio_err, SSL_CIPHER_get_name(c));
        } else if (memcmp(rlist, scsv_id, num) == 0) {
            BIO_puts(bio_err, "SCSV");
        } else {
            size_t j;
            BIO_puts(bio_err, "0x");
            for (j = 0; j < num; j++)
                BIO_printf(bio_err, "%02X", rlist[j]);
        }
    }
    BIO_puts(bio_err, "\n");
}

void print_ssl_summary(SSL *s)
{
    const SSL_CIPHER *c;
    X509 *peer;

    BIO_printf(bio_err, "Protocol version: %s\n", SSL_get_version(s));
    print_raw_cipherlist(s);
    c = SSL_get_current_cipher(s);
    BIO_printf(bio_err, "Ciphersuite: %s\n", SSL_CIPHER_get_name(c));
    do_print_sigalgs(bio_err, s, 0);
    peer = SSL_get_peer_certificate(s);
    if (peer != NULL) {
        int nid;

        BIO_puts(bio_err, "Peer certificate: ");
        X509_NAME_print_ex(bio_err, X509_get_subject_name(peer),
                           0, get_nameopt());
        BIO_puts(bio_err, "\n");
        if (SSL_get_peer_signature_nid(s, &nid))
            BIO_printf(bio_err, "Hash used: %s\n", OBJ_nid2sn(nid));
        if (SSL_get_peer_signature_type_nid(s, &nid))
            BIO_printf(bio_err, "Signature type: %s\n", get_sigtype(nid));
        print_verify_detail(s, bio_err);
    } else {
        BIO_puts(bio_err, "No peer certificate\n");
    }
    X509_free(peer);
    ssl_print_point_formats(bio_err, s);
    if (SSL_is_server(s))
        ssl_print_groups(bio_err, s, 1);
    else
        ssl_print_tmp_key(bio_err, s);
}

static void print_ca_names(BIO *bio, SSL *s)
{
    const char *cs = SSL_is_server(s) ? "server" : "client";
    const STACK_OF(X509_NAME) *sk = SSL_get0_peer_CA_list(s);
    int i;

    if (sk == NULL || sk_X509_NAME_num(sk) == 0) {
        if (!SSL_is_server(s))
            BIO_printf(bio, "---\nNo %s certificate CA names sent\n", cs);
        return;
    }

    BIO_printf(bio, "---\nAcceptable %s certificate CA names\n",cs);
    for (i = 0; i < sk_X509_NAME_num(sk); i++) {
        X509_NAME_print_ex(bio, sk_X509_NAME_value(sk, i), 0, get_nameopt());
        BIO_write(bio, "\n", 1);
    }
}

static void print_stuff(BIO *bio, SSL *s, int full)
{
    X509 *peer = NULL;
    STACK_OF(X509) *sk;
    const SSL_CIPHER *c;
    int i, istls13 = (SSL_version(s) == TLS1_3_VERSION);
    long verify_result;
    const COMP_METHOD *comp, *expansion;
    unsigned char *exportedkeymat;
    const SSL_CTX *ctx = SSL_get_SSL_CTX(s);

    if (full) {
        int got_a_chain = 0;

        sk = SSL_get_peer_cert_chain(s);
        if (sk != NULL) {
            got_a_chain = 1;

            BIO_printf(bio, "---\nCertificate chain\n");
            for (i = 0; i < sk_X509_num(sk); i++) {
                BIO_printf(bio, "%2d s:", i);
                X509_NAME_print_ex(bio, X509_get_subject_name(sk_X509_value(sk, i)), 0, get_nameopt());
                BIO_puts(bio, "\n");
                BIO_printf(bio, "   i:");
                X509_NAME_print_ex(bio, X509_get_issuer_name(sk_X509_value(sk, i)), 0, get_nameopt());
                BIO_puts(bio, "\n");
                if (c_showcerts)
                    PEM_write_bio_X509(bio, sk_X509_value(sk, i));
            }
        }

        BIO_printf(bio, "---\n");
        peer = SSL_get_peer_certificate(s);
        if (peer != NULL) {
            BIO_printf(bio, "Server certificate\n");

            /* Redundant if we showed the whole chain */
            if (!(c_showcerts && got_a_chain))
                PEM_write_bio_X509(bio, peer);
            dump_cert_text(bio, peer);
        } else {
            BIO_printf(bio, "no peer certificate available\n");
        }
        print_ca_names(bio, s);

        ssl_print_sigalgs(bio, s);
        ssl_print_tmp_key(bio, s);

        /*
         * When the SSL session is anonymous, or resumed via an abbreviated
         * handshake, no SCTs are provided as part of the handshake.  While in
         * a resumed session SCTs may be present in the session's certificate,
         * no callbacks are invoked to revalidate these, and in any case that
         * set of SCTs may be incomplete.  Thus it makes little sense to
         * attempt to display SCTs from a resumed session's certificate, and of
         * course none are associated with an anonymous peer.
         */
        if (peer != NULL && !SSL_session_reused(s) && SSL_ct_is_enabled(s)) {
            const STACK_OF(SCT) *scts = SSL_get0_peer_scts(s);
            int sct_count = scts != NULL ? sk_SCT_num(scts) : 0;

            BIO_printf(bio, "---\nSCTs present (%i)\n", sct_count);
            if (sct_count > 0) {
                const CTLOG_STORE *log_store = SSL_CTX_get0_ctlog_store(ctx);

                BIO_printf(bio, "---\n");
                for (i = 0; i < sct_count; ++i) {
                    SCT *sct = sk_SCT_value(scts, i);

                    BIO_printf(bio, "SCT validation status: %s\n",
                               SCT_validation_status_string(sct));
                    SCT_print(sct, bio, 0, log_store);
                    if (i < sct_count - 1)
                        BIO_printf(bio, "\n---\n");
                }
                BIO_printf(bio, "\n");
            }
        }

        BIO_printf(bio,
                   "---\nSSL handshake has read %ju bytes "
                   "and written %ju bytes\n",
                   BIO_number_read(SSL_get_rbio(s)),
                   BIO_number_written(SSL_get_wbio(s)));
    }
    print_verify_detail(s, bio);
    BIO_printf(bio, (SSL_session_reused(s) ? "---\nReused, " : "---\nNew, "));
    c = SSL_get_current_cipher(s);
    BIO_printf(bio, "%s, Cipher is %s\n",
               SSL_CIPHER_get_version(c), SSL_CIPHER_get_name(c));
    if (peer != NULL) {
        EVP_PKEY *pktmp;

        pktmp = X509_get0_pubkey(peer);
        BIO_printf(bio, "Server public key is %d bit\n",
                   EVP_PKEY_bits(pktmp));
    }
    BIO_printf(bio, "Secure Renegotiation IS%s supported\n",
               SSL_get_secure_renegotiation_support(s) ? "" : " NOT");
    comp = SSL_get_current_compression(s);
    expansion = SSL_get_current_expansion(s);
    BIO_printf(bio, "Compression: %s\n",
               comp ? SSL_COMP_get_name(comp) : "NONE");
    BIO_printf(bio, "Expansion: %s\n",
               expansion ? SSL_COMP_get_name(expansion) : "NONE");

    {
        /* Print out local port of connection: useful for debugging */
        int sock;
        union BIO_sock_info_u info;

        sock = SSL_get_fd(s);
        if ((info.addr = BIO_ADDR_new()) != NULL
            && BIO_sock_info(sock, BIO_SOCK_INFO_ADDRESS, &info)) {
            BIO_printf(bio_c_out, "LOCAL PORT is %u\n",
                       ntohs(BIO_ADDR_rawport(info.addr)));
        }
        BIO_ADDR_free(info.addr);
    }

    if (next_proto.status != -1) {
        const unsigned char *proto;
        unsigned int proto_len;
        SSL_get0_next_proto_negotiated(s, &proto, &proto_len);
        BIO_printf(bio, "Next protocol: (%d) ", next_proto.status);
        BIO_write(bio, proto, proto_len);
        BIO_write(bio, "\n", 1);
    }
    {
        const unsigned char *proto;
        unsigned int proto_len;
        SSL_get0_alpn_selected(s, &proto, &proto_len);
        if (proto_len > 0) {
            BIO_printf(bio, "ALPN protocol: ");
            BIO_write(bio, proto, proto_len);
            BIO_write(bio, "\n", 1);
        } else
            BIO_printf(bio, "No ALPN negotiated\n");
    }

    {
        SRTP_PROTECTION_PROFILE *srtp_profile =
            SSL_get_selected_srtp_profile(s);

        if (srtp_profile)
            BIO_printf(bio, "SRTP Extension negotiated, profile=%s\n",
                       srtp_profile->name);
    }

    if (istls13) {
        switch (SSL_get_early_data_status(s)) {
        case SSL_EARLY_DATA_NOT_SENT:
            BIO_printf(bio, "Early data was not sent\n");
            break;

        case SSL_EARLY_DATA_REJECTED:
            BIO_printf(bio, "Early data was rejected\n");
            break;

        case SSL_EARLY_DATA_ACCEPTED:
            BIO_printf(bio, "Early data was accepted\n");
            break;

        }

        /*
         * We also print the verify results when we dump session information,
         * but in TLSv1.3 we may not get that right away (or at all) depending
         * on when we get a NewSessionTicket. Therefore we print it now as well.
         */
        verify_result = SSL_get_verify_result(s);
        BIO_printf(bio, "Verify return code: %ld (%s)\n", verify_result,
                   X509_verify_cert_error_string(verify_result));
    } else {
        /* In TLSv1.3 we do this on arrival of a NewSessionTicket */
        SSL_SESSION_print(bio, SSL_get_session(s));
    }

    if (SSL_get_session(s) != NULL && keymatexportlabel != NULL) {
        BIO_printf(bio, "Keying material exporter:\n");
        BIO_printf(bio, "    Label: '%s'\n", keymatexportlabel);
        BIO_printf(bio, "    Length: %i bytes\n", keymatexportlen);
        exportedkeymat = OPENSSL_malloc(keymatexportlen);
        if (!SSL_export_keying_material(s, exportedkeymat,
                                        keymatexportlen,
                                        keymatexportlabel,
                                        strlen(keymatexportlabel),
                                        NULL, 0, 0)) {
            BIO_printf(bio, "    Error\n");
        } else {
            BIO_printf(bio, "    Keying material: ");
            for (i = 0; i < keymatexportlen; i++)
                BIO_printf(bio, "%02X", exportedkeymat[i]);
            BIO_printf(bio, "\n");
        }
        OPENSSL_free(exportedkeymat);
    }
    BIO_printf(bio, "---\n");
    X509_free(peer);
    /* flush, or debugging output gets mixed with http response */
    (void)BIO_flush(bio);
}

static void do_ssl_shutdown(SSL *ssl)
{
    int ret;

    do {
        /* We only do unidirectional shutdown */
        ret = SSL_shutdown(ssl);
        if (ret < 0) {
            switch (SSL_get_error(ssl, ret)) {
            case SSL_ERROR_WANT_READ:
            case SSL_ERROR_WANT_WRITE:
            case SSL_ERROR_WANT_ASYNC:
            case SSL_ERROR_WANT_ASYNC_JOB:
                /* We just do busy waiting. Nothing clever */
                continue;
            }
            ret = 0;
        }
    } while (ret < 0);
}

static int ssl_servername_cb(SSL *s, int *ad, void *arg)
{
    tlsextctx *p = (tlsextctx *) arg;
    const char *hn = SSL_get_servername(s, TLSEXT_NAMETYPE_host_name);
    if (SSL_get_servername_type(s) != -1)
        p->ack = !SSL_session_reused(s) && hn != NULL;
    else
        BIO_printf(bio_err, "Can't use SSL_get_servername\n");

    return SSL_TLSEXT_ERR_OK;
}

/* Free |*dest| and optionally set it to a copy of |source|. */
static void freeandcopy(char **dest, const char *source)
{
    OPENSSL_free(*dest);
    *dest = NULL;
    if (source != NULL)
        *dest = OPENSSL_strdup(source);
}

static int new_session_cb(SSL *s, SSL_SESSION *sess)
{

    if (sess_out != NULL) {
        BIO *stmp = BIO_new_file(sess_out, "w");

        if (stmp == NULL) {
            BIO_printf(bio_err, "Error writing session file %s\n", sess_out);
        } else {
            PEM_write_bio_SSL_SESSION(stmp, sess);
            BIO_free(stmp);
        }
    }

    /*
     * Session data gets dumped on connection for TLSv1.2 and below, and on
     * arrival of the NewSessionTicket for TLSv1.3.
     */
    if (SSL_version(s) == TLS1_3_VERSION) {
        BIO_printf(bio_c_out,
                   "---\nPost-Handshake New Session Ticket arrived:\n");
        SSL_SESSION_print(bio_c_out, sess);
        BIO_printf(bio_c_out, "---\n");
    }

    /*
     * We always return a "fail" response so that the session gets freed again
     * because we haven't used the reference.
     */
    return 0;
}

static int ocsp_resp_cb(SSL *s, void *arg)
{
    const unsigned char *p;
    int len;
    OCSP_RESPONSE *rsp;
    len = SSL_get_tlsext_status_ocsp_resp(s, &p);
    BIO_puts(arg, "OCSP response: ");
    if (p == NULL) {
        BIO_puts(arg, "no response sent\n");
        return 1;
    }
    rsp = d2i_OCSP_RESPONSE(NULL, &p, len);
    if (rsp == NULL) {
        BIO_puts(arg, "response parse error\n");
        BIO_dump_indent(arg, (char *)p, len, 4);
        return 0;
    }
    BIO_puts(arg, "\n======================================\n");
    OCSP_RESPONSE_print(arg, rsp, 0);
    BIO_puts(arg, "======================================\n");
    OCSP_RESPONSE_free(rsp);
    return 1;
}

static int ldap_ExtendedResponse_parse(const char *buf, long rem)
{
    const unsigned char *cur, *end;
    long len;
    int tag, xclass, inf, ret = -1;

    cur = (const unsigned char *)buf;
    end = cur + rem;

    /*
     * From RFC 4511:
     *
     *    LDAPMessage ::= SEQUENCE {
     *         messageID       MessageID,
     *         protocolOp      CHOICE {
     *              ...
     *              extendedResp          ExtendedResponse,
     *              ... },
     *         controls       [0] Controls OPTIONAL }
     *
     *    ExtendedResponse ::= [APPLICATION 24] SEQUENCE {
     *         COMPONENTS OF LDAPResult,
     *         responseName     [10] LDAPOID OPTIONAL,
     *         responseValue    [11] OCTET STRING OPTIONAL }
     *
     *    LDAPResult ::= SEQUENCE {
     *         resultCode         ENUMERATED {
     *              success                      (0),
     *              ...
     *              other                        (80),
     *              ...  },
     *         matchedDN          LDAPDN,
     *         diagnosticMessage  LDAPString,
     *         referral           [3] Referral OPTIONAL }
     */

    /* pull SEQUENCE */
    inf = ASN1_get_object(&cur, &len, &tag, &xclass, rem);
    if (inf != V_ASN1_CONSTRUCTED || tag != V_ASN1_SEQUENCE ||
        (rem = end - cur, len > rem)) {
        BIO_printf(bio_err, "Unexpected LDAP response\n");
        goto end;
    }

    rem = len;  /* ensure that we don't overstep the SEQUENCE */

    /* pull MessageID */
    inf = ASN1_get_object(&cur, &len, &tag, &xclass, rem);
    if (inf != V_ASN1_UNIVERSAL || tag != V_ASN1_INTEGER ||
        (rem = end - cur, len > rem)) {
        BIO_printf(bio_err, "No MessageID\n");
        goto end;
    }

    cur += len; /* shall we check for MessageId match or just skip? */

    /* pull [APPLICATION 24] */
    rem = end - cur;
    inf = ASN1_get_object(&cur, &len, &tag, &xclass, rem);
    if (inf != V_ASN1_CONSTRUCTED || xclass != V_ASN1_APPLICATION ||
        tag != 24) {
        BIO_printf(bio_err, "Not ExtendedResponse\n");
        goto end;
    }

    /* pull resultCode */
    rem = end - cur;
    inf = ASN1_get_object(&cur, &len, &tag, &xclass, rem);
    if (inf != V_ASN1_UNIVERSAL || tag != V_ASN1_ENUMERATED || len == 0 ||
        (rem = end - cur, len > rem)) {
        BIO_printf(bio_err, "Not LDAPResult\n");
        goto end;
    }

    /* len should always be one, but just in case... */
    for (ret = 0, inf = 0; inf < len; inf++) {
        ret <<= 8;
        ret |= cur[inf];
    }
    /* There is more data, but we don't care... */
 end:
    return ret;
}

/*
 * Host dNS Name verifier: used for checking that the hostname is in dNS format 
 * before setting it as SNI
 */
static int is_dNS_name(const char *host)
{
    const size_t MAX_LABEL_LENGTH = 63;
    size_t i;
    int isdnsname = 0;
    size_t length = strlen(host);
    size_t label_length = 0;
    int all_numeric = 1;

    /*
     * Deviation from strict DNS name syntax, also check names with '_'
     * Check DNS name syntax, any '-' or '.' must be internal,
     * and on either side of each '.' we can't have a '-' or '.'.
     *
     * If the name has just one label, we don't consider it a DNS name.
     */
    for (i = 0; i < length && label_length < MAX_LABEL_LENGTH; ++i) {
        char c = host[i];

        if ((c >= 'a' && c <= 'z')
            || (c >= 'A' && c <= 'Z')
            || c == '_') {
            label_length += 1;
            all_numeric = 0;
            continue;
        }

        if (c >= '0' && c <= '9') {
            label_length += 1;
            continue;
        }

        /* Dot and hyphen cannot be first or last. */
        if (i > 0 && i < length - 1) {
            if (c == '-') {
                label_length += 1;
                continue;
            }
            /*
             * Next to a dot the preceding and following characters must not be
             * another dot or a hyphen.  Otherwise, record that the name is
             * plausible, since it has two or more labels.
             */
            if (c == '.'
                && host[i + 1] != '.'
                && host[i - 1] != '-'
                && host[i + 1] != '-') {
                label_length = 0;
                isdnsname = 1;
                continue;
            }
        }
        isdnsname = 0;
        break;
    }

    /* dNS name must not be all numeric and labels must be shorter than 64 characters. */
    isdnsname &= !all_numeric && !(label_length == MAX_LABEL_LENGTH);

    return isdnsname;
}
/* Keep track of our peer's address for the cookie callback */
BIO_ADDR *ourpeer = NULL;

/*
 * init_client - helper routine to set up socket communication
 * @sock: pointer to storage of resulting socket.
 * @host: the host name or path (for AF_UNIX) to connect to.
 * @port: the port to connect to (ignored for AF_UNIX).
 * @bindhost: source host or path (for AF_UNIX).
 * @bindport: source port (ignored for AF_UNIX).
 * @family: desired socket family, may be AF_INET, AF_INET6, AF_UNIX or
 *  AF_UNSPEC
 * @type: socket type, must be SOCK_STREAM or SOCK_DGRAM
 * @protocol: socket protocol, e.g. IPPROTO_TCP or IPPROTO_UDP (or 0 for any)
 *
 * This will create a socket and use it to connect to a host:port, or if
 * family == AF_UNIX, to the path found in host.
 *
 * If the host has more than one address, it will try them one by one until
 * a successful connection is established.  The resulting socket will be
 * found in *sock on success, it will be given INVALID_SOCKET otherwise.
 *
 * Returns 1 on success, 0 on failure.
 */
static int init_client(int *sock, const char *host, const char *port,
                const char *bindhost, const char *bindport,
                int family, int type, int protocol)
{
    BIO_ADDRINFO *res = NULL;
    BIO_ADDRINFO *bindaddr = NULL;
    const BIO_ADDRINFO *ai = NULL;
    const BIO_ADDRINFO *bi = NULL;
    int found = 0;
    int ret;

    if (BIO_sock_init() != 1)
        return 0;

    ret = BIO_lookup_ex(host, port, BIO_LOOKUP_CLIENT, family, type, protocol,
                        &res);
    if (ret == 0) {
        ERR_print_errors(bio_err);
        return 0;
    }

    if (bindhost != NULL || bindport != NULL) {
        ret = BIO_lookup_ex(bindhost, bindport, BIO_LOOKUP_CLIENT,
                            family, type, protocol, &bindaddr);
        if (ret == 0) {
            ERR_print_errors (bio_err);
            goto out;
        }
    }

    ret = 0;
    for (ai = res; ai != NULL; ai = BIO_ADDRINFO_next(ai)) {
        /* Admittedly, these checks are quite paranoid, we should not get
         * anything in the BIO_ADDRINFO chain that we haven't
         * asked for. */
        OPENSSL_assert((family == AF_UNSPEC
                        || family == BIO_ADDRINFO_family(ai))
                       && (type == 0 || type == BIO_ADDRINFO_socktype(ai))
                       && (protocol == 0
                           || protocol == BIO_ADDRINFO_protocol(ai)));

        if (bindaddr != NULL) {
            for (bi = bindaddr; bi != NULL; bi = BIO_ADDRINFO_next(bi)) {
                if (BIO_ADDRINFO_family(bi) == BIO_ADDRINFO_family(ai))
                    break;
            }
            if (bi == NULL)
                continue;
            ++found;
        }

        *sock = BIO_socket(BIO_ADDRINFO_family(ai), BIO_ADDRINFO_socktype(ai),
                           BIO_ADDRINFO_protocol(ai), 0);
        if (*sock == INVALID_SOCKET) {
            /* Maybe the kernel doesn't support the socket family, even if
             * BIO_lookup() added it in the returned result...
             */
            continue;
        }

        if (bi != NULL) {
            if (!BIO_bind(*sock, BIO_ADDRINFO_address(bi),
                          BIO_SOCK_REUSEADDR)) {
                BIO_closesocket(*sock);
                *sock = INVALID_SOCKET;
                break;
            }
        }

        if (!BIO_connect(*sock, BIO_ADDRINFO_address(ai),
                         BIO_ADDRINFO_protocol(ai) == IPPROTO_TCP ? BIO_SOCK_NODELAY : 0)) {
            BIO_closesocket(*sock);
            *sock = INVALID_SOCKET;
            continue;
        }

        /* Success, don't try any more addresses */
        break;
    }

    if (*sock == INVALID_SOCKET) {
        if (bindaddr != NULL && !found) {
            BIO_printf(bio_err, "Can't bind %saddress for %s%s%s\n",
//                       BIO_ADDRINFO_family(res) == AF_INET6 ? "IPv6 " :
                       BIO_ADDRINFO_family(res) == AF_INET ? "IPv4 " :
//                       BIO_ADDRINFO_family(res) == AF_UNIX ? "unix " : "",
                       bindhost != NULL ? bindhost : "",
                       bindport != NULL ? ":" : "",
                       bindport != NULL ? bindport : "");
            ERR_clear_error();
            ret = 0;
        }
        ERR_print_errors(bio_err);
    } else {
        /* Remove any stale errors from previous connection attempts */
        ERR_clear_error();
        ret = 1;
    }
out:
    if (bindaddr != NULL) {
        BIO_ADDRINFO_free (bindaddr);
    }
    BIO_ADDRINFO_free(res);
    return ret;
}

int main(int argc, char **argv)
{
    BIO *sbio;
    EVP_PKEY *key = NULL;
    SSL *con = NULL;
    SSL_CTX *ctx = NULL;
    STACK_OF(X509) *chain = NULL;
    X509 *cert = NULL;
    X509_VERIFY_PARAM *vpm = NULL;
    SSL_EXCERT *exc = NULL;
    SSL_CONF_CTX *cctx = NULL;
    STACK_OF(OPENSSL_STRING) *ssl_args = NULL;
    char *dane_tlsa_domain = NULL;
    STACK_OF(OPENSSL_STRING) *dane_tlsa_rrset = NULL;
    int dane_ee_no_name = 0;
    STACK_OF(X509_CRL) *crls = NULL;
    const SSL_METHOD *meth = TLS_client_method();
    const char *CApath = NULL, *CAfile = NULL;
    char *cbuf = NULL, *sbuf = NULL;
    char *mbuf = NULL, *proxystr = NULL, *connectstr = NULL, *bindstr = NULL;
    char *cert_file = NULL, *key_file = NULL, *chain_file = NULL;
    char *chCApath = NULL, *chCAfile = NULL, *host = NULL;
    char *port = OPENSSL_strdup(PORT);
    char *bindhost = NULL, *bindport = NULL;
    char *passarg = NULL, *pass = NULL, *vfyCApath = NULL, *vfyCAfile = NULL;
    char *ReqCAfile = NULL;
    char *sess_in = NULL, *crl_file = NULL, *p;
    const char *protohost = NULL;
    struct timeval timeout, *timeoutp;
    fd_set readfds, writefds;
    int noCApath = 0, noCAfile = 0;
    int build_chain = 0, cbuf_len, cbuf_off, cert_format = FORMAT_PEM;
    int key_format = FORMAT_PEM, crlf = 0, full_log = 1, mbuf_len = 0;
    int prexit = 0;
    int sdebug = 0;
    int reconnect = 0, verify = SSL_VERIFY_NONE, vpmtouched = 0;
    int ret = 1, in_init = 1, i, nbio_test = 0, s = -1, k, width, state = 0;
    int sbuf_len, sbuf_off, cmdletters = 1;
    int socket_family = AF_UNSPEC, socket_type = SOCK_STREAM, protocol = 0;
    int starttls_proto = 0, crl_format = FORMAT_PEM, crl_download = 0;
    int write_tty, read_tty, write_ssl, read_ssl, tty_on, ssl_pending;
    int at_eof = 0;
    int read_buf_len = 0;
    int fallback_scsv = 0;
    int enable_timeouts = 0;
    long socket_mtu = 0;
    ENGINE *ssl_client_engine = NULL;
    ENGINE *e = NULL;
    const char *servername = NULL;
    char *sname_alloc = NULL;
    int noservername = 0;
    const char *alpn_in = NULL;
    tlsextctx tlsextcbp = { NULL, 0 };
    const char *ssl_config = NULL;
#define MAX_SI_TYPES 100
    unsigned short serverinfo_types[MAX_SI_TYPES];
    int serverinfo_count = 0, start = 0, len;
    const char *next_proto_neg_in = NULL;
    char *srppass = NULL;
    int srp_lateuser = 0;
    SRP_ARG srp_arg = { NULL, NULL, 0, 0, 0, 1024 };
    char *srtp_profiles = NULL;
    char *ctlog_file = NULL;
    int ct_validation = 0;
    int min_version = 0, max_version = 0, prot_opt = 0, no_prot_opt = 0;
    int async = 0;
    unsigned int max_send_fragment = 0;
    unsigned int split_send_fragment = 0, max_pipelines = 0;
    enum { use_inet, use_unix, use_unknown } connect_type = use_unknown;
    int count4or6 = 0;
    uint8_t maxfraglen = 0;
    int c_nbio = 0, c_msg = 0, c_ign_eof = 0, c_brief = 0;
    int c_tlsextdebug = 0;
    int c_status_req = 0;
    BIO *bio_c_msg = NULL;
    const char *keylog_file = NULL, *early_data_file = NULL;
    int isdtls = 0;
    char *psksessf = NULL;
    int enable_pha = 0;
    int sctp_label_bug = 0;

    FD_ZERO(&readfds);
    FD_ZERO(&writefds);

    opt_progname(argv[0]);
    c_quiet = 0;
    c_debug = 0;
    c_showcerts = 0;
    c_nbio = 0;
    vpm = X509_VERIFY_PARAM_new();
    cctx = SSL_CONF_CTX_new();

    if (vpm == NULL || cctx == NULL) {
        BIO_printf(bio_err, "%s: out of memory\n", prog);
        goto end;
    }

    cbuf = OPENSSL_malloc(BUFSIZZ);
    sbuf = OPENSSL_malloc(BUFSIZZ);
    mbuf = OPENSSL_malloc(BUFSIZZ);

    SSL_CONF_CTX_set_flags(cctx, SSL_CONF_FLAG_CLIENT | SSL_CONF_FLAG_CMDLINE);

    connect_type = use_inet;
    freeandcopy(&connectstr, argv[1]);

    if (connectstr != NULL) {
        int res;
        res = BIO_parse_hostserv(connectstr, &host, &port,
                                     BIO_PARSE_PRIO_HOST);
        if (!res) {
            BIO_printf(bio_err,
                       "%s: Invalid IP address\n",
                       prog);
            goto end;
        }
    }

    next_proto.data = NULL;

    if (bio_c_out == NULL) {
        if (c_quiet && !c_debug) {
            bio_c_out = BIO_new(BIO_s_null());
            if (c_msg && bio_c_msg == NULL)
                bio_c_msg = dup_bio_out(FORMAT_TEXT);
        } else if (bio_c_out == NULL)
            bio_c_out = dup_bio_out(FORMAT_TEXT);
    }

    srp_arg.srppassin = NULL;

    ctx = SSL_CTX_new(meth);
    if (ctx == NULL) {
        ERR_print_errors(bio_err);
        goto end;
    }

    SSL_CTX_clear_mode(ctx, SSL_MODE_AUTO_RETRY);

    if (!config_ctx(cctx, ssl_args, ctx))
        goto end;

    if (ssl_config != NULL) {
        if (SSL_CTX_config(ctx, ssl_config) == 0) {
            BIO_printf(bio_err, "Error using configuration \"%s\"\n",
                       ssl_config);
            ERR_print_errors(bio_err);
            goto end;
        }
    }

    SSL_CTX_set_default_ctlog_list_file(ctx);
    SSL_CTX_set_default_verify_file(ctx);
    SSL_CTX_set_default_verify_dir(ctx);
    SSL_CTX_set_verify(ctx, verify, verify_callback);

    tlsextcbp.biodebug = bio_err;
    SSL_CTX_set_tlsext_servername_callback(ctx, ssl_servername_cb);
    SSL_CTX_set_tlsext_servername_arg(ctx, &tlsextcbp);

    /*
     * In TLSv1.3 NewSessionTicket messages arrive after the handshake and can
     * come at any time. Therefore we use a callback to write out the session
     * when we know about it. This approach works for < TLSv1.3 as well.
     */
    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_CLIENT
                                        | SSL_SESS_CACHE_NO_INTERNAL_STORE);
    SSL_CTX_sess_set_new_cb(ctx, new_session_cb);

    con = SSL_new(ctx);
    if (con == NULL)
        goto end;

    if (!noservername && (servername != NULL || dane_tlsa_domain == NULL)) {
        if (servername == NULL) {
            if(host == NULL || is_dNS_name(host)) 
                servername = (host == NULL) ? "localhost" : host;
        }
        if (servername != NULL && !SSL_set_tlsext_host_name(con, servername)) {
            BIO_printf(bio_err, "Unable to set TLS servername extension.\n");
            ERR_print_errors(bio_err);
            goto end;
        }
    }

 re_start:
    if (init_client(&s, host, port, bindhost, bindport, socket_family,
                    socket_type, protocol) == 0) {
        BIO_printf(bio_err, "connect:errno=%d\n", get_last_socket_error());
        BIO_closesocket(s);
        goto end;
    }
    BIO_printf(bio_c_out, "CONNECTED(%08X)\n", s);

    if (c_nbio) {
        if (!BIO_socket_nbio(s, 1)) {
            ERR_print_errors(bio_err);
            goto end;
        }
        BIO_printf(bio_c_out, "Turned on non blocking io\n");
    }

    sbio = BIO_new_socket(s, BIO_NOCLOSE);

    SSL_set_bio(con, sbio, sbio);
    SSL_set_connect_state(con);

    /* ok, lets connect */
    if (fileno_stdin() > SSL_get_fd(con))
        width = fileno_stdin() + 1;
    else
        width = SSL_get_fd(con) + 1;

    read_tty = 1;
    write_tty = 0;
    tty_on = 0;
    read_ssl = 1;
    write_ssl = 1;

    cbuf_len = 0;
    cbuf_off = 0;
    sbuf_len = 0;
    sbuf_off = 0;

    for (;;) {
        FD_ZERO(&readfds);
        FD_ZERO(&writefds);

        if (SSL_is_dtls(con) && DTLSv1_get_timeout(con, &timeout))
            timeoutp = &timeout;
        else
            timeoutp = NULL;

        if (!SSL_is_init_finished(con) && SSL_total_renegotiations(con) == 0
                && SSL_get_key_update_type(con) == SSL_KEY_UPDATE_NONE) {
            in_init = 1;
            tty_on = 0;
        } else {
            tty_on = 1;
            if (in_init) {
                in_init = 0;

                if (c_brief) {
                    BIO_puts(bio_err, "CONNECTION ESTABLISHED\n");
                    print_ssl_summary(con);
                }

                print_stuff(bio_c_out, con, full_log);
                if (full_log > 0)
                    full_log--;

                if (starttls_proto) {
                    BIO_write(bio_err, mbuf, mbuf_len);
                    /* We don't need to know any more */
                    if (!reconnect)
                        starttls_proto = 0;
                }

                if (reconnect) {
                    reconnect--;
                    BIO_printf(bio_c_out,
                               "drop connection and then reconnect\n");
                    do_ssl_shutdown(con);
                    SSL_set_connect_state(con);
                    BIO_closesocket(SSL_get_fd(con));
                    goto re_start;
                }
            }
        }

        ssl_pending = read_ssl && SSL_has_pending(con);

        if (!ssl_pending) {
            if (tty_on) {
                /*
                 * Note that select() returns when read _would not block_,
                 * and EOF satisfies that.  To avoid a CPU-hogging loop,
                 * set the flag so we exit.
                 */
                if (read_tty && !at_eof)
                    openssl_fdset(fileno_stdin(), &readfds);

                if (write_tty)
                    openssl_fdset(fileno_stdout(), &writefds);
            }
            if (read_ssl)
                openssl_fdset(SSL_get_fd(con), &readfds);
            if (write_ssl)
                openssl_fdset(SSL_get_fd(con), &writefds);

            /*
             * Note: under VMS with SOCKETSHR the second parameter is
             * currently of type (int *) whereas under other systems it is
             * (void *) if you don't have a cast it will choke the compiler:
             * if you do have a cast then you can either go for (int *) or
             * (void *).
             */
            i = select(width, (void *)&readfds, (void *)&writefds,
                       NULL, timeoutp);

            if (i < 0) {
                BIO_printf(bio_err, "bad select %d\n",
                           get_last_socket_error());
                goto shut;
            }
        }

        if (SSL_is_dtls(con) && DTLSv1_handle_timeout(con) > 0)
            BIO_printf(bio_err, "TIMEOUT occurred\n");

        if (!ssl_pending && FD_ISSET(SSL_get_fd(con), &writefds)) {
            k = SSL_write(con, &(cbuf[cbuf_off]), (unsigned int)cbuf_len);
            switch (SSL_get_error(con, k)) {
            case SSL_ERROR_NONE:
                cbuf_off += k;
                cbuf_len -= k;
                if (k <= 0)
                    goto end;
                /* we have done a  write(con,NULL,0); */
                if (cbuf_len <= 0) {
                    read_tty = 1;
                    write_ssl = 0;
                } else {        /* if (cbuf_len > 0) */

                    read_tty = 0;
                    write_ssl = 1;
                }
                break;
            case SSL_ERROR_WANT_WRITE:
                BIO_printf(bio_c_out, "write W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;
            case SSL_ERROR_WANT_ASYNC:
                BIO_printf(bio_c_out, "write A BLOCK\n");
                wait_for_async(con);
                write_ssl = 1;
                read_tty = 0;
                break;
            case SSL_ERROR_WANT_READ:
                BIO_printf(bio_c_out, "write R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                write_ssl = 0;
                break;
            case SSL_ERROR_WANT_X509_LOOKUP:
                BIO_printf(bio_c_out, "write X BLOCK\n");
                break;
            case SSL_ERROR_ZERO_RETURN:
                if (cbuf_len != 0) {
                    BIO_printf(bio_c_out, "shutdown\n");
                    ret = 0;
                    goto shut;
                } else {
                    read_tty = 1;
                    write_ssl = 0;
                    break;
                }

            case SSL_ERROR_SYSCALL:
                if ((k != 0) || (cbuf_len != 0)) {
                    BIO_printf(bio_err, "write:errno=%d\n",
                               get_last_socket_error());
                    goto shut;
                } else {
                    read_tty = 1;
                    write_ssl = 0;
                }
                break;
            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client - treat as an error */
            case SSL_ERROR_SSL:
                ERR_print_errors(bio_err);
                goto shut;
            }
        }
        else if (!ssl_pending && FD_ISSET(fileno_stdout(), &writefds))
        {
            i = raw_write_stdout(&(sbuf[sbuf_off]), sbuf_len);

            if (i <= 0) {
                BIO_printf(bio_c_out, "DONE\n");
                ret = 0;
                goto shut;
            }

            sbuf_len -= i;
            sbuf_off += i;
            if (sbuf_len <= 0) {
                read_ssl = 1;
                write_tty = 0;
            }
        } else if (ssl_pending || FD_ISSET(SSL_get_fd(con), &readfds)) {
            k = SSL_read(con, sbuf, 1024 /* BUFSIZZ */ );

            switch (SSL_get_error(con, k)) {
            case SSL_ERROR_NONE:
                if (k <= 0)
                    goto end;
                sbuf_off = 0;
                sbuf_len = k;

                read_ssl = 0;
                write_tty = 1;
                break;
            case SSL_ERROR_WANT_ASYNC:
                BIO_printf(bio_c_out, "read A BLOCK\n");
                wait_for_async(con);
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;
            case SSL_ERROR_WANT_WRITE:
                BIO_printf(bio_c_out, "read W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;
            case SSL_ERROR_WANT_READ:
                BIO_printf(bio_c_out, "read R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;
            case SSL_ERROR_WANT_X509_LOOKUP:
                BIO_printf(bio_c_out, "read X BLOCK\n");
                break;
            case SSL_ERROR_SYSCALL:
                ret = get_last_socket_error();
                if (c_brief)
                    BIO_puts(bio_err, "CONNECTION CLOSED BY SERVER\n");
                else
                    BIO_printf(bio_err, "read:errno=%d\n", ret);
                goto shut;
            case SSL_ERROR_ZERO_RETURN:
                BIO_printf(bio_c_out, "closed\n");
                ret = 0;
                goto shut;
            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client. Treat as an error */
            case SSL_ERROR_SSL:
                ERR_print_errors(bio_err);
                goto shut;
            }
        }
        else if (FD_ISSET(fileno_stdin(), &readfds))
        {
            if (crlf) {
                int j, lf_num;

                i = raw_read_stdin(cbuf, BUFSIZZ / 2);
                lf_num = 0;
                /* both loops are skipped when i <= 0 */
                for (j = 0; j < i; j++)
                    if (cbuf[j] == '\n')
                        lf_num++;
                for (j = i - 1; j >= 0; j--) {
                    cbuf[j + lf_num] = cbuf[j];
                    if (cbuf[j] == '\n') {
                        lf_num--;
                        i++;
                        cbuf[j + lf_num] = '\r';
                    }
                }
                assert(lf_num == 0);
            } else
                i = raw_read_stdin(cbuf, BUFSIZZ);
            if (i == 0)
                at_eof = 1;

            if ((!c_ign_eof) && ((i <= 0) || (cbuf[0] == 'Q' && cmdletters))) {
                BIO_printf(bio_err, "DONE\n");
                ret = 0;
                goto shut;
            }

            if ((!c_ign_eof) && (cbuf[0] == 'R' && cmdletters)) {
                BIO_printf(bio_err, "RENEGOTIATING\n");
                SSL_renegotiate(con);
                cbuf_len = 0;
	    } else if (!c_ign_eof && (cbuf[0] == 'K' || cbuf[0] == 'k' )
                    && cmdletters) {
                BIO_printf(bio_err, "KEYUPDATE\n");
                SSL_key_update(con,
                               cbuf[0] == 'K' ? SSL_KEY_UPDATE_REQUESTED
                                              : SSL_KEY_UPDATE_NOT_REQUESTED);
                cbuf_len = 0;
            }
            else {
                cbuf_len = i;
                cbuf_off = 0;
            }

            write_ssl = 1;
            read_tty = 0;
        }
    }

    ret = 0;
 shut:
    if (in_init)
        print_stuff(bio_c_out, con, full_log);
    do_ssl_shutdown(con);

    /*
     * If we ended with an alert being sent, but still with data in the
     * network buffer to be read, then calling BIO_closesocket() will
     * result in a TCP-RST being sent. On some platforms (notably
     * Windows) then this will result in the peer immediately abandoning
     * the connection including any buffered alert data before it has
     * had a chance to be read. Shutting down the sending side first,
     * and then closing the socket sends TCP-FIN first followed by
     * TCP-RST. This seems to allow the peer to read the alert data.
     */
    shutdown(SSL_get_fd(con), 1); /* SHUT_WR */
    /*
     * We just said we have nothing else to say, but it doesn't mean that
     * the other side has nothing. It's even recommended to consume incoming
     * data. [In testing context this ensures that alerts are passed on...]
     */
    timeout.tv_sec = 0;
    timeout.tv_usec = 500000;  /* some extreme round-trip */
    do {
        FD_ZERO(&readfds);
        openssl_fdset(s, &readfds);
    } while (select(s + 1, &readfds, NULL, NULL, &timeout) > 0
             && BIO_read(sbio, sbuf, BUFSIZZ) > 0);

    BIO_closesocket(SSL_get_fd(con));
 end:
    if (con != NULL) {
        if (prexit != 0)
            print_stuff(bio_c_out, con, 1);
        SSL_free(con);
    }
    SSL_SESSION_free(psksess);
    OPENSSL_free(next_proto.data);
    SSL_CTX_free(ctx);
    X509_free(cert);
    sk_X509_CRL_pop_free(crls, X509_CRL_free);
    EVP_PKEY_free(key);
    sk_X509_pop_free(chain, X509_free);
    OPENSSL_free(pass);
    OPENSSL_free(srp_arg.srppassin);
    OPENSSL_free(sname_alloc);
    OPENSSL_free(connectstr);
    OPENSSL_free(bindstr);
    OPENSSL_free(bindhost);
    OPENSSL_free(bindport);
    OPENSSL_free(host);
    OPENSSL_free(port);
    X509_VERIFY_PARAM_free(vpm);
    sk_OPENSSL_STRING_free(ssl_args);
    sk_OPENSSL_STRING_free(dane_tlsa_rrset);
    SSL_CONF_CTX_free(cctx);
    OPENSSL_clear_free(cbuf, BUFSIZZ);
    OPENSSL_clear_free(sbuf, BUFSIZZ);
    OPENSSL_clear_free(mbuf, BUFSIZZ);
    BIO_free(bio_c_out);
    bio_c_out = NULL;
    BIO_free(bio_c_msg);
    bio_c_msg = NULL;
    return ret;
}

