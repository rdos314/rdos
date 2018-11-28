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
#include "json.h"

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
    void NotifyJson(char *str);

    virtual const char *GetProtocol();
    virtual void ReceivedText(char *str);
    virtual void ReceivedBinary(char *str, int size);

    TString FId;
    TString FAction;
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
#   Name       : TOcppSocketServer::NotifyJson
#
#   Purpose....: Notify json message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::NotifyJson(char *str)
{
    TString text;
    TFile file("ocpp.json", 0);
    TJsonDocument json(str);

    json.Write(text);
    file.Write(text.GetData(), text.GetSize());
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
void TOcppSocketServer::ReceivedText(char *str)
{
    int size = strlen(str);
    int id;
    char *ptr;
    char *tempptr;

    if (str[0] != '[')
        return;

    if (str[size - 1] != ']')
        return;

    str[size - 1] = 0;
    ptr = str + 1;

    tempptr = strchr(ptr, ',');
    if (!tempptr)
        return;

    *tempptr = 0;
    id = atoi(ptr);
    
    if (id != 2)
        return;

    ptr = tempptr + 1;

    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    ptr = tempptr + 1;
    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    *tempptr = 0;
    FId = ptr;

    ptr = tempptr + 1;

    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    ptr = tempptr + 1;
    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    *tempptr = 0;
    FAction = ptr;

    ptr = tempptr + 1;

    tempptr = strchr(ptr, '{');
    if (tempptr)
        NotifyJson(tempptr);
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
void TOcppSocketServer::ReceivedBinary(char *str, int size)
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
