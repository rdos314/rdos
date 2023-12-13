/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# test.cpp
# Secure socket test
#
########################################################################*/

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

#include "rdos.h"

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

#undef BUFSIZZ
#define BUFSIZZ 1024*8


/*##########################################################################
#
#   Name       : main
#
#   Purpose....: main program
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
    BIO *sbio;
    SSL *con = NULL;
    SSL_CONF_CTX *cctx = NULL;
    SSL_CTX *ctx = NULL;
    char *cbuf = NULL;
    char *sbuf = NULL;
    char *connectstr = NULL;
    char host[80];
    int ret = 1; 
    int in_init = 1;
    int i;
    int s = -1;
    int k;
    int write_tty;
    int read_tty;
    int write_ssl;
    int read_ssl;
    int tty_on;
    int ssl_pending;
    int cbuf_len;
    int cbuf_off;
    int sbuf_len;
    int sbuf_off;
    int n0,n1,n2,n3;
    int ip;
    int portnr;
    int key_count = 0;
    int wait = RdosCreateWait();

    int sess;
    int sockh;

    strcpy(host, "185.20.15.60");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    portnr = 443;

//    s = BIO_open_socket(ip, portnr);

    sess = RdosCreateSecureSession();

    sockh = RdosCreateSecureConnection(sess, ip, 0, portnr, 5000, 0x1000);

    RdosCloseSecureSession(sess);

    cctx = SSL_CONF_CTX_new();

    cbuf = (char *)OPENSSL_malloc(BUFSIZZ);
    sbuf = (char *)OPENSSL_malloc(BUFSIZZ);

    SSL_CONF_CTX_set_flags(cctx, SSL_CONF_FLAG_CLIENT | SSL_CONF_FLAG_CMDLINE);

    connectstr = OPENSSL_strdup(argv[1]);

//    BIO_parse_hostserv(connectstr, &host, &port, BIO_PARSE_PRIO_HOST);

    ctx = SSL_CTX_new(TLS_client_method());

    SSL_CTX_clear_mode(ctx, SSL_MODE_AUTO_RETRY);
    SSL_CONF_CTX_set_ssl_ctx(cctx, ctx);

    SSL_CTX_set_default_ctlog_list_file(ctx);
    SSL_CTX_set_default_verify_file(ctx);
    SSL_CTX_set_default_verify_dir(ctx);

    SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_CLIENT | SSL_SESS_CACHE_NO_INTERNAL_STORE);

    con = SSL_new(ctx);

    s = BIO_open_socket(ip, portnr);

    printf("CONNECTED(%08X)\n", s);

    sbio = BIO_new_socket(s, BIO_NOCLOSE);

    SSL_set_bio(con, sbio, sbio);
    SSL_set_connect_state(con);

    RdosAddWaitForTcpConnection(wait, SSL_get_handle(con), 2);
    RdosAddWaitForKeyboard(wait, 1);

    read_tty = 1;
    write_tty = 0;
    tty_on = 0;
    read_ssl = 1;
    write_ssl = 1;

    cbuf_len = 0;
    cbuf_off = 0;
    sbuf_len = 0;
    sbuf_off = 0;

    for (;;) 
    {
        if (!SSL_is_init_finished(con) && SSL_total_renegotiations(con) == 0
                && SSL_get_key_update_type(con) == SSL_KEY_UPDATE_NONE) 
        {
            in_init = 1;
            tty_on = 0;
        } 
        else 
        {
            tty_on = 1;

            if (in_init)
                in_init = 0;

        }

        ssl_pending = read_ssl && SSL_has_pending(con);

        if (!ssl_pending) 
        {
            if (write_ssl)
            {
                if (RdosGetTcpConnectionWriteSpace(SSL_get_handle(con)) == 0)
                    RdosWaitMilli(25);
            }
            else
                RdosWaitForever(wait);
        }

        if (!ssl_pending && write_ssl && RdosGetTcpConnectionWriteSpace(SSL_get_handle(con))) 
        {
            k = SSL_write(con, &(cbuf[cbuf_off]), (unsigned int)cbuf_len);
            switch (SSL_get_error(con, k)) 
            {
            case SSL_ERROR_NONE:
                cbuf_off += k;
                cbuf_len -= k;
                if (k <= 0)
                    goto end;
                /* we have done a  write(con,NULL,0); */
                if (cbuf_len <= 0) 
                {
                    read_tty = 1;
                    write_ssl = 0;
                } 
                else 
                {        /* if (cbuf_len > 0) */

                    read_tty = 0;
                    write_ssl = 1;
                }
                break;

            case SSL_ERROR_WANT_WRITE:
                printf("write W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_ASYNC:
                printf("write A BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_READ:
                printf("write R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                write_ssl = 0;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
                printf("write X BLOCK\n");
                break;

            case SSL_ERROR_ZERO_RETURN:
                if (cbuf_len != 0) 
                {
                    printf("shutdown\n");
                    ret = 0;
                    goto shut;
                } 
                else 
                {
                    read_tty = 1;
                    write_ssl = 0;
                    break;
                }

            case SSL_ERROR_SYSCALL:
                if ((k != 0) || (cbuf_len != 0)) 
                {
                    printf("Socket error\n");
                    goto shut;
                } 
                else 
                {
                    read_tty = 1;
                    write_ssl = 0;
                }
                break;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client - treat as an error */

            case SSL_ERROR_SSL:
                printf("SSL error\r\n");
                goto shut;
            }
        }
        else if (!ssl_pending && write_tty)
        {
            printf(sbuf + sbuf_off);
            sbuf_len = 0;
            sbuf_off = 0;
            read_ssl = 1;
            write_tty = 0;
        } 
        else if (ssl_pending || RdosPollTcpConnection(SSL_get_handle(con)))
        {
            k = SSL_read(con, sbuf, 1024 /* BUFSIZZ */ );

            switch (SSL_get_error(con, k)) 
            {
            case SSL_ERROR_NONE:
                if (k <= 0)
                    goto end;
                sbuf_off = 0;
                sbuf_len = k;

                read_ssl = 0;
                write_tty = 1;
                break;

            case SSL_ERROR_WANT_ASYNC:
                printf("read A BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;

            case SSL_ERROR_WANT_WRITE:
                printf("read W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_READ:
                printf("read R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
                printf("read X BLOCK\n");
                break;

            case SSL_ERROR_SYSCALL:
                printf("CONNECTION CLOSED BY SERVER\n");
                goto shut;

            case SSL_ERROR_ZERO_RETURN:
                printf("closed\n");
                ret = 0;
                goto shut;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client. Treat as an error */

            case SSL_ERROR_SSL:
                printf("SSL error\n");
                goto shut;

            }
        }
        else if (read_tty && RdosPollKeyboard())
        {
            char ch = (char)RdosReadKeyboard();
            printf("%c", ch);

            if (ch == 0xd)
            {
                cbuf[key_count] = 0xd;
                cbuf[key_count+1] = 0xa;
                cbuf_len = key_count + 2;
                key_count = 0;
                cbuf_off = 0;
                write_ssl = 1;
                read_tty = 0;
            }
            else
            {
                cbuf[key_count] = ch;
                key_count++;
            }
        }
    }

    ret = 0;

 shut:
    ret = SSL_shutdown(con);
    RdosCloseWait(wait);
    shutdown(SSL_get_handle(con), 1); /* SHUT_WR */
    BIO_closesocket(SSL_get_handle(con));

 end:
    if (con != NULL)
        SSL_free(con);

    SSL_CTX_free(ctx);
    OPENSSL_free(connectstr);
//    OPENSSL_free(host);
//    OPENSSL_free(port);
    SSL_CONF_CTX_free(cctx);
    OPENSSL_clear_free(cbuf, BUFSIZZ);
    OPENSSL_clear_free(sbuf, BUFSIZZ);
    return ret;
}
