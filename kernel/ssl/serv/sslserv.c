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

#define bool int
#define false 0
#define true 1

#define BUFSIZZ 1024*8
#define MAX_SESSION_COUNT 16
#define MAX_CONNECTION_COUNT 128

struct TServer
{
    int Index;
    SSL_CTX *ctx;
    int ListenHandle;
    int Port;
    int MaxConnections;
    int BufferSize;
    int CurrConnection;
    struct TConnection **ConnectionArr;
};

struct TConnection
{
    int Index;
    int Timeout;
    int BufferSize;
    struct TServer *Server;
    SSL *Con;
};

SSL_CONF_CTX *ClientConf;
SSL_CTX *ClientSessionArr[MAX_SESSION_COUNT];
struct TConnection *ConnectionArr[MAX_CONNECTION_COUNT];

SSL_CONF_CTX *ServerConf;
struct TServer *ServerSessionArr[MAX_SESSION_COUNT];

extern int WaitForMsg();
#pragma aux WaitForMsg value [eax]

/*##########################################################################
#
#   Name       : CreateClientName
#
#   Purpose....: returns thread name based on IP&port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CreateClientName(char *str, int Ip, int port)
{
    sprintf(str, "c-%d.%d.%d.%d:%d", Ip & 0xff, (Ip >> 8) & 0xff, (Ip >> 16) & 0xff, (unsigned int)(Ip) >> 24, port);
}

/*##########################################################################
#
#   Name       : CreateListenName
#
#   Purpose....: returns thread name based on port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CreateListenName(char *str, int port)
{
    sprintf(str, "s-%d", port);
}

/*##########################################################################
#
#   Name       : CreateServerName
#
#   Purpose....: returns thread name based on IP&port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CreateServerName(char *str, int Ip, int port)
{
    sprintf(str, "s-%d.%d.%d.%d:%d", Ip & 0xff, (Ip >> 8) & 0xff, (Ip >> 16) & 0xff, (unsigned int)(Ip) >> 24, port);
}

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
            printf("Open session %d\r\n", index + 1);

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
        printf("Close session %d\r\n", index);
    }

    if (ctx)
        SSL_CTX_free(ctx);
}

/*##########################################################################
#
#   Name       : ConnectionHandler
#
#   Purpose....: Connection handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ConnectionHandler(void *par)
{
    struct TConnection *Conn = (struct TConnection *)par;
    int index = Conn->Index;
    SSL *con = Conn->Con;
    int timeout = Conn->Timeout;
    int size = Conn->BufferSize;
    int handle = SSL_get_handle(con);
    bool in_init = true;
    bool write_ssl = true;
    bool ssl_pending;
    int len;
    int scount = 0;
    int rspace = 0;
    char *buf;

    if (!RdosWaitForTcpConnection(handle, timeout))
        return;

    printf("connected %d\r\n", index);

    ServSslStart(index, handle);
    buf = (char *)malloc(size);

    while (!RdosIsTcpConnectionClosed(handle))
    {
        if (!SSL_is_init_finished(con) && SSL_total_renegotiations(con) == 0
                && SSL_get_key_update_type(con) == SSL_KEY_UPDATE_NONE)
        {
            if (!in_init)
                ServSslInitStart(index);

            in_init = true;
        }
        else
        {
            if (in_init)
            {
                in_init = false;
                ServSslInitDone(index);
            }
        }

        if (ServSslGetReceiveSpace(index))
            ssl_pending = SSL_has_pending(con) || RdosPollTcpConnection(handle);
        else
            ssl_pending = false;

        if (!in_init && !ssl_pending)
        {
            if (ServSslGetSendCount(index) && RdosGetTcpConnectionWriteSpace(handle))
                write_ssl = true;
            else
                write_ssl = false;
        }

        if (ssl_pending)
        {
            rspace = ServSslGetReceiveSpace(index);
            len = SSL_read(con, buf, rspace);

            if (len > 0)
                printf("Received %d bytes\r\n", len);

            switch (SSL_get_error(con, len))
            {
            case SSL_ERROR_NONE:
                if (len <= 0)
                    RdosCloseTcpConnection(handle);
                else
                    ServSslAddReceiveBuf(index, buf, len);

                break;

            case SSL_ERROR_SYSCALL:
                printf("CONNECTION CLOSED BY SERVER\r\n");
                RdosCloseTcpConnection(handle);
                break;

            case SSL_ERROR_ZERO_RETURN:
                printf("closed\r\n");
                RdosCloseTcpConnection(handle);
                break;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client. Treat as an error */

            case SSL_ERROR_SSL:
                printf("SSL error\r\n");
                RdosCloseTcpConnection(handle);
                break;

            }
        }
        else if (write_ssl)
        {
            scount = ServSslGetSendBuf(index, buf);

            if (scount > 0)
                printf("Sent %d bytes\r\n", scount);

            len = SSL_write(con, buf, (unsigned int)scount);
            switch (SSL_get_error(con, len))
            {
            case SSL_ERROR_NONE:
                if (len <= 0)
                    RdosCloseTcpConnection(handle);
                else
                    ServSslClearSendCount(index, len);
                break;

            case SSL_ERROR_ZERO_RETURN:
                if (scount)
                {
                    printf("shutdown\r\n");
                    RdosCloseTcpConnection(handle);
                }
                break;

            case SSL_ERROR_SYSCALL:
                if (len || scount)
                {
                    printf("Socket error\r\n");
                    RdosCloseTcpConnection(handle);
                }
                break;

            case SSL_ERROR_WANT_ASYNC_JOB:
                /* This shouldn't ever happen in s_client - treat as an error */

            case SSL_ERROR_SSL:
                printf("SSL error\r\n");
                RdosCloseTcpConnection(handle);
                break;
            }
            scount = 0;
        }
        else
            ServSslWaitForChange(index);
    }

    printf("closed %d\r\n", index);

    ServSslStop(index, handle);
    free(buf);
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
    struct TConnection *Conn = 0;
    SSL_CTX *ctx = 0;
    BIO *sbio;
    SSL *con;
    int handle = 0;
    int i;
    int index = -1;
    char str[80];

    if (session > 0 && session <= MAX_SESSION_COUNT)
        ctx = ClientSessionArr[session - 1];

    if (ctx)
    {
        for (i = 0; i < MAX_CONNECTION_COUNT; i++)
        {
            if (ConnectionArr[i] == 0)
            {
                index = i;
                break;
            }
        }
    }

    if (index >= 0)
        handle = RdosOpenTcpConnection(IP, LocalPort, RemotePort, Timeout, BufferSize);

    if (handle)
    {
        Conn = (struct TConnection *)malloc(sizeof(struct TConnection));
        Conn->Index = index + 1;
        Conn->Timeout = Timeout;
        Conn->BufferSize = BufferSize;

        printf("Open connection %d\r\n", Conn->Index);

        if (!LocalPort)
            LocalPort = RdosGetLocalTcpConnectionPort(handle);

        ServCreateSslConnection(Conn->Index, IP, LocalPort, RemotePort, BufferSize);

        sbio = BIO_new_socket(handle, BIO_NOCLOSE);
        con = SSL_new(ctx);
        Conn->Con = con;

        SSL_set_bio(con, sbio, sbio);
        SSL_set_connect_state(con);

        ConnectionArr[Conn->Index - 1] = Conn;

        CreateClientName(str, IP, RemotePort);
        RdosCreateThread(ConnectionHandler, str, Conn, 0x4000);

        return Conn->Index;
    }
    else
        return -1;
}

