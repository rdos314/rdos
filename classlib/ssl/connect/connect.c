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
#include <openssl/e_os2.h>
#include "apps.h"
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
#include "s_apps.h"
#include "timeouts.h"
#include "internal/sockets.h"

#undef BUFSIZZ
#define BUFSIZZ 1024*8
#define S_CLIENT_IRC_READ_TIMEOUT 8

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

static int saved_errno;
char *default_config_file = NULL;
char *psk_key = NULL;
BIO *bio_in = NULL;
BIO *bio_out = NULL;
BIO *bio_err = NULL;

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

static void save_errno(void)
{
    saved_errno = errno;
    errno = 0;
}

static int restore_errno(void)
{
    int ret = errno;
    errno = saved_errno;
    return ret;
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

/* Default PSK identity and key */
static char *psk_identity = "Client_identity";

static unsigned int psk_client_cb(SSL *ssl, const char *hint, char *identity,
                                  unsigned int max_identity_len,
                                  unsigned char *psk,
                                  unsigned int max_psk_len)
{
    int ret;
    long key_len;
    unsigned char *key;

    if (c_debug)
        BIO_printf(bio_c_out, "psk_client_cb\n");
    if (!hint) {
        /* no ServerKeyExchange message */
        if (c_debug)
            BIO_printf(bio_c_out,
                       "NULL received PSK identity hint, continuing anyway\n");
    } else if (c_debug) {
        BIO_printf(bio_c_out, "Received PSK identity hint '%s'\n", hint);
    }

    /*
     * lookup PSK identity and PSK key based on the given identity hint here
     */
    ret = BIO_snprintf(identity, max_identity_len, "%s", psk_identity);
    if (ret < 0 || (unsigned int)ret > max_identity_len)
        goto out_err;
    if (c_debug)
        BIO_printf(bio_c_out, "created identity '%s' len=%d\n", identity,
                   ret);

    /* convert the PSK key to binary */
    key = OPENSSL_hexstr2buf(psk_key, &key_len);
    if (key == NULL) {
        BIO_printf(bio_err, "Could not convert PSK key '%s' to buffer\n",
                   psk_key);
        return 0;
    }
    if (max_psk_len > INT_MAX || key_len > (long)max_psk_len) {
        BIO_printf(bio_err,
                   "psk buffer of callback is too small (%d) for key (%ld)\n",
                   max_psk_len, key_len);
        OPENSSL_free(key);
        return 0;
    }

    memcpy(psk, key, key_len);
    OPENSSL_free(key);

    if (c_debug)
        BIO_printf(bio_c_out, "created PSK len=%ld\n", key_len);

    return key_len;
 out_err:
    if (c_debug)
        BIO_printf(bio_err, "Error in PSK client callback\n");
    return 0;
}

const unsigned char tls13_aes128gcmsha256_id[] = { 0x13, 0x01 };
const unsigned char tls13_aes256gcmsha384_id[] = { 0x13, 0x02 };

static int psk_use_session_cb(SSL *s, const EVP_MD *md,
                              const unsigned char **id, size_t *idlen,
                              SSL_SESSION **sess)
{
    SSL_SESSION *usesess = NULL;
    const SSL_CIPHER *cipher = NULL;

    if (psksess != NULL) {
        SSL_SESSION_up_ref(psksess);
        usesess = psksess;
    } else {
        long key_len;
        unsigned char *key = OPENSSL_hexstr2buf(psk_key, &key_len);

        if (key == NULL) {
            BIO_printf(bio_err, "Could not convert PSK key '%s' to buffer\n",
                       psk_key);
            return 0;
        }

        /* We default to SHA-256 */
        cipher = SSL_CIPHER_find(s, tls13_aes128gcmsha256_id);
        if (cipher == NULL) {
            BIO_printf(bio_err, "Error finding suitable ciphersuite\n");
            OPENSSL_free(key);
            return 0;
        }

        usesess = SSL_SESSION_new();
        if (usesess == NULL
                || !SSL_SESSION_set1_master_key(usesess, key, key_len)
                || !SSL_SESSION_set_cipher(usesess, cipher)
                || !SSL_SESSION_set_protocol_version(usesess, TLS1_3_VERSION)) {
            OPENSSL_free(key);
            goto err;
        }
        OPENSSL_free(key);
    }

    cipher = SSL_SESSION_get0_cipher(usesess);
    if (cipher == NULL)
        goto err;

    if (md != NULL && SSL_CIPHER_get_handshake_digest(cipher) != md) {
        /* PSK not usable, ignore it */
        *id = NULL;
        *idlen = 0;
        *sess = NULL;
        SSL_SESSION_free(usesess);
    } else {
        *sess = usesess;
        *id = (unsigned char *)psk_identity;
        *idlen = strlen(psk_identity);
    }

    return 1;

 err:
    SSL_SESSION_free(usesess);
    return 0;
}

/* This is a context that we pass to callbacks */
typedef struct tlsextctx_st {
    BIO *biodebug;
    int ack;
} tlsextctx;

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

static int srp_Verify_N_and_g(const BIGNUM *N, const BIGNUM *g)
{
    BN_CTX *bn_ctx = BN_CTX_new();
    BIGNUM *p = BN_new();
    BIGNUM *r = BN_new();
    int ret =
        g != NULL && N != NULL && bn_ctx != NULL && BN_is_odd(N) &&
        BN_is_prime_ex(N, SRP_NUMBER_ITERATIONS_FOR_PRIME, bn_ctx, NULL) == 1 &&
        p != NULL && BN_rshift1(p, N) &&
        /* p = (N-1)/2 */
        BN_is_prime_ex(p, SRP_NUMBER_ITERATIONS_FOR_PRIME, bn_ctx, NULL) == 1 &&
        r != NULL &&
        /* verify g^((N-1)/2) == -1 (mod N) */
        BN_mod_exp(r, g, p, N, bn_ctx) &&
        BN_add_word(r, 1) && BN_cmp(r, N) == 0;

    BN_free(r);
    BN_free(p);
    BN_CTX_free(bn_ctx);
    return ret;
}

/*-
 * This callback is used here for two purposes:
 * - extended debugging
 * - making some primality tests for unknown groups
 * The callback is only called for a non default group.
 *
 * An application does not need the call back at all if
 * only the standard groups are used.  In real life situations,
 * client and server already share well known groups,
 * thus there is no need to verify them.
 * Furthermore, in case that a server actually proposes a group that
 * is not one of those defined in RFC 5054, it is more appropriate
 * to add the group to a static list and then compare since
 * primality tests are rather cpu consuming.
 */

static int ssl_srp_verify_param_cb(SSL *s, void *arg)
{
    SRP_ARG *srp_arg = (SRP_ARG *)arg;
    BIGNUM *N = NULL, *g = NULL;

    if (((N = SSL_get_srp_N(s)) == NULL) || ((g = SSL_get_srp_g(s)) == NULL))
        return 0;
    if (srp_arg->debug || srp_arg->msg || srp_arg->amp == 1) {
        BIO_printf(bio_err, "SRP parameters:\n");
        BIO_printf(bio_err, "\tN=");
        BN_print(bio_err, N);
        BIO_printf(bio_err, "\n\tg=");
        BN_print(bio_err, g);
        BIO_printf(bio_err, "\n");
    }

    if (SRP_check_known_gN_param(g, N))
        return 1;

    if (srp_arg->amp == 1) {
        if (srp_arg->debug)
            BIO_printf(bio_err,
                       "SRP param N and g are not known params, going to check deeper.\n");

        /*
         * The srp_moregroups is a real debugging feature. Implementors
         * should rather add the value to the known ones. The minimal size
         * has already been tested.
         */
        if (BN_num_bits(g) <= BN_BITS && srp_Verify_N_and_g(N, g))
            return 1;
    }
    BIO_printf(bio_err, "SRP param N and g rejected.\n");
    return 0;
}


/* This the context that we pass to next_proto_cb */
typedef struct tlsextnextprotoctx_st {
    unsigned char *data;
    size_t len;
    int status;
} tlsextnextprotoctx;

static tlsextnextprotoctx next_proto;

static int next_proto_cb(SSL *s, unsigned char **out, unsigned char *outlen,
                         const unsigned char *in, unsigned int inlen,
                         void *arg)
{
    tlsextnextprotoctx *ctx = arg;

    if (!c_quiet) {
        /* We can assume that |in| is syntactically valid. */
        unsigned i;
        BIO_printf(bio_c_out, "Protocols advertised by server: ");
        for (i = 0; i < inlen;) {
            if (i)
                BIO_write(bio_c_out, ", ", 2);
            BIO_write(bio_c_out, &in[i + 1], in[i]);
            i += in[i] + 1;
        }
        BIO_write(bio_c_out, "\n", 1);
    }

    ctx->status =
        SSL_select_next_proto(out, outlen, in, inlen, ctx->data, ctx->len);
    return SSL_TLSEXT_ERR_OK;
}

static int serverinfo_cli_parse_cb(SSL *s, unsigned int ext_type,
                                   const unsigned char *in, size_t inlen,
                                   int *al, void *arg)
{
    char pem_name[100];
    unsigned char ext_buf[4 + 65536];

    /* Reconstruct the type/len fields prior to extension data */
    inlen &= 0xffff; /* for formal memcmpy correctness */
    ext_buf[0] = (unsigned char)(ext_type >> 8);
    ext_buf[1] = (unsigned char)(ext_type);
    ext_buf[2] = (unsigned char)(inlen >> 8);
    ext_buf[3] = (unsigned char)(inlen);
    memcpy(ext_buf + 4, in, inlen);

    BIO_snprintf(pem_name, sizeof(pem_name), "SERVERINFO FOR EXTENSION %d",
                 ext_type);
    PEM_write_bio(bio_c_out, pem_name, "", ext_buf, 4 + inlen);
    return 1;
}

/*
 * Hex decoder that tolerates optional whitespace.  Returns number of bytes
 * produced, advances inptr to end of input string.
 */
static ossl_ssize_t hexdecode(const char **inptr, void *result)
{
    unsigned char **out = (unsigned char **)result;
    const char *in = *inptr;
    unsigned char *ret = app_malloc(strlen(in) / 2, "hexdecode");
    unsigned char *cp = ret;
    uint8_t byte;
    int nibble = 0;

    if (ret == NULL)
        return -1;

    for (byte = 0; *in; ++in) {
        int x;

        if (isspace(_UC(*in)))
            continue;
        x = OPENSSL_hexchar2int(*in);
        if (x < 0) {
            OPENSSL_free(ret);
            return 0;
        }
        byte |= (char)x;
        if ((nibble ^= 1) == 0) {
            *cp++ = byte;
            byte = 0;
        } else {
            byte <<= 4;
        }
    }
    if (nibble != 0) {
        OPENSSL_free(ret);
        return 0;
    }
    *inptr = in;

    return cp - (*out = ret);
}

/*
 * Decode unsigned 0..255, returns 1 on success, <= 0 on failure. Advances
 * inptr to next field skipping leading whitespace.
 */
static ossl_ssize_t checked_uint8(const char **inptr, void *out)
{
    uint8_t *result = (uint8_t *)out;
    const char *in = *inptr;
    char *endp;
    long v;
    int e;

    save_errno();
    v = strtol(in, &endp, 10);
    e = restore_errno();

    if (((v == LONG_MIN || v == LONG_MAX) && e == ERANGE) ||
        endp == in || !isspace(_UC(*endp)) ||
        v != (*result = (uint8_t) v)) {
        return -1;
    }
    for (in = endp; isspace(_UC(*in)); ++in)
        continue;

    *inptr = in;
    return 1;
}

struct tlsa_field {
    void *var;
    const char *name;
    ossl_ssize_t (*parser)(const char **, void *);
};

static int tlsa_import_rr(SSL *con, const char *rrdata)
{
    /* Not necessary to re-init these values; the "parsers" do that. */
    static uint8_t usage;
    static uint8_t selector;
    static uint8_t mtype;
    static unsigned char *data;
    static struct tlsa_field tlsa_fields[] = {
        { &usage, "usage", checked_uint8 },
        { &selector, "selector", checked_uint8 },
        { &mtype, "mtype", checked_uint8 },
        { &data, "data", hexdecode },
        { NULL, }
    };
    struct tlsa_field *f;
    int ret;
    const char *cp = rrdata;
    ossl_ssize_t len = 0;

    for (f = tlsa_fields; f->var; ++f) {
        /* Returns number of bytes produced, advances cp to next field */
        if ((len = f->parser(&cp, f->var)) <= 0) {
            BIO_printf(bio_err, "%s: warning: bad TLSA %s field in: %s\n",
                       prog, f->name, rrdata);
            return 0;
        }
    }
    /* The data field is last, so len is its length */
    ret = SSL_dane_tlsa_add(con, usage, selector, mtype, data, len);
    OPENSSL_free(data);

    if (ret == 0) {
        ERR_print_errors(bio_err);
        BIO_printf(bio_err, "%s: warning: unusable TLSA rrdata: %s\n",
                   prog, rrdata);
        return 0;
    }
    if (ret < 0) {
        ERR_print_errors(bio_err);
        BIO_printf(bio_err, "%s: warning: error loading TLSA rrdata: %s\n",
                   prog, rrdata);
        return 0;
    }
    return ret;
}

static int tlsa_import_rrset(SSL *con, STACK_OF(OPENSSL_STRING) *rrset)
{
    int num = sk_OPENSSL_STRING_num(rrset);
    int count = 0;
    int i;

    for (i = 0; i < num; ++i) {
        char *rrdata = sk_OPENSSL_STRING_value(rrset, i);
        if (tlsa_import_rr(con, rrdata) > 0)
            ++count;
    }
    return count > 0;
}

#define IS_INET_FLAG(o) \
 (o == OPT_4 || o == OPT_6 || o == OPT_HOST || o == OPT_PORT || o == OPT_CONNECT)
#define IS_UNIX_FLAG(o) (o == OPT_UNIX)

#define IS_PROT_FLAG(o) \
 (o == OPT_SSL3 || o == OPT_TLS1 || o == OPT_TLS1_1 || o == OPT_TLS1_2 \
  || o == OPT_TLS1_3 || o == OPT_DTLS || o == OPT_DTLS1 || o == OPT_DTLS1_2)

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

    cbuf = app_malloc(BUFSIZZ, "cbuf");
    sbuf = app_malloc(BUFSIZZ, "sbuf");
    mbuf = app_malloc(BUFSIZZ, "mbuf");

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

    if (sdebug)
        ssl_ctx_security_debug(ctx, sdebug);

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

    if (protocol == IPPROTO_SCTP && sctp_label_bug == 1)
        SSL_CTX_set_mode(ctx, SSL_MODE_DTLS_SCTP_LABEL_LENGTH_BUG);

    if (min_version != 0
        && SSL_CTX_set_min_proto_version(ctx, min_version) == 0)
        goto end;
    if (max_version != 0
        && SSL_CTX_set_max_proto_version(ctx, max_version) == 0)
        goto end;

    if (vpmtouched && !SSL_CTX_set1_param(ctx, vpm)) {
        BIO_printf(bio_err, "Error setting verify params\n");
        ERR_print_errors(bio_err);
        goto end;
    }

    if (async) {
        SSL_CTX_set_mode(ctx, SSL_MODE_ASYNC);
    }

    if (max_send_fragment > 0
        && !SSL_CTX_set_max_send_fragment(ctx, max_send_fragment)) {
        BIO_printf(bio_err, "%s: Max send fragment size %u is out of permitted range\n",
                   prog, max_send_fragment);
        goto end;
    }

    if (split_send_fragment > 0
        && !SSL_CTX_set_split_send_fragment(ctx, split_send_fragment)) {
        BIO_printf(bio_err, "%s: Split send fragment size %u is out of permitted range\n",
                   prog, split_send_fragment);
        goto end;
    }

    if (max_pipelines > 0
        && !SSL_CTX_set_max_pipelines(ctx, max_pipelines)) {
        BIO_printf(bio_err, "%s: Max pipelines %u is out of permitted range\n",
                   prog, max_pipelines);
        goto end;
    }

    if (read_buf_len > 0) {
        SSL_CTX_set_default_read_buffer_len(ctx, read_buf_len);
    }

    if (maxfraglen > 0
            && !SSL_CTX_set_tlsext_max_fragment_length(ctx, maxfraglen)) {
        BIO_printf(bio_err,
                   "%s: Max Fragment Length code %u is out of permitted values"
                   "\n", prog, maxfraglen);
        goto end;
    }

    if (!ssl_load_stores(ctx, vfyCApath, vfyCAfile, chCApath, chCAfile,
                         crls, crl_download)) {
        BIO_printf(bio_err, "Error loading store locations\n");
        ERR_print_errors(bio_err);
        goto end;
    }
    if (ReqCAfile != NULL) {
        STACK_OF(X509_NAME) *nm = sk_X509_NAME_new_null();

        if (nm == NULL || !SSL_add_file_cert_subjects_to_stack(nm, ReqCAfile)) {
            sk_X509_NAME_pop_free(nm, X509_NAME_free);
            BIO_printf(bio_err, "Error loading CA names\n");
            ERR_print_errors(bio_err);
            goto end;
        }
        SSL_CTX_set0_CA_list(ctx, nm);
    }

    if (ssl_client_engine) {
        if (!SSL_CTX_set_client_cert_engine(ctx, ssl_client_engine)) {
            BIO_puts(bio_err, "Error setting client auth engine\n");
            ERR_print_errors(bio_err);
            ENGINE_free(ssl_client_engine);
            goto end;
        }
        ENGINE_free(ssl_client_engine);
    }

    if (psk_key != NULL) {
        if (c_debug)
            BIO_printf(bio_c_out, "PSK key given, setting client callback\n");
        SSL_CTX_set_psk_client_callback(ctx, psk_client_cb);
    }

    if (psksessf != NULL) {
        BIO *stmp = BIO_new_file(psksessf, "r");

        if (stmp == NULL) {
            BIO_printf(bio_err, "Can't open PSK session file %s\n", psksessf);
            ERR_print_errors(bio_err);
            goto end;
        }
        psksess = PEM_read_bio_SSL_SESSION(stmp, NULL, 0, NULL);
        BIO_free(stmp);
        if (psksess == NULL) {
            BIO_printf(bio_err, "Can't read PSK session file %s\n", psksessf);
            ERR_print_errors(bio_err);
            goto end;
        }
    }
    if (psk_key != NULL || psksess != NULL)
        SSL_CTX_set_psk_use_session_callback(ctx, psk_use_session_cb);

    if (srtp_profiles != NULL) {
        /* Returns 0 on success! */
        if (SSL_CTX_set_tlsext_use_srtp(ctx, srtp_profiles) != 0) {
            BIO_printf(bio_err, "Error setting SRTP profile\n");
            ERR_print_errors(bio_err);
            goto end;
        }
    }

    if (exc != NULL)
        ssl_ctx_set_excert(ctx, exc);

    if (next_proto.data != NULL)
        SSL_CTX_set_next_proto_select_cb(ctx, next_proto_cb, &next_proto);

    if (state)
        SSL_CTX_set_info_callback(ctx, apps_ssl_info_callback);

    /* Enable SCT processing, without early connection termination */
    if (ct_validation &&
        !SSL_CTX_enable_ct(ctx, SSL_CT_VALIDATION_PERMISSIVE)) {
        ERR_print_errors(bio_err);
        goto end;
    }

    if (!ctx_set_ctlog_list_file(ctx, ctlog_file)) {
        if (ct_validation) {
            ERR_print_errors(bio_err);
            goto end;
        }

        /*
         * If CT validation is not enabled, the log list isn't needed so don't
         * show errors or abort. We try to load it regardless because then we
         * can show the names of the logs any SCTs came from (SCTs may be seen
         * even with validation disabled).
         */
        ERR_clear_error();
    }

    SSL_CTX_set_verify(ctx, verify, verify_callback);

    if (!ctx_set_verify_locations(ctx, CAfile, CApath, noCAfile, noCApath)) {
        ERR_print_errors(bio_err);
        goto end;
    }

    ssl_ctx_add_crls(ctx, crls, crl_download);

    if (!set_cert_key_stuff(ctx, cert, key, chain, build_chain))
        goto end;

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

    if (set_keylog_file(ctx, keylog_file))
        goto end;

    con = SSL_new(ctx);
    if (con == NULL)
        goto end;

    if (enable_pha)
        SSL_set_post_handshake_auth(con, 1);

    if (sess_in != NULL) {
        SSL_SESSION *sess;
        BIO *stmp = BIO_new_file(sess_in, "r");
        if (stmp == NULL) {
            BIO_printf(bio_err, "Can't open session file %s\n", sess_in);
            ERR_print_errors(bio_err);
            goto end;
        }
        sess = PEM_read_bio_SSL_SESSION(stmp, NULL, 0, NULL);
        BIO_free(stmp);
        if (sess == NULL) {
            BIO_printf(bio_err, "Can't open session file %s\n", sess_in);
            ERR_print_errors(bio_err);
            goto end;
        }
        if (!SSL_set_session(con, sess)) {
            BIO_printf(bio_err, "Can't set session\n");
            ERR_print_errors(bio_err);
            goto end;
        }

        SSL_SESSION_free(sess);
    }

    if (fallback_scsv)
        SSL_set_mode(con, SSL_MODE_SEND_FALLBACK_SCSV);

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

    if (dane_tlsa_domain != NULL) {
        if (SSL_dane_enable(con, dane_tlsa_domain) <= 0) {
            BIO_printf(bio_err, "%s: Error enabling DANE TLSA "
                       "authentication.\n", prog);
            ERR_print_errors(bio_err);
            goto end;
        }
        if (dane_tlsa_rrset == NULL) {
            BIO_printf(bio_err, "%s: DANE TLSA authentication requires at "
                       "least one -dane_tlsa_rrdata option.\n", prog);
            goto end;
        }
        if (tlsa_import_rrset(con, dane_tlsa_rrset) <= 0) {
            BIO_printf(bio_err, "%s: Failed to import any TLSA "
                       "records.\n", prog);
            goto end;
        }
        if (dane_ee_no_name)
            SSL_dane_set_flags(con, DANE_FLAG_NO_DANE_EE_NAMECHECKS);
    } else if (dane_tlsa_rrset != NULL) {
        BIO_printf(bio_err, "%s: DANE TLSA authentication requires the "
                   "-dane_tlsa_domain option.\n", prog);
        goto end;
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

    if (isdtls) {
        union BIO_sock_info_u peer_info;

        sbio = BIO_new_dgram(s, BIO_NOCLOSE);

        if ((peer_info.addr = BIO_ADDR_new()) == NULL) {
            BIO_printf(bio_err, "memory allocation failure\n");
            BIO_closesocket(s);
            goto end;
        }
        if (!BIO_sock_info(s, BIO_SOCK_INFO_ADDRESS, &peer_info)) {
            BIO_printf(bio_err, "getsockname:errno=%d\n",
                       get_last_socket_error());
            BIO_ADDR_free(peer_info.addr);
            BIO_closesocket(s);
            goto end;
        }

        (void)BIO_ctrl_set_connected(sbio, peer_info.addr);
        BIO_ADDR_free(peer_info.addr);
        peer_info.addr = NULL;

        if (enable_timeouts) {
            timeout.tv_sec = 0;
            timeout.tv_usec = DGRAM_RCV_TIMEOUT;
            BIO_ctrl(sbio, BIO_CTRL_DGRAM_SET_RECV_TIMEOUT, 0, &timeout);

            timeout.tv_sec = 0;
            timeout.tv_usec = DGRAM_SND_TIMEOUT;
            BIO_ctrl(sbio, BIO_CTRL_DGRAM_SET_SEND_TIMEOUT, 0, &timeout);
        }

        if (socket_mtu) {
            if (socket_mtu < DTLS_get_link_min_mtu(con)) {
                BIO_printf(bio_err, "MTU too small. Must be at least %ld\n",
                           DTLS_get_link_min_mtu(con));
                BIO_free(sbio);
                goto shut;
            }
            SSL_set_options(con, SSL_OP_NO_QUERY_MTU);
            if (!DTLS_set_link_mtu(con, socket_mtu)) {
                BIO_printf(bio_err, "Failed to set MTU\n");
                BIO_free(sbio);
                goto shut;
            }
        } else {
            /* want to do MTU discovery */
            BIO_ctrl(sbio, BIO_CTRL_DGRAM_MTU_DISCOVER, 0, NULL);
        }
    } else
        sbio = BIO_new_socket(s, BIO_NOCLOSE);

    if (nbio_test) {
        BIO *test;

        test = BIO_new(BIO_f_nbio_test());
        sbio = BIO_push(test, sbio);
    }

    if (c_debug) {
        BIO_set_callback(sbio, bio_dump_callback);
        BIO_set_callback_arg(sbio, (char *)bio_c_out);
    }
    if (c_msg) {
        SSL_set_msg_callback(con, msg_cb);
        SSL_set_msg_callback_arg(con, bio_c_msg ? bio_c_msg : bio_c_out);
    }

    if (c_tlsextdebug) {
        SSL_set_tlsext_debug_callback(con, tlsext_cb);
        SSL_set_tlsext_debug_arg(con, bio_c_out);
    }

    if (c_status_req) {
        SSL_set_tlsext_status_type(con, TLSEXT_STATUSTYPE_ocsp);
        SSL_CTX_set_tlsext_status_cb(ctx, ocsp_resp_cb);
        SSL_CTX_set_tlsext_status_arg(ctx, bio_c_out);
    }

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

    if (early_data_file != NULL
            && ((SSL_get0_session(con) != NULL
                 && SSL_SESSION_get_max_early_data(SSL_get0_session(con)) > 0)
                || (psksess != NULL
                    && SSL_SESSION_get_max_early_data(psksess) > 0))) {
        BIO *edfile = BIO_new_file(early_data_file, "r");
        size_t readbytes, writtenbytes;
        int finish = 0;

        if (edfile == NULL) {
            BIO_printf(bio_err, "Cannot open early data file\n");
            goto shut;
        }

        while (!finish) {
            if (!BIO_read_ex(edfile, cbuf, BUFSIZZ, &readbytes))
                finish = 1;

            while (!SSL_write_early_data(con, cbuf, readbytes, &writtenbytes)) {
                switch (SSL_get_error(con, 0)) {
                case SSL_ERROR_WANT_WRITE:
                case SSL_ERROR_WANT_ASYNC:
                case SSL_ERROR_WANT_READ:
                    /* Just keep trying - busy waiting */
                    continue;
                default:
                    BIO_printf(bio_err, "Error writing early data\n");
                    BIO_free(edfile);
                    ERR_print_errors(bio_err);
                    goto shut;
                }
            }
        }

        BIO_free(edfile);
    }

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
    set_keylog_file(NULL, NULL);
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
    ssl_excert_free(exc);
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
        exportedkeymat = app_malloc(keymatexportlen, "export key");
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
