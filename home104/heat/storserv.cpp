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
  : TSocketServer(Name, StackSize, Socket)
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
#   Name       : TStorageSocketServer::AddRadData
#
#   Purpose....: Add rad data to cotex
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageSocketServer::AddRadData(TRadData *data, TDeviceMsg *doc)
{
	TDeviceTag *tag;
	int ival;

	tag = doc->AddTag(LOG_TAG_RAD);
	tag->AddSignedInt(LOG_VAR_Address, data->Address);

	ival = 10.0 * data->Ref;
	tag->AddFloat1(LOG_VAR_Ref, ival);
	
	ival = 10.0 * data->Temp;
	tag->AddFloat1(LOG_VAR_Temp, ival);

	ival = 10.0 * data->Motor;
	tag->AddFloat1(LOG_VAR_Motor, ival);

	ival = 10.0 * data->Light;
	tag->AddFloat1(LOG_VAR_Light, ival);

	ival = 10.0 * data->AuxTemp;
	tag->AddFloat1(LOG_VAR_AuxTemp, ival);
}

/*##########################################################################
#
#   Name       : TStorageSocketServer::ConvToCotex
#
#   Purpose....: Convert data to cotex
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceMsg *TStorageSocketServer::ConvToCotex(THeatData *data)
{
	TDeviceMsg *doc;
	TDeviceTag *tag;
	int ival;
   int i;

	doc = new TDeviceMsg(MAX_MSG_SIZE);

	tag = doc->AddTag(LOG_TAG_HEADER);
	tag->AddUnsignedLong(LOG_VAR_MsbTime, data->Msb);
	tag->AddUnsignedLong(LOG_VAR_LsbTime, data->Lsb);

	if (data->HasWs)
	{
	    tag = doc->AddTag(LOG_TAG_INDOOR);
		ival = 10.0 * data->IndoorTemp;
		tag->AddFloat1(LOG_VAR_Temp, ival);

		ival = data->IndoorHumidity;
		tag->AddSignedInt(LOG_VAR_Humidity, ival);

		tag = doc->AddTag(LOG_TAG_OUTDOOR);
		ival = 10.0 * data->OutdoorTemp;
		tag->AddFloat1(LOG_VAR_Temp, ival);

		ival = data->OutdoorHumidity;
		tag->AddSignedInt(LOG_VAR_Humidity, ival);

		ival = 10.0 * data->DewPoint;
		tag->AddFloat1(LOG_VAR_Dewpoint, ival);

		ival = 10.0 * data->WindChill;
		tag->AddFloat1(LOG_VAR_Windchill, ival);

		ival = 10.0 * data->WindSpeed;
	    tag->AddFloat1(LOG_VAR_Windspeed, ival);

		ival = data->WindDir;
		tag->AddSignedInt(LOG_VAR_Winddir, ival);

		ival = 10.0 * data->AirPressure;
		tag->AddFloat1(LOG_VAR_Pressure, ival);

		if (data->HasRain)
		{
		    tag = doc->AddTag(LOG_TAG_RAIN);

			ival = 10.0 * data->Rain1h;
		    tag->AddFloat1(LOG_VAR_Rain, ival);
		}
	}

	if (data->HasCirc)
	{
        tag = doc->AddTag(LOG_TAG_CIRC);
	    ival = 10.0 * data->CircSpeed;
		tag->AddFloat1(LOG_VAR_Motor, ival);
	}

    if (data->HasVp)
	{
		tag = doc->AddTag(LOG_TAG_VP);
		ival = data->VpOn;
		tag->AddBoolean(LOG_VAR_On, ival);

		ival = data->EpOn;
		tag->AddBoolean(LOG_VAR_On, ival);
		
		if (data->HasTankTemp)
		{
			tag = doc->AddTag(LOG_TAG_TANK);
    	    ival = 10.0 * data->TankTemp;
		    tag->AddFloat1(LOG_VAR_Temp, ival);

			if (data->HasTankP)
			{
			    ival = 100.0 * data->TankP;
				tag->AddFloat2(LOG_VAR_P, ival);
			}
		}

		if (data->HasHeatTemp)
		{
			tag = doc->AddTag(LOG_TAG_HEAT);
    	    ival = 10.0 * data->HeatTemp;
			tag->AddFloat1(LOG_VAR_Temp, ival);

			if (data->HasHeatP)
			{
			    ival = 100.0 * data->HeatP;
				tag->AddFloat2(LOG_VAR_P, ival);
		    }
		}
    }

    for (i = 0; i < RAD_COUNT; i++)
        if (data->Rad[i].HasData)
            AddRadData(&data->Rad[i], doc);

    return doc;
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
