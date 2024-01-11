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


typedef struct string_int_pair_st {
    const char *name;
    int retval;
} OPT_PAIR, STRINT_PAIR;

static const char *lookup(int val, const STRINT_PAIR* list, const char* def)
{
    for ( ; list->name; ++list)
        if (list->retval == val)
            return list->name;
    return def;
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
#ifndef OPENSSL_NO_NEXTPROTONEG
    {", NextProto", SSL3_MT_NEXT_PROTO},
#endif
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
#ifndef OPENSSL_NO_HEARTBEATS
        case 24:
            str_details1 = ", Heartbeat";

            if (len > 0) {
                switch (bp[0]) {
                case 1:
                    str_details1 = ", HeartbeatRequest";
                    break;
                case 2:
                    str_details1 = ", HeartbeatResponse";
                    break;
                }
            }
            break;
#endif
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
#ifdef TLSEXT_TYPE_next_proto_neg
    {"next protocol", TLSEXT_TYPE_next_proto_neg},
#endif
#ifdef TLSEXT_TYPE_encrypt_then_mac
    {"encrypt-then-mac", TLSEXT_TYPE_encrypt_then_mac},
#endif
#ifdef TLSEXT_TYPE_application_layer_protocol_negotiation
    {"application layer protocol negotiation",
     TLSEXT_TYPE_application_layer_protocol_negotiation},
#endif
#ifdef TLSEXT_TYPE_extended_master_secret
    {"extended master secret", TLSEXT_TYPE_extended_master_secret},
#endif
    {"key share", TLSEXT_TYPE_key_share},
    {"supported versions", TLSEXT_TYPE_supported_versions},
    {"psk", TLSEXT_TYPE_psk},
    {"psk kex modes", TLSEXT_TYPE_psk_kex_modes},
    {"certificate authorities", TLSEXT_TYPE_certificate_authorities},
    {"post handshake auth", TLSEXT_TYPE_post_handshake_auth},
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


    BIO *bio_s_out = BIO_new_fp(stdout, BIO_NOCLOSE | BIO_FP_TEXT);

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
        Conn->Server = 0;

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

                Server->ConnectionArr[index] = Conn;

                ServAddSslListen(Server->Index, index + 1);
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
    bool in_init = true;
    bool write_ssl = true;
    bool ssl_pending;
    int len;
    int scount = 0;
    int rspace = 0;
    char *buf;

    BIO *bio_s_out = BIO_new_fp(stdout, BIO_NOCLOSE | BIO_FP_TEXT);

    SSL_set_tlsext_debug_callback(con, tlsext_cb);
    SSL_set_tlsext_debug_arg(con, bio_s_out);

    SSL_set_msg_callback(con, msg_cb);
    SSL_set_msg_callback_arg(con, bio_s_out);

    ServSslStart(index, handle);
    buf = (char *)malloc(size);

    while (!RdosIsTcpConnectionClosed(handle))
    {
        if (!SSL_is_init_finished(con))
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
