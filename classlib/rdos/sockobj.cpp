/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# socket.cpp
# Socket class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include "sockobj.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : IpToString
#
#   Purpose....: returns a string with the ip in the format "x.x.x.x"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void IpToString(char *str, int Ip)
{
    sprintf(str, "%d.%d.%d.%d", Ip & 0xff, (Ip >> 8) & 0xff, (Ip >> 16) & 0xff, (unsigned int)(Ip) >> 24);
}

/*##########################################################################
#
#   Name       : StringToIp
#
#   Purpose....: decodes ip from the format "x.x.x.x"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int StringToIp(const char *str)
{
    int n0,n1,n2,n3;

    if (sscanf(str, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        return n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TSocket::~TSocket
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::~TSocket()
{
}

/*##################  TSocket::GetLocalIP  ############################
*   Purpose....: Get local IP                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TSocket::GetLocalIP()
{
    return RdosGetIp();
}

/*##########################################################################
#
#   Name       : TSocket::WaitForData
#
#   Purpose....: Wait for something in the receive buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if available
#
##########################################################################*/
int TSocket::WaitForData(long Timeout)
{
    if (!FWait)
        CreateWait();

    if (FWait)
        if (FWait->WaitTimeout(Timeout) == this)
            return IsOpen();

    return FALSE;
}

