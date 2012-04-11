/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# realserv.cpp
# Realtime data socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "socket.h"
#include "realserv.h"
#include "cotdata.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TRealtimeSocketServer::TRealtimeSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeSocketServer::TRealtimeSocketServer(TRealtimeSocketServerFactory *fact, const char *Name, int StackSize, TSocket *Socket)
  : TCotexSocketServer(Name, StackSize, Socket)
{
    FFactory = fact;
    FNewData = FALSE;
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServer::~TRealtimeSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeSocketServer::~TRealtimeSocketServer()
{
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeSocketServer::HandleSocket()
{
    TDeviceMsg *doc;
    int size;
    char *msg;
    char ch;

	 FFactory->InsertServer(this);
        
    while (FSocket->IsOpen())
    {
        FSignal.WaitForever();

        if (FSocket->IsOpen() && FNewData)
		  {
				doc = ConvToCotex(&FHeatData);

				FNewData = FALSE;

				size = doc->GetSize();
				msg = new char[size];
				doc->GetData(COT_SIGN, msg);

				delete doc;

				FSocket->Write((char *)&size, 4);
				FSocket->Write(msg, size);
				FSocket->Push();

				delete msg;

                if (FSocket->WaitForChar(30000))
                    ch = FSocket->Read();

		  }
	 }

	 FFactory->RemoveServer(this);
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServer::SendData
#
#   Purpose....: Send realtime data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeSocketServer::SendData(THeatData *data)
{
    memcpy(&FHeatData, data, sizeof(THeatData));
    FNewData = TRUE;

    FSignal.Signal();
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::TRealtimeSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeSocketServerFactory::TRealtimeSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    FServerList = 0;
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::~TRealtimeSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRealtimeSocketServerFactory::~TRealtimeSocketServerFactory()
{
}        

/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TRealtimeSocketServerFactory::Create(TSocket *Socket)
{
	TRealtimeSocketServer *server;
	server = new TRealtimeSocketServer(this, "Realtime", 0x2000, Socket);

	return server;
}


/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::InsertServer
#
#   Purpose....: Insert socket-server into list
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeSocketServerFactory::InsertServer(TRealtimeSocketServer *server)
{
    FServerSection.Enter();

    server->FNext = FServerList;
    FServerList = server;

    FServerSection.Leave();
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::RemoveServer
#
#   Purpose....: Remove socket-server from list                   
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeSocketServerFactory::RemoveServer(TRealtimeSocketServer *server)
{
    TRealtimeSocketServer *ptr;
    TRealtimeSocketServer *prev;

    prev = 0;
    FServerSection.Enter();
    ptr = FServerList;

    while ((ptr != 0) && (ptr != server))
    {
        prev = ptr;
        ptr = ptr->FNext;
    }
    
    if (prev == 0)
        FServerList = FServerList->FNext;
    else
        prev->FNext = ptr->FNext;

    FServerSection.Leave();
}

/*##########################################################################
#
#   Name       : TRealtimeSocketServerFactory::SendData
#
#   Purpose....: Send realtime data to all socket-servers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRealtimeSocketServerFactory::SendData(THeatData *data)
{
    TRealtimeSocketServer *ptr;

    FServerSection.Enter();

    ptr = FServerList;
    while (ptr)
    {
        ptr->SendData(data);
        ptr = ptr->FNext;
    }

    FServerSection.Leave();
}
