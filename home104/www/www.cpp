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
# www.cpp
# WWW heat control program
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "socket.h"
#include "datastor.h"
#include "cotdata.h"
#include "wwwdata.h"

#define FALSE	0
#define TRUE	!FALSE

int CurrYear = 0;
int CurrMonth = 0;
int CurrDay = 0;

TWwwDataEntry CurrData[24][60];


/*##########################################################################
#
#   Name       : InitRadData
#
#   Purpose....: Init rad data structure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitRadData(TWwwRadData *data)
{
    data->Ref.valid = FALSE;
	 data->Temp.valid = FALSE;
	 data->Motor.valid = FALSE;
	 data->Light.valid = FALSE;
	 data->AuxTemp.valid = FALSE;
}

/*##########################################################################
#
#   Name       : InitWwwData
#
#   Purpose....: Init www data entry structure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitWwwData(TWwwDataEntry *data)
{
	 int rad;

	 data->Temp.valid = FALSE;
	 data->Humidity.valid = FALSE;
	 data->WindSpeed.valid = FALSE;
	 data->WindDir.valid = FALSE;
	 data->AirPressure.valid = FALSE;
	 data->CircSpeed.valid = FALSE;
	 data->TankTemp.valid = FALSE;
	 data->TankP.valid = FALSE;
	 data->HeatTemp.valid = FALSE;
	 data->HeatP.valid = FALSE;
	 data->Vp.valid = FALSE;
	 data->Ep.valid = FALSE;

	 for (rad = 0; rad < RAD_COUNT; rad++)
		  InitRadData(&data->Rad[rad]);
}

/*##########################################################################
#
#   Name       : DecodeOutdoor
#
#   Purpose....: Decode outdoor tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeOutdoor(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival < 500 && ival > -500)
		{
            val = (long double)ival;
	        data->Temp.val = val / 10.0;
	        data->Temp.valid = TRUE;
	    }
	}
    
    var = tag->GetVar(LOG_VAR_Humidity);
    if (var)
	{
        ival = var->GetSignedInt();

		if (ival <= 100 && ival >= 0)
		{
            val = (long double)ival;
	        data->Humidity.val = val;
	        data->Humidity.valid = TRUE;
	    }
	}

	 var = tag->GetVar(LOG_VAR_Windspeed);
	 if (var)
	{
		  ival = var->GetFloat1();

		if (ival < 400 && ival >= 0)
		{
				val = (long double)ival;
			  data->WindSpeed.val = val / 10.0;
			  data->WindSpeed.valid = TRUE;
		 }
	}

	 var = tag->GetVar(LOG_VAR_Winddir);
	 if (var)
	{
        ival = var->GetSignedInt();

		if (ival <= 360 && ival >= 0)
		{
		    ival = ival % 360;
            val = (long double)ival;
			  data->WindDir.val = val;
	        data->WindDir.valid = TRUE;
	    }
	}
    
    var = tag->GetVar(LOG_VAR_Pressure);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival < 11000 && ival >= 9000)
		{
            val = (long double)ival;
	        data->AirPressure.val = val / 10.0;
	        data->AirPressure.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : DecodeCirc
#
#   Purpose....: Decode circ tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeCirc(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Motor);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 110 && ival >= 0)
		{
            val = (long double)ival;
	        data->CircSpeed.val = val / 10.0;
	        data->CircSpeed.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : DecodeVp
#
#   Purpose....: Decode VP tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeVp(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_On);
    if (var)
	{
	    data->Vp.val = var->GetBoolean();
	    data->Vp.valid = TRUE;
	}
}

/*##########################################################################
#
#   Name       : DecodeTank
#
#   Purpose....: Decode tank tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeTank(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
	 long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->TankTemp.val = val / 10.0;
	        data->TankTemp.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_P);
    if (var)
	{
        ival = var->GetFloat2();

		if (ival <= 1000 && ival >= -1000)
		{
            val = (long double)ival;
	        data->TankP.val = val / 100.0;
	        data->TankP.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : DecodeHeat
#
#   Purpose....: Decode heat tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeHeat(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->HeatTemp.val = val / 10.0;
	        data->HeatTemp.valid = TRUE;
	    }
	}

	 var = tag->GetVar(LOG_VAR_P);
    if (var)
	{
        ival = var->GetFloat2();

		if (ival <= 1000 && ival >= -1000)
		{
            val = (long double)ival;
	        data->HeatP.val = val / 100.0;
	        data->HeatP.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_On);
    if (var)
	{
	    data->Ep.val = var->GetBoolean();
	    data->Ep.valid = TRUE;
	}
}

/*##########################################################################
#
#   Name       : DecodeRadData
#
#   Purpose....: Decode rad data tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeRadData(TDeviceTag *tag, TWwwRadData *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Ref);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->Ref.val = val / 10.0;
	        data->Ref.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Temp);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->Temp.val = val / 10.0;
			  data->Temp.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Motor);
    if (var)
	{
        ival = var->GetFloat1();

		if (ival <= 110 && ival >= 0)
		{
            val = (long double)ival;
	        data->Motor.val = val / 10.0;
	        data->Motor.valid = TRUE;
	    }
	}

    var = tag->GetVar(LOG_VAR_Light);
    if (var)
	{
        ival = var->GetFloat1();

        val = (long double)ival;
	    data->Light.val = val / 10.0;
	    data->Light.valid = TRUE;
	}

    var = tag->GetVar(LOG_VAR_AuxTemp);
    if (var)
	{
		  ival = var->GetFloat1();

		if (ival <= 1000 && ival >= 0)
		{
            val = (long double)ival;
	        data->AuxTemp.val = val / 10.0;
	        data->AuxTemp.valid = TRUE;
	    }
	}
}

/*##########################################################################
#
#   Name       : DecodeRad
#
#   Purpose....: Decode rad tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeRad(TDeviceTag *tag, TWwwDataEntry *data)
{
    TDeviceVar *var;
    long ival;
    long double val;
    
    var = tag->GetVar(LOG_VAR_Address);
    if (var)
	{
        ival = var->GetSignedInt();

        if (ival >= 0x20)
        {
            ival -= 0x20;

            if (ival < RAD_COUNT)
                DecodeRadData(tag, &data->Rad[ival]);
        }
    }
}            

/*##########################################################################
#
#   Name       : CotexToBinary
#
#   Purpose....: Convert cotex to binary data format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CotexToBinary(TDeviceMsg *doc, TWwwDataEntry *data)
{
    TDeviceTag *tag;
    long ival;

	 InitWwwData(data);

	 tag = doc->GotoFirstTag();
	while (tag)
    {
        switch (tag->GetID())
        {
            case LOG_TAG_OUTDOOR:
                DecodeOutdoor(tag, data);
                break;

            case LOG_TAG_CIRC:
                DecodeCirc(tag, data);
                break;
                
            case LOG_TAG_VP:
                DecodeVp(tag, data);
                break;
                
            case LOG_TAG_TANK:
                DecodeTank(tag, data);
                break;
                
            case LOG_TAG_HEAT:
                DecodeHeat(tag, data);
                break;

            case LOG_TAG_RAD:
                DecodeRad(tag, data);
                break;
        }

        tag = doc->GotoNextTag();
    }
}

/*##########################################################################
#
#   Name       : HandleRealData
#
#   Purpose....: Handle realtime data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HandleRealData(TDeviceMsg *doc)
{
    unsigned long msb, lsb;
	TDeviceTag *header;
	int year, month, day, hour;
	int min, sec, ms, us;
	TFile *file;
	int size;
	char *msg;

	header = doc->GetTag(LOG_TAG_HEADER);
	if (header)
	{
        msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
		lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
		RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
		RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

		printf("%04d-%02d-%02d %02d.%02d\r\n", year, month, day, hour, min);
    }
}

void cdecl main()
{
	 TSocket *socket;
	 int size;
	 int count;
	 char *msg;
	 TDeviceMsg *doc;

	 TDataStore *DataStore;

	 DataStore = new TDataStore("e:\\data", "Data store", 0x2800A8C0, 600);
	 DataStore->NotifyData = HandleRealData;

	 for (;;)
	 {
		  socket = new TSocket(0x2800A8C0, 601, 600000, 0x4000);
		  socket->WaitForConnection(600000);

		  while (socket->IsOpen())
		  {
				  if (socket->WaitForChar(30000))
				  {
					count = socket->Read((char *)&size, 4);
					if (count == 4)
					{
						 msg = new char[size];
						count = socket->Read(msg, size);

						if (count == size)
						{
							  doc = new TDeviceMsg(MAX_MSG_SIZE);

							if (doc->Parse(COT_SIGN, msg, size))
							{
								 delete msg;
								HandleRealData(doc);
					    	}
						    else
						    { 
							    delete msg;
								socket->Close();
						    }

						    delete doc;
       					 }
					     else
						    socket->Close();
				    }
				}
				else
				{
    				socket->Push();
					 RdosWaitMilli(250);
    		    }
		  }
		  delete socket;
	 }
}
