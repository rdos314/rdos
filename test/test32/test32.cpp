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
#include "websock.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"

#define FALSE 0
#define TRUE !FALSE

class TOcppSocketServerFactory : public TSocketServerFactory
{
public:
    TOcppSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TOcppSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

class TOcppSocketServer : public TWebSocketServer
{
public:
    TOcppSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TOcppSocketServer();
    
protected:
    virtual const char *GetProtocol();
    virtual void ReceivedText(const char *str);
    virtual void ReceivedBinary(const char *str, int size);
};


/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::TOcppSocketServerFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServerFactory::TOcppSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    Start("OCPP Listen", 0x10000);
}

/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::~TOcppSocketServerFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServerFactory::~TOcppSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::Create
#
#   Purpose....: Create web socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TOcppSocketServerFactory::Create(TTcpSocket *Socket)
{
    return new TOcppSocketServer("OCPP", 0x10000, Socket);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::TOcppSocketServer
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServer::TOcppSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TWebSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::~TOcppSocketServer
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServer::~TOcppSocketServer()
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::GetProtocol
#
#   Purpose....: Get protocol to use
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TOcppSocketServer::GetProtocol()
{
    const char *prot = FProtocol.GetData();

    if (strstr(prot, "ocpp1.6"))
        return "ocpp1.6";
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReceivedText
#
#   Purpose....: Received text message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReceivedText(const char *str)
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReceivedBinary
#
#   Purpose....: Received binary message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReceivedBinary(const char *str, int size)
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
void main()
{
    TOcppSocketServerFactory fact(7000, 16, 1024);

    for (;;)
        RdosWaitMilli(250);

}