/*##########################################################################
#
#   Name       : ListenHandler
#
#   Purpose....: Listen handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ListenHandler(void *par)
{
    struct TServer *Server = (struct TServer *)par;
    int index;
    int sock;
    int WaitHandle = RdosCreateWait();
    int Ip;
    int RemotePort;
    BIO *sbio;
    SSL *con;
    int i;
    char str[80];

    RdosAddWaitForTcpListen(WaitHandle, Server->ListenHandle, 0);

    for (;;)
    {
        RdosWaitForever(WaitHandle);

        sock = RdosGetTcpListen(Server->ListenHandle);
        while (sock)
        {
            index = -1;

            for (i = 0; i < Server->MaxConnections; i++)
            {
                if (Server->ConnectionArr[i] == 0)
                {
                    index = i;
                    break;
                }
            }

            if (index >= 0)
            {
                printf("Add connection %d:%d\r\n", Server->Index, index);

                Ip = RdosGetRemoteTcpConnectionIP(sock);
                RemotePort = RdosGetLocalTcpConnectionPort(sock);

//                ServCreateSslConnection(index + 1, Ip, Server->Port, RemotePort, Server->BufferSize);

                sbio = BIO_new_socket(sock, BIO_NOCLOSE);
                con = SSL_new(Server->ctx);

                SSL_set_bio(con, sbio, sbio);
                SSL_set_accept_state(con);

//                ServerConnectionArr[index] = con;

//                CreateServerName(str, IP, entry->Port);
//                RdosCreateThread(ConnectionHandler, str, 0, 0x4000);
            }

            sock = RdosGetTcpListen(Server->ListenHandle);
        }
    }

    RdosCloseWait(WaitHandle);
}

/*##########################################################################
#
#   Name       : OpenServer
#
#   Purpose....: Open server session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux OpenServer "*" parm routine [eax] [edx] [ecx] value [ebx]
int OpenServer(int Port, int MaxConnections, int BufferSize)
{
    struct TServer *Server;
    void *p;
    SSL_CTX *ctx = NULL;
    int i;
    int index = -1;
    char str[80];

    for (i = 0; i < MAX_SESSION_COUNT; i++)
    {
        if (ServerSessionArr[i] == 0)
        {
            index = i;
            break;
        }
    }

    if (index >= 0)
    {
        ctx = SSL_CTX_new(TLS_server_method());

        if (ctx)
        {
            printf("Open server %d\r\n", index + 1);

            SSL_CTX_clear_mode(ctx, SSL_MODE_AUTO_RETRY);
            SSL_CONF_CTX_set_ssl_ctx(ServerConf, ctx);

            SSL_CTX_set_session_cache_mode(ctx, SSL_SESS_CACHE_NO_INTERNAL | SSL_SESS_CACHE_SERVER);

            Server = (struct TServer *)malloc(sizeof(struct TServer));
            Server->Index = index;
            Server->MaxConnections = MaxConnections;
            Server->BufferSize = BufferSize;
            Server->ListenHandle = RdosCreateTcpListen(Port, MaxConnections, BufferSize);
            Server->ctx = ctx;
            Server->ConnectionArr = (struct TConnection **)malloc(MaxConnections * sizeof(struct TConnection *));

            for (i = 0; i < MaxConnections; i++)
                Server->ConnectionArr[i] = 0;

            ServerSessionArr[index] = Server;

            CreateListenName(str, Port);
            RdosCreateThread(ListenHandler, str, Server, 0x4000);
        }
        else
            index = -1;
    }

    return index + 1;
}

/*##########################################################################
#
#   Name       : PushConnection
#
#   Purpose....: Push connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux PushConnection "*" parm routine [ebx]
void PushConnection(int index)
{
    struct TConnection *Conn = 0;
    SSL *con = 0;
    int handle;

    if (index > 0 && index <= MAX_CONNECTION_COUNT)
        Conn = ConnectionArr[index - 1];

    if (Conn)
        con = Conn->Con;

    if (con)
    {       
        handle = SSL_get_handle(con);
        if (!RdosIsTcpConnectionClosed(handle) && !ServSslGetSendCount(index))
            RdosPushTcpConnection(handle);
    }
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
    struct TConnection *Conn = 0;
    SSL *con = 0;
    int handle;

    if (index > 0 && index <= MAX_CONNECTION_COUNT)
    {
        Conn = ConnectionArr[index - 1];
        ConnectionArr[index - 1] = 0;

        printf("Close connection %d\r\n", index);
    }

    if (Conn)
    {
        con = Conn->Con;

        if (con)
        {
            handle = SSL_get_handle(con);

            SSL_shutdown(con);
            SSL_free(con);
 
            RdosDeleteTcpConnection(handle);
            ServDeleteSslConnection(index);
        }
        free(Conn);
    }
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

    ServerConf = SSL_CONF_CTX_new();
    SSL_CONF_CTX_set_flags(ServerConf, SSL_CONF_FLAG_SERVER | SSL_CONF_FLAG_CMDLINE);

    for (i = 0; i < MAX_SESSION_COUNT; i++)
        ClientSessionArr[i] = 0;

    for (i = 0; i < MAX_CONNECTION_COUNT; i++)
        ConnectionArr[i] = 0;

    for (i = 0; i < MAX_SESSION_COUNT; i++)
        ServerSessionArr[i] = 0;

    while (WaitForMsg())
        ;
}
