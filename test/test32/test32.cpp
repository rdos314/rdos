#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"
#include "modbus.h"
#include "sockobj.h"
#include "base64.h"
#include "sha1.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"

#define FALSE 0
#define TRUE !FALSE

class TOccpSocketServerFactory : public TSocketServerFactory
{
public:
    TOccpSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TOccpSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

class TOccpSocketServer : public TSocketServer
{
public:
    TOccpSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TOccpSocketServer();
    
protected:
    virtual void HandleSocket();
};


/*##########################################################################
#
#   Name       : TOccpSocketServerFactory::TOccpSocketServerFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOccpSocketServerFactory::TOccpSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    Start("OCCP Listen", 0x10000);
}

/*##########################################################################
#
#   Name       : TOccpSocketServerFactory::~TOccpSocketServerFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOccpSocketServerFactory::~TOccpSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : TOccpSocketServerFactory::Create
#
#   Purpose....: Create socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TOccpSocketServerFactory::Create(TTcpSocket *Socket)
{
    return new TOccpSocketServer("OCCP", 0x10000, Socket);
}

/*##########################################################################
#
#   Name       : TOccpSocketServer::TOccpSocketServer
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOccpSocketServer::TOccpSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : TOccpSocketServer::~TOccpSocketServer
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOccpSocketServer::~TOccpSocketServer()
{
}

/*##########################################################################
#
#   Name       : TOccpSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOccpSocketServer::HandleSocket()
{
    while (FSocket->IsOpen())
    {
        RdosWaitMilli(250);
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
void main()
{
    TSha1Hash sha1;
    char outstr[256];
    char instr[] = "dGhlIHNhbXBsZSBub25jZQ==";
    char data[20];
    char res[30];

    strcpy(outstr, instr);
    strcat(outstr, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");

    sha1.Add(outstr, strlen(outstr));
    sha1.GetHashData(data);

    CodeBase64(data, res, 20);

    TOccpSocketServerFactory fact(7000, 16, 1024);

    for (;;)
        RdosWaitMilli(250);

}
