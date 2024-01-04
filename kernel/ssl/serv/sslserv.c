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
# handler.c
# SSL handler
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
#include "serv.h"

// #define _DEBUG 1


#define bool int
#define false 0
#define true 1

#define BUFSIZZ 1024*8
#define MAX_SESSION_COUNT 16
#define MAX_CONNECTION_COUNT 128

SSL_CONF_CTX *ClientConf;
SSL_CTX *ClientSessionArr[MAX_SESSION_COUNT];
SSL *ClientConnectionArr[MAX_CONNECTION_COUNT];

extern int WaitForMsg();
#pragma aux WaitForMsg value [eax]

/*##########################################################################
#
#   Name       : OpenSession
#
#   Purpose....: Open client session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux OpenSession "*" parm routine value [ebx]
int OpenSession()
{
    void *p;
    SSL_CTX *ctx = NULL;
    int index = -1;
    int i;

    for (i = 0; i < MAX_SESSION_COUNT; i++)
    {
        if (ClientSessionArr[i] == 0)
        {
            index = i;
            break;
        }
    }

    if (index >= 0)
    {

        ctx = SSL_CTX_new(TLS_client_method());

        if (ctx)
        {
            SSL_CTX_clear_mode(ctx, SSL_MODE_AUTO_RETRY);
            SSL_CONF_CTX_set_ssl_ctx(ClientConf, ctx);

            SSL_CTX_set_default_ctlog_list_file(ctx);
            SSL_CTX_set_default_verify_file(ctx);
            SSL_CTX_set_default_verify_dir(ctx);

            SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_CLIENT | SSL_SESS_CACHE_NO_INTERNAL_STORE);

            ClientSessionArr[index] = ctx;
        }
        else
            index = -1;
    }

    return index + 1;
}

/*##########################################################################
#
#   Name       : CloseSession
#
#   Purpose....: Close client session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CloseSession "*" parm routine [ebx]
void CloseSession(int index)
{
    SSL_CTX *ctx = 0;

    if (index > 0 && index <= MAX_SESSION_COUNT)
    {
        ctx = ClientSessionArr[index - 1];
        ClientSessionArr[index - 1] = 0;
    }

    if (ctx)
        SSL_CTX_free(ctx);
}

/*##########################################################################
#
#   Name       : OpenConnection
#
#   Purpose....: Open client connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux OpenConnection "*" parm routine [ebx] [edx] [esi] [edi] [ecx] [eax] value [ebx]
int OpenConnection(int session, long IP, int LocalPort, int RemotePort, int BufferSize, int Timeout)
{
    SSL_CTX *ctx = 0;
    int handle = 0;
    int i;
    int index = -1;

    if (session > 0 && session <= MAX_SESSION_COUNT)
        ctx = ClientSessionArr[session - 1];

    if (ctx)
    {
        for (i = 0; i < MAX_CONNECTION_COUNT; i++)
        {
            if (ClientConnectionArr[i] == 0)
            {
                index = i;
                break;
            }
        }
    }

    if (index >= 0)
        handle = RdosOpenTcpConnection(IP, LocalPort, RemotePort, Timeout, BufferSize);

    if (handle)
        ServCreateSslConnection(handle, IP, LocalPort, RemotePort, BufferSize);

    return index + 1;
}

/*##########################################################################
#
#   Name       : CloseConnection
#
#   Purpose....: Close client connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CloseConnection "*" parm routine [ebx]
void CloseConnection(int index)
{
}


/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    int i;

    ClientConf = SSL_CONF_CTX_new();
    SSL_CONF_CTX_set_flags(ClientConf, SSL_CONF_FLAG_CLIENT | SSL_CONF_FLAG_CMDLINE);

    for (i = 0; i < MAX_SESSION_COUNT; i++)
        ClientSessionArr[i] = 0;

    for (i = 0; i < MAX_CONNECTION_COUNT; i++)
        ClientConnectionArr[i] = 0;

    while (WaitForMsg())
        ;
}
