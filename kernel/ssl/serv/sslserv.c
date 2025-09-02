/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# sslserv.c
# SSL server
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
#include "crypto/jsonc.h"

#include "rdos.h"
#include "ssl.h"
#include "apps.h"
#include "s_apps.h"

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
    int ServerEntry;
    SSL *Con;
    bool Active;
    bool Closed;
    struct RdosFutex Futex;
};

SSL_CONF_CTX *ClientConf;
SSL_CTX *ClientSessionArr[MAX_SESSION_COUNT];
struct TConnection *ConnectionArr[MAX_CONNECTION_COUNT];

SSL_CONF_CTX *ServerConf;
struct TServer *ServerSessionArr[MAX_SESSION_COUNT];

BIO *bio_s_out;
BIO *bio_err = NULL;
BIO_ADDR *ourpeer = NULL;

char *prog;
char *default_config_file = NULL;

extern int WaitForMsg();
#pragma aux WaitForMsg value [eax]

char *opt_getprog(void)
{
    return prog;
}

char *opt_arg(void)
{
    return NULL;
}

int opt_format(const char *s, unsigned long flags, int *result)
{
    return 0;
}

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
#   Name       : FreeConnection
#
#   Purpose....: Free connection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void FreeConnection(struct TConnection *Conn)
{
    SSL *con = Conn->Con;
    int handle = SSL_get_handle(con);
    struct TServer *Server = Conn->Server;
    int Entry = Conn->ServerEntry;

    ConnectionArr[Conn->Index - 1] = 0;

    if (Server)
        if (Entry > 0 && Entry <= Server->MaxConnections)
            if (Server->ConnectionArr[Entry - 1] == Conn)
                Server->ConnectionArr[Entry - 1] = 0;

    if (con)
    {
        SSL_shutdown(con);
        SSL_free(con);

        RdosDeleteTcpConnection(handle);
        ServDeleteSslConnection(Conn->Index);
    }

    RdosLeaveFutex(&Conn->Futex);
    RdosResetFutex(&Conn->Futex);
    free(Conn);
}