/*##########################################################################
#
#   Name       : TSocket::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::SignalNewData()
{
}

/*##########################################################################
#
#   Name       : TTcpSocket::TTcpSocket
#
#   Purpose....: Constructor
#
#   In params..: Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTcpSocket::TTcpSocket(int Handle)
{
    FHandle = Handle;
    Open();
}

/*##########################################################################
#
#   Name       : TTcpSocket::TTcpSocket
#
#   Purpose....: Constructor
#
#   In params..: IP         Remote IP address
#                Port       remote port to connect to
#                Timeout        establish timeout in ms
#                BufferSize     socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTcpSocket::TTcpSocket(long IP, int Port, int Timeout, int BufferSize)
{
    FHandle = RdosOpenTcpConnection(IP, 0, Port, Timeout, BufferSize);
    Open();
}

/*##########################################################################
#
#   Name       : TTcpSocket::TTcpSocket
#
#   Purpose....: Constructor
#
#   In params..: IP         Remote IP address
#                LocalPort  local port to use
#                RemotePort remote port to connect to
#                Timeout        establish timeout in ms
#                BufferSize     socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTcpSocket::TTcpSocket(long IP, int LocalPort, int RemotePort, int Timeout, int BufferSize)
{
    FHandle = RdosOpenTcpConnection(IP, LocalPort, RemotePort, Timeout, BufferSize);
    Open();     
}

/*##########################################################################
#
#   Name       : TTcpSocket::~TTcpSocket
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTcpSocket::~TTcpSocket()
{
    if (FHandle)
    {
        RdosCloseTcpConnection(FHandle);
        RdosDeleteTcpConnection(FHandle);
    }
}

/*##########################################################################
#
#   Name       : TTcpSocket::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TTcpSocket::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name,"TCP Socket",MaxLen);
}

/*##########################################################################
#
#   Name       : TTcpSocket::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait       Wait device
#                Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTcpSocket::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForTcpConnection(Wait->GetHandle(), FHandle, (int)this);
}

/*##################  TTcpSocket::IsOpen  ############################
*   Purpose....: Check if socket is open                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::IsOpen()
{
    if (TDevice::IsOpen() && FHandle)
        return !RdosIsTcpConnectionClosed(FHandle);
    else    
        return FALSE;
}

/*##################  TTcpSocket::NotifyClose  ############################
*   Purpose....: Notify socket closed                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTcpSocket::NotifyClose()
{
    if (FHandle)
        RdosCloseTcpConnection(FHandle);
}

/*##################  TTcpSocket::GetRemoteIP  ############################
*   Purpose....: Get remote IP                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TTcpSocket::GetRemoteIP() const
{
    if (FHandle)
        return RdosGetRemoteTcpConnectionIP(FHandle);
    else
        return -1;
}

/*##################  TTcpSocket::GetRemotePort  ############################
*   Purpose....: Get remote port                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::GetRemotePort() const
{
    if (FHandle)
        return RdosGetRemoteTcpConnectionPort(FHandle);
    else
        return 0;
}

/*##################  TTcpSocket::GetLocalPort  ############################
*   Purpose....: Get local port                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::GetLocalPort() const
{
    if (FHandle)
        return RdosGetLocalTcpConnectionPort(FHandle);
    else
        return 0;
}

/*##################  TTcpSocket::Push  ############################
*   Purpose....: Push connection                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TTcpSocket::Push()
{
    if (FHandle)
        RdosPushTcpConnection(FHandle);
}

/*##################  TTcpSocket::IsIdle  ############################
*   Purpose....: Check if connection is idle (no unsent data & no received data)                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::IsIdle()
{
    if (FHandle)
        return RdosIsTcpConnectionIdle(FHandle);
    else
        return TRUE;
}

/*##################  TTcpSocket::WaitForConnection  ############################
*   Purpose....: Wait for a connection                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::WaitForConnection(int Timeout)
{
    if (FHandle)
        return RdosWaitForTcpConnection(FHandle, Timeout);
    else
        return FALSE;
}

/*##################  TTcpSocket::GetSize  ############################
*   Purpose....: Check available bytes in receive buffer                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::GetSize()
{
    if (FHandle)
        return RdosPollTcpConnection(FHandle);
    else
        return 0;
}

/*##################  TTcpSocket::GetWriteSpace  ############################
*   Purpose....: Check free bytes in send buffer                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TTcpSocket::GetWriteSpace()
{
    if (FHandle)
        return RdosGetTcpConnectionWriteSpace(FHandle);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TTcpSocket::Write
#
#   Purpose....: Write a char
#
#   In params..: ch     char to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTcpSocket::Write(char ch)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, &ch, 1);
}

/*##########################################################################
#
#   Name       : TTcpSocket::Write
#
#   Purpose....: Write a buffer
#
#   In params..: buf     buffer to write
#                count   count to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTcpSocket::Write(const char *buf, int count)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, buf, count);
}

/*##########################################################################
#
#   Name       : TTcpSocket::Write
#
#   Purpose....: Write a string
#
#   In params..: str    string to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTcpSocket::Write(const char *str)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TTcpSocket::Read
#
#   Purpose....: Read a single character
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
char TTcpSocket::Read()
{
    char ch = 0;

    if (FHandle)
        RdosReadTcpConnection(FHandle, &ch, 1);

    return ch;    
}

/*##########################################################################
#
#   Name       : TTcpSocket::Read
#
#   Purpose....: Read to buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: read chars
#
##########################################################################*/
int TTcpSocket::Read(char *buf, int size)
{
    if (FHandle)
        return RdosReadTcpConnection(FHandle, buf, size);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TUdpSocket::TUdpSocket
#
#   Purpose....: Constructor
#
#   In params..: IP         Remote IP address
#                LocalPort  local port to use
#                RemotePort remote port to connect to
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUdpSocket::TUdpSocket(long IP, int LocalPort, int RemotePort)
{
    FHandle = RdosOpenUdpConnection(IP, LocalPort, RemotePort);
    FLocalPort = LocalPort;
    FRemotePort = RemotePort;
    FRemoteIp = IP;
    Open();     
}

/*##########################################################################
#
#   Name       : TUdpSocket::~TUdpSocket
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUdpSocket::~TUdpSocket()
{
    if (FHandle)
        RdosCloseUdpConnection(FHandle);
}

/*##########################################################################
#
#   Name       : TUdpSocket::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TUdpSocket::DeviceName(char *Name, int MaxLen) const
{
    strncpy(Name,"UDP Socket",MaxLen);
}

/*##########################################################################
#
#   Name       : TUdpSocket::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait       Wait device
#                Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUdpSocket::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForUdpConnection(Wait->GetHandle(), FHandle, (int)this);
}

/*##################  TUdpSocket::NotifyClose  ############################
*   Purpose....: Notify socket closed                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TUdpSocket::NotifyClose()
{
    if (FHandle)
        RdosCloseUdpConnection(FHandle);
}

/*##################  TUdpSocket::GetRemoteIP  ############################
*   Purpose....: Get remote IP                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TUdpSocket::GetRemoteIP() const
{
    return FRemoteIp;
}

/*##################  TUdpSocket::GetRemotePort  ############################
*   Purpose....: Get remote port                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TUdpSocket::GetRemotePort() const
{
    return FRemotePort;
}

/*##################  TUdpSocket::GetLocalPort  ############################
*   Purpose....: Get local port                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TUdpSocket::GetLocalPort() const
{
    return FLocalPort;
}

/*##################  TUdpSocket::IsIdle  ############################
*   Purpose....: Check if connection is idle                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TUdpSocket::IsIdle()
{
    return TRUE;
}

/*##################  TUdpSocket::GetSize  ############################
*   Purpose....: Check size of message, if available                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TUdpSocket::GetSize()
{
    if (FHandle)
        return RdosPeekUdpConnection(FHandle);
    else
        return 0;
}

/*##################  TUdpSocket::GetWriteSpace  ############################
*   Purpose....: Check free bytes in send buffer                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TUdpSocket::GetWriteSpace()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TUdpSocket::Write
#
#   Purpose....: Write a buffer
#
#   In params..: buf     buffer to write
#                count   count to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUdpSocket::Write(const char *buf, int count)
{
    if (FHandle)
        RdosSendUdpConnection(FHandle, buf, count);
}

/*##########################################################################
#
#   Name       : TUdpSocket::Write
#
#   Purpose....: Write a string
#
#   In params..: str    string to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUdpSocket::Write(const char *str)
{
    if (FHandle)
        RdosSendUdpConnection(FHandle, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TUdpSocket::Read
#
#   Purpose....: Read to buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: read chars
#
##########################################################################*/
int TUdpSocket::Read(char *buf, int size)
{
    if (FHandle)
        return RdosReadUdpConnection(FHandle, buf, size);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TSocketServer::TSocketServer
#
#   Purpose....: Constructor for socket server
#
#   In params..: ThreadName     Name of server thread
#                                Socket         Socket to handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer::TSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
{
    int ip = Socket->GetRemoteIP();

    IpToString(FRemoteIp, ip);

    FSocket = Socket;
    FNext = 0;

    Start(Name, StackSize);
}

/*##########################################################################
#
#   Name       : TSocketServer::~TSocketServer
#
#   Purpose....: Destructor for socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer::~TSocketServer()
{
    if (FSocket)
        delete FSocket;
}

/*##########################################################################
#
#   Name       : TSocketServer::NotifyStarted
#
#   Purpose....: Notify server started
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::NotifyStarted()
{
}

/*##########################################################################
#
#   Name       : TSocketServer::NotifyStopped
#
#   Purpose....: Notify server stopped
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::NotifyStopped()
{
}

/*##########################################################################
#
#   Name       : TSocketServer::Execute
#
#   Purpose....: Execute socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::Execute()
{
    RdosWaitMilli(50);

    NotifyStarted();
        
    HandleSocket();
    
    FSocket->Close();
    delete FSocket;
    FSocket = 0;        

    NotifyStopped();
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::TSocketServerFactory
#
#   Purpose....: Constructor for socket server factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServerFactory::TSocketServerFactory(int Port, int MaxConnections, int BufferSize)
{
    FServerCount = 0;
    FList = 0;
    FListenHandle = RdosCreateTcpListen(Port, MaxConnections, BufferSize);
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::~TSocketServerFactory
#
#   Purpose....: Destructor for socket server factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServerFactory::~TSocketServerFactory()
{
     RdosCloseTcpListen(FListenHandle);
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::GetConnectionCount
#
#   Purpose....: Get connection count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSocketServerFactory::GetConnectionCount()
{
    Cleanup();
    return FServerCount;
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::Clearup
#
#   Purpose....: Cleanup terminated socket servers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServerFactory::Cleanup()
{
    TSocketServer *ptr;
    TSocketServer *prev;
    TSocketServer *temp;

    prev = 0;
    ptr = FList;
    while (ptr)
    {
        if (ptr->FSocket == 0)
        {
            FServerCount--;

            temp = ptr->FNext;
            delete ptr;
            if (prev == 0)
                FList = temp;
            else
                prev->FNext = temp;
            ptr = temp;
        }
        else
        {
            prev = ptr;
            ptr = ptr->FNext;
        }
    }
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::Insert
#
#   Purpose....: Insert into socket server list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServerFactory::Insert(TSocketServer *server)
{
    FServerCount++;

    server->FNext = FList;
    FList = server;
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::Add
#
#   Purpose....: Add this object to wait list
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServerFactory::Add(TWait *Wait)
{
    RdosAddWaitForTcpListen(Wait->GetHandle(), FListenHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::SignalNewData
#
#   Purpose....: Signal new data if available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServerFactory::SignalNewData()
{
    int handle;
    TTcpSocket *socket;

    Cleanup();
    handle = RdosGetTcpListen(FListenHandle);
    if (handle)
    {
        socket = new TTcpSocket(handle);
        Insert(Create(socket));
    }
}

/*##########################################################################
#
#   Name       : TSocketServerFactory::CloseAllSockets
#
#   Purpose....: Closes all open sockets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServerFactory::CloseAllSockets()
{
    TSocketServer *ptr;

    ptr = FList;

    while (ptr)
    {
        if (ptr->FSocket != 0)
        {
            ptr->FSocket->Close();
        }
        ptr = ptr->FNext;
    }

    // give the socket threads some time to terminate
    RdosWaitMilli(50);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::TUdpSocketListner
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUdpSocketListner::TUdpSocketListner(int Port, int MaxMessages)
{
    FHandle = RdosCreateUdpListen(Port, MaxMessages);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::~TUdpSocketListner
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUdpSocketListner::~TUdpSocketListner()
{
    if (FHandle)
        RdosCloseUdpListen(FHandle);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait       Wait device
#                Handle     UDP listen handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUdpSocketListner::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForUdpListen(Wait->GetHandle(), FHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::WaitForMsg
#
#   Purpose....: Wait for a new message
#
#   In params..: Timeout    milliseconds timeout
#   Out params.: *
#   Returns....: TRUE if available
#
##########################################################################*/
int TUdpSocketListner::WaitForMsg(long Timeout)
{
    if (!FWait)
        CreateWait();

    if (FWait)
        if (FWait->WaitTimeout(Timeout) == this)
            return HasMsg();

    return FALSE;
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::WaitForMsg
#
#   Purpose....: Wait indefinitely for new message
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if available
#
##########################################################################*/
int TUdpSocketListner::WaitForMsg()
{
    if (!FWait)
        CreateWait();

    if (FWait)
        if (FWait->WaitForever() == this)
            return HasMsg();

    return FALSE;
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUdpSocketListner::SignalNewData()
{
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::HasMsg
#
#   Purpose....: Check for unfetched message
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if available
#
##########################################################################*/
int TUdpSocketListner::HasMsg()
{
    if (RdosGetUdpListenSize(FHandle))
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::GetIP
#
#   Purpose....: Get IP for last message
#
#   In params..: *
#   Out params.: *
#   Returns....: IP
#
##########################################################################*/
long TUdpSocketListner::GetIP()
{
    return RdosGetUdpListenIp(FHandle);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::GetPort
#
#   Purpose....: Get port for last message
#
#   In params..: *
#   Out params.: *
#   Returns....: Port
#
##########################################################################*/
int TUdpSocketListner::GetPort()
{
    return RdosGetUdpListenPort(FHandle);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::GetMsgSize
#
#   Purpose....: Get size of last message (0 if no message)
#
#   In params..: *
#   Out params.: *
#   Returns....: size
#
##########################################################################*/
int TUdpSocketListner::GetMsgSize()
{
    return RdosGetUdpListenSize(FHandle);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::GetMsg
#
#   Purpose....: Get size of last message
#
#   In params..: *
#   Out params.: *
#   Returns....: size
#
##########################################################################*/
int TUdpSocketListner::GetMsg(char *buf, int size)
{
    return RdosGetUdpListenData(FHandle, buf, size);
}

/*##########################################################################
#
#   Name       : TUdpSocketListner::ClearMsg
#
#   Purpose....: Clear message
#
#   In params..: *
#   Out params.: *
#   Returns....: size
#
##########################################################################*/
void TUdpSocketListner::ClearMsg()
{
    RdosClearUdpListen(FHandle);
}
