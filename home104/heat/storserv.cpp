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
# storserv.cpp
# Storage socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "socket.h"
#include "storserv.h"
#include "cotdata.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TStorageSocketServer::TStorageSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageSocketServer::TStorageSocketServer(TStorageList *StorList, const char *Name, int StackSize, TSocket *Socket)
  : TCotexSocketServer(Name, StackSize, Socket)
{
    FStorList = StorList;
}

/*##########################################################################
#
#   Name       : TStorageSocketServer::~TStorageSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageSocketServer::~TStorageSocketServer()
{
}

/*##########################################################################
#
#   Name       : TStorageSocketServer::SendCotex
#
#   Purpose....: Send cotex formatted data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageSocketServer::SendCotex(THeatData *data)
{
	int size;
	char *msg;
	char ch;
    TDeviceMsg *doc = ConvToCotex(data);
        
    size = doc->GetSize();
    msg = new char[size];
	 doc->GetData(COT_SIGN, msg);

	 if (FSocket->IsOpen())
	 {
		  FSocket->Write((char *)&size, 4);
		  FSocket->Write(msg, size);
		  FSocket->Push();

        if (FSocket->WaitForChar(30000))
        {
            ch = FSocket->Read();

            if (ch == 0x6)
                FStorList->RemoveCurrent();
        }
    }
        
    delete msg;
    delete doc;
}

/*##########################################################################
#
#   Name       : TStorageSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageSocketServer::HandleSocket()
{
    THeatData *data;    

    while (FSocket->IsOpen())
    {
        if (FStorList->IsEmpty())
            FSocket->Close();
        else
        {
            FStorList->GotoFirst();
            data = (THeatData *)FStorList->Get();
            SendCotex(data);
        }
    }
}

/*##########################################################################
#
#   Name       : TStorageSocketServerFactory::TStorageSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageSocketServerFactory::TStorageSocketServerFactory(TStorageList *StorList, int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    FStorList = StorList;
}

/*##########################################################################
#
#   Name       : TStorageSocketServerFactory::~TStorageSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageSocketServerFactory::~TStorageSocketServerFactory()
{
}        

/*##########################################################################
#
#   Name       : TStorageSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TStorageSocketServerFactory::Create(TSocket *Socket)
{
	TStorageSocketServer *server;
	server = new TStorageSocketServer(FStorList, "Storage", 0x2000, Socket);

	return server;
}