/*##########################################################################
#
#   Name       : ShowCert
#
#   Purpose....: Show certificate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ShowCert(SSL *con)
{
    X509 *peer = NULL;
//    STACK_OF(X509) *sk;
//    int i;

    struct buf_mem_st *mb = (struct buf_mem_st *)malloc(sizeof(struct buf_mem_st));
    char *buf = (char *)malloc(0x1000);
    BIO *bio = BIO_new(BIO_s_mem());

    mb->length = 0;
    mb->max = 5;
    mb->data = buf;
    mb->flags = BUF_MEM_FLAG_FIXED;

    BIO_set_mem_buf(bio, mb, BIO_NOCLOSE);

//    sk = SSL_get_peer_cert_chain(con);
//    if (sk != NULL)
//    {
//        BIO_printf(bio_s_out, "---\nCertificate chain\n");
//        for (i = 0; i < sk_X509_num(sk); i++)
//        {
//            BIO_printf(bio_s_out, "%2d s:", i);
//            X509_NAME_print_ex(bio_s_out, X509_get_subject_name(sk_X509_value(sk, i)), 0, get_nameopt());
//            BIO_puts(bio_s_out, "\n");
//            BIO_printf(bio_s_out, "   i:");
//            X509_NAME_print_ex(bio_s_out, X509_get_issuer_name(sk_X509_value(sk, i)), 0, get_nameopt());
//            BIO_puts(bio_s_out, "\n");
//            PEM_write_bio_X509(bio_s_out, sk_X509_value(sk, i));
//        }
//    }

    BIO_printf(bio, "---\n");
    peer = SSL_get_peer_certificate(con);
    if (peer != NULL)
    {
        BIO_printf(bio, "Server certificate\n");

        PEM_write_bio_X509(bio, peer);
        dump_cert_text(bio, peer);
    }

    BIO_free(bio);

    free(buf);
    free(mb);
}

/*##########################################################################
#
#   Name       : ClientHandler
#
#   Purpose....: Client connection handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ClientHandler(void *par)
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

    SSL_set_tlsext_debug_callback(con, tlsext_cb);
    SSL_set_tlsext_debug_arg(con, bio_s_out);

    SSL_set_msg_callback(con, msg_cb);
    SSL_set_msg_callback_arg(con, bio_s_out);

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

                ShowCert(con);
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
        {
            if (RdosPollTcpConnection(handle) || ServSslGetSendCount(index) || SSL_has_pending(con))
                RdosWaitMilli(25);
            else
                ServSslWaitForChange(index);
        }
    }

    printf("closed %d\r\n", index);

    ServSslStop(index, handle);
    free(buf);

    RdosEnterFutex(&Conn->Futex);
    Conn->Active = false;
    if (Conn->Closed)
        FreeConnection(Conn);
    else
        RdosLeaveFutex(&Conn->Futex);
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
        Conn->Server = 0;
        Conn->Active = true;
        Conn->Closed = false;
        sprintf(str, "Conn.%d", Conn->Index);
        RdosInitFutex(&Conn->Futex, str);

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
        RdosCreateThread(ClientHandler, str, Conn, 0x4000);

        return Conn->Index;
    }
    else
        return -1;
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

    if (con && !Conn->Closed)
    {
        handle = SSL_get_handle(con);
        if (!RdosIsTcpConnectionClosed(handle) && !ServSslGetSendCount(index))
            RdosPushTcpConnection(handle);
    }
}

/*##########################################################################
#
#   Name       : GetConnectionCert
#
#   Purpose....: Get connection certificate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetConnectionCert "*" parm routine [ebx] [edi] [ecx] value [eax]
int GetConnectionCert(int index, char *buf, int maxsize)
{
    struct TConnection *Conn = 0;
    SSL *con = 0;
    X509 *peer = NULL;
    int size = 0;
    JSON_DOC *doc;

    if (index > 0 && index <= MAX_CONNECTION_COUNT)
        Conn = ConnectionArr[index - 1];

    if (Conn)
        con = Conn->Con;

    if (con)
        peer = SSL_get_peer_certificate(con);

    if (peer)
    {
        doc = X509_get_json(peer);
        size = GetJsonText(doc, buf, maxsize);
        DeleteJson(doc);
    }

    return size;
}

/*##########################################################################
#
#   Name       : GetCertJson
#
#   Purpose....: Get certficate in JSON format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetCertJson "*" parm routine [esi] [edi] [ecx] value [eax]
int GetCertJson(const char *filename, char *buf, int maxsize)
{
    X509 *x;
    JSON_DOC *doc;
    int size = 0;

    x = load_cert(filename, FORMAT_PEM, "Certificate");

    if (x)
    {
        doc = X509_get_json(x);
        size = GetJsonText(doc, buf, maxsize);
        DeleteJson(doc);

        X509_free(x);
    }

    return size;
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

    if (index > 0 && index <= MAX_CONNECTION_COUNT)
    {
        Conn = ConnectionArr[index - 1];
        printf("Close connection %d\r\n", index);
    }

    if (Conn)
    {
        RdosEnterFutex(&Conn->Futex);
        Conn->Closed = true;
        if (Conn->Active)
            RdosLeaveFutex(&Conn->Futex);
        else
            FreeConnection(Conn);
     }
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
    struct TConnection *Conn;
    int index;
    int sock;
    int WaitHandle = RdosCreateWait();
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

                Conn = (struct TConnection *)malloc(sizeof(struct TConnection));
                Conn->Index = sock;
                Conn->Timeout = 0;
                Conn->BufferSize = Server->BufferSize;
                Conn->Server = 0;
                Conn->Con = 0;
                Conn->Active = true;
                Conn->Closed = false;
                sprintf(str, "Conn%d:%d", Server->Index, index);
                RdosInitFutex(&Conn->Futex, str);

                Server->ConnectionArr[index] = Conn;

                ServAddSslListen(Server->Index, index + 1);
            }

            sock = RdosGetTcpListen(Server->ListenHandle);
        }
    }

//    RdosCloseWait(WaitHandle);
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
#pragma aux OpenServer "*" parm routine [esi] [eax] [ecx] value [ebx]
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
            Server->Index = index + 1;
            Server->MaxConnections = MaxConnections;
            Server->BufferSize = BufferSize;
            Server->ListenHandle = RdosCreateTcpListen(Port, MaxConnections, BufferSize);
            Server->ctx = ctx;
            Server->ConnectionArr = (struct TConnection **)malloc(MaxConnections * sizeof(struct TConnection *));

            for (i = 0; i < MaxConnections; i++)
                Server->ConnectionArr[i] = 0;

            ServCreateSslListen(Server->Index, Port, MaxConnections);

            ServerSessionArr[index] = Server;

            CreateListenName(str, Port);
            RdosCreateThread(ListenHandler, str, Server, 0x4000);
        }
        else
            index = -1;
    }

    return index + 1;
}


static int init_ssl_connection(SSL *con)
{
    int i;
    long verify_err;

    i = SSL_accept(con);

    if (i <= 0)
    {
        BIO_printf(bio_s_out, "ERROR\n");

        verify_err = SSL_get_verify_result(con);
        if (verify_err != X509_V_OK) {
            BIO_printf(bio_s_out, "verify error:%s\n",
                       X509_verify_cert_error_string(verify_err));
        }
        /* Always print any error messages */
        ERR_print_errors(bio_s_out);
        return 0;
    }

