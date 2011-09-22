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
#include "socket.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSocket::TSocket
#
#   Purpose....: Constructor
#
#   In params..: Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::TSocket(int Handle)
{
	FHandle = Handle;
	Open();
}

/*##########################################################################
#
#   Name       : TSocket::TSocket
#
#   Purpose....: Constructor
#
#   In params..: Wait       Wait device
#                IP         Remote IP address
#                Port       remote port to connect to
#				 Timeout	establish timeout in ms
#				 BufferSize	socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::TSocket(long IP, int Port, int Timeout, int BufferSize)
{
	FHandle = RdosOpenTcpConnection(IP, 0, Port, Timeout, BufferSize);
	Open();
}

/*##########################################################################
#
#   Name       : TSocket::TSocket
#
#   Purpose....: Constructor
#
#   In params..: Wait       Wait device
#                IP         Remote IP address
#                LocalPort  local port to use
#                RemotePort remote port to connect to
#				 Timeout	establish timeout in ms
#				 BufferSize	socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::TSocket(long IP, int LocalPort, int RemotePort, int Timeout, int BufferSize)
{
	FHandle = RdosOpenTcpConnection(IP, LocalPort, RemotePort, Timeout, BufferSize);
    Open();	
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
    if (FHandle)
    {
        RdosCloseTcpConnection(FHandle);
        RdosDeleteTcpConnection(FHandle);
    }
}

/*##########################################################################
#
#   Name       : TSocket::DeviceName
#
#   Purpose....: Returns device-name
#
#   In params..: MaxLen max size of name
#   Out params.: Name   device name
#   Returns....: *
#
##########################################################################*/
void TSocket::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"Socket",MaxLen);
}

/*##########################################################################
#
#   Name       : TSocket::Add
#
#   Purpose....: Add object to wait
#
#   In params..: Wait       Wait device
#                Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::Add(TWait *Wait)
{
	if (FHandle)
		RdosAddWaitForTcpConnection(Wait->GetHandle(), FHandle, this);
}

/*##################  TSocket::IsOpen  ############################
*   Purpose....: Check if socket is open		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::IsOpen() const
{
    if (TDevice::IsOpen() && FHandle)
	    return !RdosIsTcpConnectionClosed(FHandle);
    else    
	    return FALSE;
}

/*##################  TSocket::NotifyClose  ############################
*   Purpose....: Notify socket closed		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSocket::NotifyClose()
{
	if (FHandle)
		RdosCloseTcpConnection(FHandle);
}

/*##################  TSocket::GetLocalIP  ############################
*   Purpose....: Get local IP          		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TSocket::GetLocalIP()
{
	return RdosGetIp();
}

/*##################  TSocket::GetRemoteIP  ############################
*   Purpose....: Get remote IP          		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long TSocket::GetRemoteIP() const
{
	if (FHandle)
		return RdosGetRemoteTcpConnectionIP(FHandle);
	else
		return -1;
}

/*##################  TSocket::GetRemotePort  ############################
*   Purpose....: Get remote port          		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::GetRemotePort() const
{
	if (FHandle)
		return RdosGetRemoteTcpConnectionPort(FHandle);
	else
		return 0;
}

/*##################  TSocket::GetLocalPort  ############################
*   Purpose....: Get local port          		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::GetLocalPort() const
{
	if (FHandle)
		return RdosGetLocalTcpConnectionPort(FHandle);
	else
	    return 0;
}

/*##################  TSocket::Push  ############################
*   Purpose....: Push connection        		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSocket::Push()
{
	if (FHandle)
	    RdosPushTcpConnection(FHandle);
}

/*##################  TSocket::IsIdle  ############################
*   Purpose....: Check if connection is idle (no unsent data & no received data)        		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::IsIdle()
{
	if (FHandle)
	    return RdosIsTcpConnectionIdle(FHandle);
	else
	    return TRUE;
}

/*##################  TSocket::WaitForConnection  ############################
*   Purpose....: Wait for a connection		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::WaitForConnection(int Timeout)
{
	if (FHandle)
		return RdosWaitForTcpConnection(FHandle, Timeout);
	else
	    return FALSE;
}

/*##########################################################################
#
#   Name       : TSocket::Write
#
#   Purpose....: Write a char
#
#   In params..: ch     char to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::Write(char ch)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, &ch, 1);
}

/*##########################################################################
#
#   Name       : TSocket::Write
#
#   Purpose....: Write a buffer
#
#   In params..: buf     buffer to write
#                count   count to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::Write(const char *buf, int count)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, buf, count);
}

/*##########################################################################
#
#   Name       : TSocket::Write
#
#   Purpose....: Write a string
#
#   In params..: str    string to write
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::Write(const char *str)
{
    if (FHandle)
        RdosWriteTcpConnection(FHandle, str, strlen(str));
}

/*##################  TSocket::Poll  ############################
*   Purpose....: Check available bytes in receive buffer	                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::Poll()
{
	if (FHandle)
		return RdosPollTcpConnection(FHandle);
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TSocket::WaitForChar
#
#   Purpose....: Wait for something in the receive buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if available
#
##########################################################################*/
int TSocket::WaitForChar(long Timeout)
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
#   Name       : TSocket::Read
#
#   Purpose....: Read a single character
#
#   In params..: *
#   Out params.: *
#   Returns....: character
#
##########################################################################*/
char TSocket::Read()
{
    char ch = 0;

    if (FHandle)
        RdosReadTcpConnection(FHandle, &ch, 1);

    return ch;    
}

/*##########################################################################
#
#   Name       : TSocket::Read
#
#   Purpose....: Read to buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: read chars
#
##########################################################################*/
int TSocket::Read(char *buf, int size)
{
    if (FHandle)
        return RdosReadTcpConnection(FHandle, buf, size);
    else
        return 0;
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
#   Name       : TSocketServer::TSocketServer
#
#   Purpose....: Constructor for socket server
#
#   In params..: ThreadName     Name of server thread
#				 Socket         Socket to handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer::TSocketServer(const char *Name, int StackSize, TSocket *Socket)
{
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
        
	if (FSocket->WaitForConnection(6000))
	{
    	HandleSocket();
    	FSocket->Push();
    }
    
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
	RdosAddWaitForTcpListen(Wait->GetHandle(), FListenHandle, this);
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
	TSocket *socket;

    Cleanup();
	handle = RdosGetTcpListen(FListenHandle);
	if (handle)
	{
	    socket = new TSocket(handle);
		Insert(Create(socket));
	}
}

