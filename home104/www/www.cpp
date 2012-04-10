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
#include "bindata.h"

#define FALSE   0
#define TRUE    !FALSE


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
    TDeviceTag *tag;
    int year, month, day, hour;
    int min, sec, ms, us;
    TFile *file;
    int size;
    char *msg;
    TDeviceVar *var;
    long ival;
    long double val;

    header = doc->GetTag(LOG_TAG_HEADER);
    if (header)
    {
        msb = header->GetUnsignedInt(LOG_VAR_MsbTime, 0);
        lsb = header->GetUnsignedInt(LOG_VAR_LsbTime, 0);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);

        printf("%04d-%02d-%02d %02d.%02d", year, month, day, hour, min);

	    tag = doc->GetTag(LOG_TAG_OUTDOOR);

        if (tag)
        {
            var = tag->GetVar(LOG_VAR_Temp);
            if (var)
          	{
                ival = var->GetFloat1();

        		if (ival < 500 && ival > -500)
		        {
                    val = (long double)ival;
                    val = val / 10.0;
                    printf(", %5.1LfC ", val);
                }
       	    }
    
            var = tag->GetVar(LOG_VAR_Humidity);
            if (var)
	        {
                ival = var->GetSignedInt();

        		if (ival <= 100 && ival >= 0)
		        {
                    val = (long double)ival;
                    printf(", %3.0Lf%% ", val);
        	    }
	        }

        	var = tag->GetVar(LOG_VAR_Windspeed);
        	if (var)
	        {
                ival = var->GetFloat1();

        		if (ival < 400 && ival >= 0)
		        {
				    val = (long double)ival;
				    val = val / 10.0;
                    printf(", %4.1Lfm/s ", val);
        		 }
	        }

            var = tag->GetVar(LOG_VAR_Pressure);
            if (var)
	        {
                ival = var->GetFloat1();

        		if (ival < 11000 && ival >= 9000)
		        {
                    val = (long double)ival;
                    val = val / 10.0;
                    printf(", %6.1Lfhpa ", val);
        	    }
	        }
    
            var = tag->GetVar(LOG_VAR_Rain);
            if (var)
	        {
                ival = var->GetFloat1();

        		if (ival > 0)
		        {
                    val = (long double)ival;
	                val = val / 10.0;
                    printf(", %5.1Lfmm ", val);
        	    }
        	}
        }
        printf("\r\n");
     }
}

void cdecl main()
{
    TSocket *socket;
    int size;
    int count;
    char *msg;
    TDeviceMsg *doc;
    unsigned long Node;
    int i;

    TDataStore *DataStore;

    Node = 0x4201A8C0;

    for (i = 0; i < 10; i++)
    {
        if (RdosPing(Node, 2000))
        {
            printf("Weather station found\r\n");
            break;
        }
        else
            printf("Weather station ping failed\r\n");
    }

    DataStore = new TDataStore("e:\\data", "Data store", Node, 600);
//     DataStore->NotifyData = HandleRealData;

     for (;;)
     {
          socket = new TSocket(Node, 601, 600000, 0x4000);
          socket->WaitForConnection(600000);

          while (socket->IsOpen())
          {
                if (socket->WaitForChar(25000))
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
