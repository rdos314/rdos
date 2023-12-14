/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
# ssl.c
# SSL device
#
########################################################################*/

#include "e_os.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <float.h>
#include <time.h>
#include <sys/time.h>
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

#include "rdos.h"
#include "rdosdev.h"

#define BUFSIZZ 1024*8
#define MAX_SESSION_COUNT 16

int ClientCount = 0;
SSL_CONF_CTX *ClientConf = NULL;

void InitSecure();

void AssertBreak(char *func, char *fn, int line_num);
#pragma aux AssertBreak parm routine [fs esi] [es edi] [ecx]

/*##########################################################################
#
#   Name       : CreateClientSession
#
#   Purpose....: Create client session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CreateClientSession "*" rdosdev parm routine value [dx edi]
SSL_CTX *CreateClientSession()
{
    void *p;
    SSL_CTX *ctx = NULL;

    if (ClientCount == 0)
    {
        ClientConf = SSL_CONF_CTX_new();
        SSL_CONF_CTX_set_flags(ClientConf, SSL_CONF_FLAG_CLIENT | SSL_CONF_FLAG_CMDLINE);
    }

    ClientCount++;

    ctx = SSL_CTX_new(TLS_client_method());

    if (ctx)
    {
        SSL_CTX_clear_mode(ctx, SSL_MODE_AUTO_RETRY);
        SSL_CONF_CTX_set_ssl_ctx(ClientConf, ctx);

        SSL_CTX_set_default_ctlog_list_file(ctx);
        SSL_CTX_set_default_verify_file(ctx);
        SSL_CTX_set_default_verify_dir(ctx);

        SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_CLIENT | SSL_SESS_CACHE_NO_INTERNAL_STORE);
    }

    return ctx;
}

/*##########################################################################
#
#   Name       : FreeClientSession
#
#   Purpose....: Free client session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux FreeClientSession "*" rdosdev parm routine [es edi]
void FreeClientSession(SSL_CTX *ctx)
{
    if (ctx)
    {
        SSL_CTX_free(ctx);

        ClientCount--;

        if (ClientCount == 0)
        {
            SSL_CONF_CTX_free(ClientConf);
            ClientConf = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : CreateClientConnection
#
#   Purpose....: Create client connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CreateClientConnection "*" rdosdev parm routine [es edi] [ebx] value [dx edi]
SSL *CreateClientConnection(SSL_CTX *ctx, int sock)
{
    SSL *con = NULL;
    BIO *sbio;

    sbio = BIO_new_socket(sock, BIO_NOCLOSE);
    con = SSL_new(ctx);

    SSL_set_bio(con, sbio, sbio);
    SSL_set_connect_state(con);

    return con;
}

/*##########################################################################
#
#   Name       : FreeClientConnection
#
#   Purpose....: Free client connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux FreeClientConnection "*" rdosdev parm routine [es edi]
void FreeClientConnection(SSL *con)
{
    if (con)
    {
        SSL_shutdown(con);
        SSL_free(con);
    }
}

/*##########################################################################
#
#   Name       : HandleClientConnection
#
#   Purpose....: Handle client connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux HandleClientConnection "*" rdosdev parm routine [es edi]
void HandleClientConnection(SSL *con)
{
    char *cbuf = NULL;
    char *sbuf = NULL;
    char *connectstr = NULL;
    char *host = NULL;
    char *port = NULL;
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
    int key_count = 0;
    int wait = RdosCreateWait();

    cbuf = (char *)OPENSSL_malloc(BUFSIZZ);
    sbuf = (char *)OPENSSL_malloc(BUFSIZZ);

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
                    return;
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
                RdosWriteString("write W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_ASYNC:
                RdosWriteString("write A BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_READ:
                RdosWriteString("write R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                write_ssl = 0;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
                RdosWriteString("write X BLOCK\n");
                break;

            case SSL_ERROR_ZERO_RETURN:
                if (cbuf_len != 0) 
                {
                    RdosWriteString("shutdown\n");
                    ret = 0;
                    return;
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
                    RdosWriteString("Socket error\n");
                    return;
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
                RdosWriteString("SSL error\r\n");
                return;
            }
        }
        else if (!ssl_pending && write_tty)
        {
            RdosWriteString(sbuf + sbuf_off);
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
                    return;
                sbuf_off = 0;
                sbuf_len = k;

                read_ssl = 0;
                write_tty = 1;
                break;

            case SSL_ERROR_WANT_ASYNC:
                RdosWriteString("read A BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;

            case SSL_ERROR_WANT_WRITE:
                RdosWriteString("read W BLOCK\n");
                write_ssl = 1;
                read_tty = 0;
                break;

            case SSL_ERROR_WANT_READ:
                RdosWriteString("read R BLOCK\n");
                write_tty = 0;
                read_ssl = 1;
                if ((read_tty == 0) && (write_ssl == 0))
                    write_ssl = 1;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
                RdosWriteString("read X BLOCK\n");
                break;

            case SSL_ERROR_SYSCALL:
                RdosWriteString("CONNECTION CLOSED BY SERVER\n");
                return;

            case SSL_ERROR_ZERO_RETURN:
                RdosWriteString("closed\n");
                ret = 0;
                return;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client. Treat as an error */

            case SSL_ERROR_SSL:
                RdosWriteString("SSL error\n");
                return;

            }
        }
        else if (read_tty && RdosPollKeyboard())
        {
            char ch = (char)RdosReadKeyboard();
            RdosWriteChar(ch);

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
}

/*##########################################################################
#
#   Name       : BIO_closesocket
#
#   Purpose....: Close socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int BIO_closesocket(int sock)
{
    RdosCloseTcpConnection(sock);
    return 1;
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    InitSecure();
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosHookInitTasking(&InitTasking);
}