//    print_connection_info(con);
    return 1;
}

/*##########################################################################
#
#   Name       : ServerHandler
#
#   Purpose....: Server connection handler
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ServerHandler(void *par)
{
    struct TConnection *Conn = (struct TConnection *)par;
    int index = Conn->Index;
    SSL *con = Conn->Con;
    int size = Conn->BufferSize;
    int handle = SSL_get_handle(con);
    int len;
    int i;
    int scount = 0;
    int rspace = 0;
    char *buf;
    bool in_init = true;
    bool read_from_terminal;
    bool read_from_sslcon;

    SSL_set_tlsext_debug_callback(con, tlsext_cb);
    SSL_set_tlsext_debug_arg(con, bio_s_out);

    SSL_set_msg_callback(con, msg_cb);
    SSL_set_msg_callback_arg(con, bio_s_out);

    ServSslStart(index, handle);
    buf = (char *)malloc(size);

    while (!RdosIsTcpConnectionClosed(handle))
    {
        read_from_terminal = false;
        read_from_sslcon = SSL_has_pending(con) || RdosPollTcpConnection(handle);

        if (!read_from_sslcon)
        {
            if (ServSslGetSendCount(index) && RdosGetTcpConnectionWriteSpace(handle))
                read_from_terminal = true;
            else
                read_from_terminal = false;
        }

        if (read_from_terminal)
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

                case SSL_ERROR_WANT_ASYNC_JOB:
                case SSL_ERROR_SSL:
                case SSL_ERROR_SYSCALL:
                    printf("SSL error\r\n");
                    RdosCloseTcpConnection(handle);
                    break;
            }
            scount = 0;
        }
        else if (read_from_sslcon)
        {
            if (!SSL_is_init_finished(con))
            {
                if (!in_init)
                    ServSslInitStart(index);

                in_init = true;

                i = init_ssl_connection(con);

                if (i < 0)
                {
                    printf("Init connection error\r\n");
                    RdosCloseTcpConnection(handle);
                }
            }
            else
            {
                if (in_init)
                {
                    in_init = false;
                    ServSslInitDone(index);
                }

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
                    case SSL_ERROR_WANT_ASYNC_JOB:
                    case SSL_ERROR_SSL:
                        printf("SSL error\r\n");
                        RdosCloseTcpConnection(handle);
                        break;
                }
            }
        }
        else
        {
            if (RdosPollTcpConnection(handle) || ServSslGetSendCount(index) || SSL_has_pending(con))
                RdosWaitMilli(25);
            else
                ServSslWaitForChange(index);
        }
    }

    printf("closed %d\r\n", index);

    ServSslStop(index, handle);
    free(buf);

    RdosEnterFutex(&Conn->Futex);
    Conn->Active = false;
    if (Conn->Closed)
        FreeConnection(Conn);
    else
        RdosLeaveFutex(&Conn->Futex);
}

/*##########################################################################
#
#   Name       : AcceptServer
#
#   Purpose....: Accept server socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux AcceptServer "*" parm routine [ebx] [eax] value [ebx]
int AcceptServer(int index, int entry)
{
    struct TServer *Server = 0;
    struct TConnection *Conn = 0;
    int sock;
    int Ip;
    int RemotePort;
    int i;
    BIO *sbio;
    SSL *con = 0;
    char str[80];

    if (index > 0 && index <= MAX_SESSION_COUNT)
        Server = ServerSessionArr[index - 1];

    if (Server)
        if (entry > 0 && entry <= MAX_CONNECTION_COUNT)
            Conn = Server->ConnectionArr[entry - 1];

    if (Conn)
    {
        sock = Conn->Index;
        Conn->Index = -1;

        for (i = 0; i < MAX_CONNECTION_COUNT; i++)
        {
            if (ConnectionArr[i] == 0)
            {
                Conn->Index = i;
                break;
            }
        }

        if (Conn->Index < 0)
        {
            RdosCloseTcpConnection(sock);
            RdosDeleteTcpConnection(sock);
            RdosResetFutex(&Conn->Futex);
            free(Conn);
            Conn = 0;
            Server->ConnectionArr[entry - 1] = 0;
        }
    }

    if (Conn)
    {
        Conn->Index++;

        printf("Accept connection %d\r\n", Conn->Index);

        Ip = RdosGetRemoteTcpConnectionIP(sock);
        RemotePort = RdosGetRemoteTcpConnectionPort(sock);

        ServCreateSslConnection(Conn->Index, Ip, Server->Port, RemotePort, Server->BufferSize);

        sbio = BIO_new_socket(sock, BIO_NOCLOSE);
        con = SSL_new(Server->ctx);
        Conn->Con = con;
        Conn->Server = Server;
        Conn->ServerEntry = entry;

        SSL_set_bio(con, sbio, sbio);
        SSL_set_accept_state(con);

        ConnectionArr[Conn->Index - 1] = Conn;

        CreateServerName(str, Ip, Server->Port);
        RdosCreateThread(ServerHandler, str, Conn, 0x4000);

        return Conn->Index;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : SetServerCert
#
#   Purpose....: Set server certificate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux SetServerCert "*" parm routine [ebx] [edi] [esi] [edx]
void SetServerCert(int index, const char *CertFileName, const char *KeyFileName, const char *ChainFileName)
{
    struct TServer *Server = 0;
    X509 *cert;
    STACK_OF(X509) *chain = NULL;
    EVP_PKEY *key;

    if (index > 0 && index <= MAX_SESSION_COUNT)
        Server = ServerSessionArr[index - 1];

    if (Server)
    {
        key = load_key(KeyFileName, FORMAT_PEM, 0, 0, 0, "server certificate private key file");

        if (!key)
            printf("Cannot load %s as a key\r\n", KeyFileName);

        cert = load_cert(CertFileName, FORMAT_PEM, "server certificate file");

        if (!cert)
            printf("Cannot load %s as a certificate\r\n", CertFileName);

        if (!load_certs(ChainFileName, &chain, FORMAT_PEM, NULL, "server certificate chain"))
            printf("Cannot load %s as a certificate chain\r\n", ChainFileName);

        if (set_cert_key_stuff(Server->ctx, cert, key, chain, 0))
            printf("Loaded Cert: %s, Private Key: %s, Chain: %s\r\n", CertFileName, KeyFileName, ChainFileName);
        else
            printf("Failed Cert: %s, Private Key: %s, Chain: %s\r\n", CertFileName, KeyFileName, ChainFileName);
    }
}

/*##########################################################################
#
#   Name       : CloseServer
#
#   Purpose....: Close server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CloseServer "*" parm routine [ebx]
void CloseServer(int index)
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
int main(int argc, char **argv)
{
    int i;
    FILE *fp;

    if (!RdosSetCurDir("d:/ssl"))
    {
        RdosDeleteFile("d:/ssl/log.txt");
        RdosMakeDir("d:/ssl");
    }

    fp = fopen("d:/ssl/log.txt", "w");

    prog = argv[0];

    bio_s_out = BIO_new_fp(fp, BIO_NOCLOSE | BIO_FP_TEXT);

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

    return 0;
}
