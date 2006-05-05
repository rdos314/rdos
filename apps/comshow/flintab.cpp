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
# flintab.cpp
# Flintab protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "flintab.h"

#define FALSE	0
#define TRUE	!FALSE

#define SOH     1
#define STX     2
#define ETX     3
#define EOT     4
#define ACK     6
#define NAK     0x15

/*##################  TFlintabProtocolAnalyser::TFlintabProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TFlintabProtocolAnalyser::TFlintabProtocolAnalyser(TFile *RawFile, int MaxSize)
  : TProtocolAnalyser(RawFile, MaxSize)
{
}

/*##################  TFlintabProtocolAnalyser::~TFlintabProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TFlintabProtocolAnalyser::~TFlintabProtocolAnalyser()
{
}

/*##################  TFlintabProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next current loop message	   		         	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TFlintabProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	unsigned char cmd;
	TSerialDebug Debug;
	int Pos;
	int size;
	TDateTime *time;

	if (FRawFile->GetSize() <= FRawFile->GetPos())
		return FALSE;

	if (FTime)
		delete FTime;
	FTime = 0;

	str = FMsg;
	*str = 0;
	FSize = 0;

	while (FRawFile->GetSize() > FRawFile->GetPos())
	{
		Pos = FRawFile->GetPos();
		FRawFile->Read(&Debug, sizeof(TSerialDebug));

		if (FTime)
		{
			time = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
			delete time;
		}
		else
		{
			FTime = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
			FChannel = Debug.Channel;
			LastTime = Debug.TimeLSB;
		}

		ch = Debug.ch;

		if (FChannel != Debug.Channel)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		Elapsed = Debug.TimeLSB - LastTime;
		if (Elapsed > 1193 * 1000)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		LastTime = Debug.TimeLSB;
		ch = Debug.ch;

		FSize++;
		*str = ch;
		str++;
		*str = 0;

		switch (ch)
		{
	        case EOT:
	            return TRUE;

	        case ACK:
	            return TRUE;
	    }
	}

	return TRUE;
}

/*##################  TFlintabProtocolAnalyser::GetData ##########################
*   Purpose....: Get data between STX and ETX	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char *TFlintabProtocolAnalyser::GetData(char *msg)
{
    char *start;
    char *ptr;
    char sum;
    
    if (*msg == STX)
    {
        sum = *msg;
        start = msg + 1;
        ptr = start;

        while (*ptr && *ptr != ETX)
        {
            sum += *ptr;
            ptr++;
        }

        if (*ptr = ETX)
        {
            sum += *ptr;

            ptr++;
            if (*ptr == sum)
            {
                ptr--;
                *ptr = 0;
                return start;
            }
            else
                return 0;
        }
        
    }
    return 0;
}

/*##################  TFlintabProtocolAnalyser::ShowCardReq ##########################
*   Purpose....: Show card req msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowCardReq(char *msg)
{
    char *ptr;

    ptr = GetData(msg);

    if (ptr && strlen(ptr) == 6)
    {
        ShowLongTime(FTime);
        Write("CARD REQ: Card <");
        Write(ptr);
        Write(">\n");
    }
    else
        TProtocolAnalyser::ShowMsg();        
}

/*##################  TFlintabProtocolAnalyser::ShowCardAck ##########################
*   Purpose....: Show card ack msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowCardAck(char *msg)
{
    char *ptr;
    char status;
    char str[10];

    ptr = GetData(msg);

    if (ptr && strlen(ptr) == 7)
    {
        status = ptr[6];
        ptr[6] = 0;
        
        ShowLongTime(FTime);
        Write("CARD ACK: Card <");
        Write(ptr);

        sprintf(str, ">, Status %c\n", status);
        Write(str);
    }
    else
        TProtocolAnalyser::ShowMsg();        
}

/*##################  TFlintabProtocolAnalyser::ShowFillReq ##########################
*   Purpose....: Show fill req msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowFillReq(char *msg)
{
    char *ptr;
    char str[80];
    long val;

    ptr = GetData(msg);

    if (ptr && strlen(ptr) == 21)
    {
        ShowLongTime(FTime);
        Write("FILL REQ: Card <");

        memcpy(str, ptr, 6);
        str[6] = 0;
        Write(str);

        memcpy(str, ptr + 6, 6);
        str[6] = 0;
        val = atol(str);
        sprintf(str, ">, Volume %ld", val);
        Write(str);        
        
        val = atol(ptr + 12);
        sprintf(str, ", Seq %ld\n", val);
        Write(str);        
    }
    else
        TProtocolAnalyser::ShowMsg();        
}

/*##################  TFlintabProtocolAnalyser::ShowSoh ##########################
*   Purpose....: Show SOH msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowSoh(char *msg)
{
    switch (*msg)
    {
        case 'd':
            ShowCardReq(msg + 1);
            break;

        case 'e':
            ShowCardAck(msg + 1);
            break;

        case 'f':
            ShowFillReq(msg + 1);
            break;

        default:
            TProtocolAnalyser::ShowMsg();
            break;
    }
}

/*##################  TFlintabProtocolAnalyser::ShowAck ##########################
*   Purpose....: Show ACK msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowAck()
{
    if (FSize == 1)
    {
    	ShowLongTime(FTime);
        Write("ACK\n");
    }
    else
        TProtocolAnalyser::ShowMsg();
}

/*##################  TFlintabProtocolAnalyser::ShowNak ##########################
*   Purpose....: Show NAK msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowNak()
{
    if (FSize == 1)
    {
    	ShowLongTime(FTime);
        Write("NAK\n");
    }
    else
        TProtocolAnalyser::ShowMsg();
}

/*##################  TFlintabProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show current loop msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TFlintabProtocolAnalyser::ShowMsg()
{
    switch (FMsg[0])
    {
        case SOH:
            ShowSoh(&FMsg[1]);
            break;

        case ACK:
            ShowAck();
            break;

		case NAK:
			ShowNak();
            break;

        default:
            ShowLongTime(FTime);
        	ShowHexMsg();
        	break;
    }
}
