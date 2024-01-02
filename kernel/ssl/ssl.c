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

// #define _DEBUG 1


#define bool int
#define false 0
#define true 1

#define BUFSIZZ 1024*8
#define MAX_SESSION_COUNT 16

int ClientCount = 0;
SSL_CONF_CTX *ClientConf = NULL;

void InitSecure();

void AssertBreak(char *func, char *fn, int line_num);
#pragma aux AssertBreak parm routine [fs esi] [es edi] [ecx]

void InitStart(int consel);
#pragma aux InitStart parm routine [ebx]

void InitDone(int consel);
#pragma aux InitDone parm routine [ebx]

char *AllocateBuf(int consel);
#pragma aux AllocateBuf parm routine [ebx] value [dx eax]

void FreeBuf(int consel, char *buf);
#pragma aux FreeBuf parm routine [ebx] [dx eax]

int GetReceiveSpace(int consel);
#pragma aux GetReceiveSpace parm routine [ebx] value [ecx]

void AddReceiveBuf(int consel, const char *buf, int size);
#pragma aux AddReceiveBuf parm routine [ebx] [es edi] [ecx]

int GetSendCount(int consel);
#pragma aux GetSendCount parm routine [ebx] value [ecx]

int GetSendBuf(int consel, char *buf);
#pragma aux GetSendBuf parm routine [ebx] [es edi] value [ecx]

void ClearSendCount(int consel, int count);
#pragma aux ClearSendCount parm routine [ebx] [ecx]

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
#pragma aux HandleClientConnection "*" rdosdev parm routine [eax] [es edi]
void HandleClientConnection(int consel, SSL *con)
{
    bool in_init = true;
    char *rbuf = AllocateBuf(consel);
    char *sbuf = AllocateBuf(consel);
    int scount = 0;
    int rspace = 0;
    int handle = SSL_get_handle(con);
    int k;

    int write_ssl;
    int read_ssl;
    int tty_on;
    int ssl_pending;

    RdosStartTcpConnectionNotify(handle);

    tty_on = 0;
    read_ssl = 1;
    write_ssl = 1;

    while (!RdosIsTcpConnectionClosed(handle)) 
    {
        if (!SSL_is_init_finished(con) && SSL_total_renegotiations(con) == 0
                && SSL_get_key_update_type(con) == SSL_KEY_UPDATE_NONE) 
        {
            if (!in_init)
                InitStart(consel);

            in_init = true;
            tty_on = 0;
        } 
        else 
        {
            tty_on = 1;

            if (in_init)
            {
                in_init = false;
                InitDone(consel);
            }
        }

        ssl_pending = SSL_has_pending(con) || RdosPollTcpConnection(handle);

        rspace = GetReceiveSpace(consel);

        if (rspace == 0)
            ssl_pending = 0;

        if (!in_init && !ssl_pending)
        {
            if (GetSendCount(consel))
            {
                scount = GetSendBuf(consel, sbuf);
                write_ssl = 1;
            }
        }

        if (!ssl_pending && !write_ssl)
            RdosWaitForSignal();

        if (!ssl_pending && write_ssl && RdosGetTcpConnectionWriteSpace(handle)) 
        {
            k = SSL_write(con, sbuf, (unsigned int)scount);
            switch (SSL_get_error(con, k)) 
            {
            case SSL_ERROR_NONE:
                if (k <= 0)
                    RdosCloseTcpConnection(handle);
                else
                    ClearSendCount(consel, k);

                /* we have done a  write(con,NULL,0); */
                if (scount <= 0) 
                    write_ssl = 0;
                else 
                    write_ssl = 1;
                break;

            case SSL_ERROR_WANT_WRITE:
#ifdef _DEBUG
                RdosWriteString("write W BLOCK\r\n");
#endif
                write_ssl = 1;
                break;

            case SSL_ERROR_WANT_ASYNC:
#ifdef _DEBUG
                RdosWriteString("write A BLOCK\r\n");
#endif
                write_ssl = 1;
                break;

            case SSL_ERROR_WANT_READ:
#ifdef _DEBUG
                RdosWriteString("write R BLOCK\r\n");
#endif
                read_ssl = 1;
                write_ssl = 0;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
#ifdef _DEBUG
                RdosWriteString("write X BLOCK\r\n");
#endif
                break;

            case SSL_ERROR_ZERO_RETURN:
                if (scount != 0) 
                {
#ifdef _DEBUG
                    RdosWriteString("shutdown\r\n");
#endif
                    RdosCloseTcpConnection(handle);
                } 
                else 
                    write_ssl = 0;
                break;

            case SSL_ERROR_SYSCALL:
                if ((k != 0) || (scount != 0)) 
                {
#ifdef _DEBUG
                    RdosWriteString("Socket error\r\n");
#endif
                    RdosCloseTcpConnection(handle);
                } 
                else 
                    write_ssl = 0;
                break;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client - treat as an error */

            case SSL_ERROR_SSL:
#ifdef _DEBUG
                RdosWriteString("SSL error\r\n");
#endif
                RdosCloseTcpConnection(handle);
                break;
            }
            scount = 0;
        }
        else if (ssl_pending || RdosPollTcpConnection(handle))
        {
            rspace = GetReceiveSpace(consel);
            k = SSL_read(con, rbuf, rspace);

            switch (SSL_get_error(con, k)) 
            {
            case SSL_ERROR_NONE:
                if (k <= 0)
                    RdosCloseTcpConnection(handle);
                else
                    AddReceiveBuf(consel, rbuf, k);

                read_ssl = 1;
                break;

            case SSL_ERROR_WANT_ASYNC:
#ifdef _DEBUG
                RdosWriteString("read A BLOCK\r\n");
#endif
                read_ssl = 1;
                write_ssl = 1;
                break;

            case SSL_ERROR_WANT_WRITE:
#ifdef _DEBUG
                RdosWriteString("read W BLOCK\r\n");
#endif
                write_ssl = 1;
                break;

            case SSL_ERROR_WANT_READ:
#ifdef _DEBUG
                RdosWriteString("read R BLOCK\r\n");
#endif
                read_ssl = 1;
                write_ssl = 1;
                break;

            case SSL_ERROR_WANT_X509_LOOKUP:
#ifdef _DEBUG
                RdosWriteString("read X BLOCK\r\n");
#endif
                break;

            case SSL_ERROR_SYSCALL:
#ifdef _DEBUG
                RdosWriteString("CONNECTION CLOSED BY SERVER\r\n");
#endif
                RdosCloseTcpConnection(handle);
                break;

            case SSL_ERROR_ZERO_RETURN:
#ifdef _DEBUG
                RdosWriteString("closed\r\n");
#endif
                RdosCloseTcpConnection(handle);
                break;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client. Treat as an error */

            case SSL_ERROR_SSL:
#ifdef _DEBUG
                RdosWriteString("SSL error\r\n");
#endif
                RdosCloseTcpConnection(handle);
                break;

            }
        }
    }
    FreeBuf(consel, rbuf);
    FreeBuf(consel, sbuf);

    RdosStopTcpConnectionNotify(handle);
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
