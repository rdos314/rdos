#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "sockobj.h"
#include "keyboard.h"

class TTestSocketServer : public TSocketServer
{
public:
    TTestSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    ~TTestSocketServer();

    virtual void HandleSocket();
};

class TTestSocketServerFactory : public TSslSocketServerFactory
{
public:
    TTestSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TTestSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

/*##########################################################################
#
#   Name       : TTestSocketServer::TTestSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTestSocketServer::TTestSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : TTestSocketServer::~TTestSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTestSocketServer::~TTestSocketServer()
{
}

/*##########################################################################
#
#   Name       : TTestSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTestSocketServer::HandleSocket()
{
    int count;
    char *rbuf = new char[1025];

    while (FSocket->IsOpen())
    {
        count = FSocket->GetSize();
        if (count)
        {
            count = FSocket->Read(rbuf, count);
            rbuf[count] = 0;
            printf(rbuf);
        }
        else
            RdosWaitMilli(50);
    }
    delete rbuf;
}

/*##########################################################################
#
#   Name       : TTestSocketServerFactory::TTestSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTestSocketServerFactory::TTestSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSslSocketServerFactory(Port, MaxConnections, BufferSize)
{
}

/*##########################################################################
#
#   Name       : TTestSocketServerFactory::~TTestSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTestSocketServerFactory::~TTestSocketServerFactory()
{
}        

/*##########################################################################
#
#   Name       : TTestSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TTestSocketServerFactory::Create(TTcpSocket *Socket)
{
    TTestSocketServer *server;
    server = new TTestSocketServer("Test Listen", 0x2000, Socket);
    return server;
}

void main()
{
    int port;
    int ip;
    int n0,n1,n2,n3;
    char host[80];
    int count;
    char *rbuf = new char[1025];
    char buf[80];
    TWait wait;
    TTcpSocket *sock;
    TKeyboardDevice keyboard;

    TTestSocketServerFactory fact(443, 100, 0x1000);

    fact.SetPrivateKey("d:/ssl/key.pem");
    fact.SetCertificate("d:/ssl/cert.pem");

    for (;;)
        fact.WaitForever();


    strcpy(host, "185.20.15.60");
//    strcpy(host, "10.8.8.240");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    port = 443;
//    port = 6666;

    sock = new TSslSocket(ip, port, 5000, 0x1000);
    sock->WaitForConnection(7000);

    wait.Add(sock);
    wait.Add(&keyboard);

    if (sock->IsOpen())
    {
        printf("connected\r\n");
        ip = sock->GetRemoteIP();
        IpToString(buf, ip);
        printf("IP: %s\r\n", buf);
        port = sock->GetRemotePort();
        printf("Remote port: %d\r\n", port);
        port = sock->GetLocalPort();
        printf("Local port: %d\r\n", port);
    }

    while (sock->IsOpen())
    {
        wait.WaitForever();

        if (keyboard.Poll())
        {
            printf(" cmd> ");
            gets(buf);
            strcat(buf, "\r\n");
            sock->Write(buf);
            sock->Push();
        }

        count = sock->GetSize();
        if (count)
        {
            count = sock->Read(rbuf, count);
            rbuf[count] = 0;
            printf(rbuf);
        }
    }

    printf("closed\r\n");

    delete sock;


//    RdosTestGate("");
}



