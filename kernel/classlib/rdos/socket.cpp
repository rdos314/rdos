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

TSection TSocketServer::FSection;
TSocketServer *TSocketServer::FList = 0;

static TSection ConnectionSection;

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
TSocketServer::TSocketServer()
{
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
}

/*##########################################################################
#
#   Name       : TSocketServer::ThreadStartup
#
#   Purpose....: Startup of socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::ThreadStartup(int Handle)
{
    FWait = new TWait;
	FSocket = new TSocket(FWait, Handle);

    Cleanup();
	Insert();    

	HandleSocket();

	FSocket->Push();
	FSocket->Close();
    delete FSocket;
    delete FWait;
    FWait = 0;
    FSocket = 0;	
}

/*##########################################################################
#
#   Name       : TSocketServer::Clearup
#
#   Purpose....: Cleanup terminated socket servers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::Cleanup()
{
	TSocketServer *ptr;
	TSocketServer *prev;
    TSocketServer *temp;
	
	prev = 0;
	FSection.Enter();
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
	    	ptr = ptr->FList;
	    }
    }
	FSection.Leave();
}

/*##########################################################################
#
#   Name       : TSocketServer::Insert
#
#   Purpose....: Insert into socket server list
#				 Should only done in constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocketServer::Insert()
{
	FSection.Enter();
	FNext = FList;
	FList = this;
	FSection.Leave();
}

/*##########################################################################
#
#   Name       : ConnectionThread
#
#   Purpose....: Connection thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ConnectionThread(void *Data)
{
	TSocketServerFactory *Factory = (TSocketServerFactory *)Data;
	int Handle = Factory->Handle;
	
    ConnectionSection.Leave();
	TSocketServer *Server = Factory->Create();
    Server->ThreadStartup(Handle);
}

/*##########################################################################
#
#   Name       : NewConnection
#
#   Purpose....: New connection callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void __stdcall NewConnection(int Handle, void *Data)
{
	TSocketServerFactory *Factory = (TSocketServerFactory *)Data;
	
    ConnectionSection.Enter();
    Factory->Handle = Handle;    	
	RdosCreateThread(ConnectionThread, Factory->GetThreadName(), Data, Factory->GetStackSize());
}

/*##########################################################################
#
#   Name       : TSocket::Listen
#
#   Purpose....: Listen for connections on a specified port
#
#   In params..: Port       local port to listen on
#				 BufferSize	socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSocket::Listen(TSocketServerFactory *Factory, int Port, int BufferSize)
{
	for (;;)
		RdosListenTcpPort(Port, BufferSize, NewConnection, Factory);
}

/*##########################################################################
#
#   Name       : TSocket::TSocket
#
#   Purpose....: Constructor
#
#   In params..: Wait       Wait device
#                Handle     Socket handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::TSocket(TWait *Wait, int Handle)
{
	FHandle = Handle;

	if (FHandle)
		RdosAddWaitForTcpConnection(RegisterWait(Wait), FHandle, this);
}

/*##########################################################################
#
#   Name       : TSocket::TSocket
#
#   Purpose....: Constructor
#
#   In params..: Wait       Wait device
#                IP         Remote IP address
#                Port       local port to listen on
#				 Timeout	establish timeout in ms
#				 BufferSize	socket buffer size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocket::TSocket(TWait *Wait, long IP, int Port, int Timeout, int BufferSize)
{
	FHandle = 0;

	FHandle = RdosOpenTcpConnection(IP, 0, Port, Timeout, BufferSize);

	if (FHandle)
		RdosAddWaitForTcpConnection(RegisterWait(Wait), FHandle, this);
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
        RdosCloseTcpConnection(FHandle);
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

/*##################  TSocket::IsOpen  ############################
*   Purpose....: Check if socket is open		                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSocket::IsOpen() const
{
	if (FHandle)
		return !RdosIsTcpConnectionClosed(FHandle);
	else
	    return FALSE;
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
	TWait *Wait = GetWait();

	if (Wait)
		if (Wait->WaitTimeout(Timeout) == this)
			return TRUE;

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
    char ch = 0;

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
