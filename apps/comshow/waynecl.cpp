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
# waynecl.cpp
# Wayne current loop protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "waynecl.h"

#define FALSE	0
#define TRUE	!FALSE

#define STATUS_RESET            0x41
#define STATUS_RESET_CALL       0x42
#define STATUS_AUTHORIZED       0x43
#define STATUS_FILLING          0x44
#define STATUS_COMPLETED        0x45
#define STATUS_COMPLETED_CALL   0x46
#define STATUS_MAX_AMOUNT       0x4C

#define STX         2
#define ETX         3

/*##################  TWayneClProtocolAnalyser::TWayneClProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TWayneClProtocolAnalyser::TWayneClProtocolAnalyser(TFile *RawFile, int MaxSize)
  : TProtocolAnalyser(RawFile, MaxSize)
{
}

/*##################  TWayneClProtocolAnalyser::~TWayneClProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TWayneClProtocolAnalyser::~TWayneClProtocolAnalyser()
{
}

/*##################  TWayneClProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next current loop message	   		         	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TWayneClProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	TSerialDebug Debug;
	int StartPos;
	int Pos;
	int done;

	if (FRawFile->GetSize() <= FRawFile->GetPos())
        return FALSE;

    if (FTime)
        delete FTime;
    FTime = 0;

	str = FMsg;
	*str = 0;
	FSize = 0;

	done = FALSE;

	StartPos = FRawFile->GetPos();

    done = FALSE;
    
	while (FRawFile->GetSize() > FRawFile->GetPos() && !done)
	{

        Pos = FRawFile->GetPos();
	    FRawFile->Read(&Debug, sizeof(TSerialDebug));

	    if (!FTime)
	    {
        	FTime = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
        	Channel = Debug.Channel;
        	LastTime = Debug.TimeLSB;
        }

		if (Channel != Debug.Channel)
		{
		    FRawFile->SetPos(StartPos);
			return TRUE;
		}

		Elapsed = Debug.TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
		{
		    FRawFile->SetPos(Pos);
			return TRUE;
		}

		ch = Debug.ch;

        if (ch == STX)
            done = TRUE;

		LastTime = Debug.TimeLSB;
	}

	if (!done)
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

    done = FALSE;
    
	while (FRawFile->GetSize() > FRawFile->GetPos() && !done)
	{
        Pos = FRawFile->GetPos();
	    FRawFile->Read(&Debug, sizeof(TSerialDebug));

		if (Channel != Debug.Channel)
		{
		    FRawFile->SetPos(Pos);
			return TRUE;
		}
		
		Elapsed = Debug.TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
		{
		    FRawFile->SetPos(Pos);
			return TRUE;
		}

		LastTime = Debug.TimeLSB;
		ch = Debug.ch;

		if (ch == ETX)
		    done = TRUE;
        else
        {
    		*str = ch;
	    	str++;
		    *str = 0;
    		FSize++;
        }
		    
	}

	if (!done)
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

	return TRUE;
}

/*##################  TWayneClProtocolAnalyser::ShowAddress ##########################
*   Purpose....: Show message address  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowAddress(char Adr)
{
	char str[30];

	FAdr = Adr;

	sprintf(str, " %02HX ", Adr);
	Write(str);
}

/*##################  TWayneClProtocolAnalyser::ShowLimit ##########################
*   Purpose....: Show CB0 limit field             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowLimit(const char *MsgData)
{
    char Str[10];
    int val;

    memcpy(&Str[1], MsgData, 5);
    Str[0] = '0';
    Str[6] = 0;
    
    if (Str[2] & 0x80)
        Str[0] |= 0x2;

    if (Str[2] & 0x40)
        Str[0] |= 0x1;

    if (Str[3] & 0x80)
        Str[0] |= 0x8;

    if (Str[3] & 0x40)
        Str[0] |= 0x4;

    Str[2] &= 0x3F;
    Str[3] &= 0x3F;

	if (sscanf(Str,"%06d", &val) == 1)
	{
	    sprintf(Str, "%d", val);
	    Write(Str);
	}
}

/*##################  TWayneClProtocolAnalyser::ShowCB0 ##########################
*   Purpose....: Show CB0             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowCB0(const char *MsgData)
{
    char Adr;
    char Mask;
    int bit;

    Write("CB0 ");

    Adr = MsgData[16];
    
    if (Adr != ' ')
    {
        Mask = MsgData[22];
        if (Mask & 0x20)
            Write("MAX VOLUME: ");
        else
            Write("MAX AMOUNT: ");
        ShowLimit(MsgData + 17);

        Write(", QUALS: ");
        for (bit = 0; bit < 5; bit++)
        {
            if (Mask & (1 << bit))
                Write("0");
            else
                Write("1");
        }
    }
    
    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowPrice ##########################
*   Purpose....: Show price             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowPrice(const char *MsgData)
{
    char Str[6];
    int val;

	memcpy(Str, MsgData, 4);
    Str[4] = 0;

	if (sscanf(Str,"%04d", &val) == 1)
	{
	    sprintf(Str, "%d", val);
	    Write(Str);
	}
}

/*##################  TWayneClProtocolAnalyser::ShowCB1 ##########################
*   Purpose....: Show CB1             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowCB1(const char *MsgData)
{
    Write("CB1 Price: ");

    ShowPrice(MsgData);
    Write(", ");

    ShowPrice(MsgData + 4);    
    Write(", ");
        
    ShowPrice(MsgData + 8);
    Write(", ");
    
    ShowPrice(MsgData + 12);
    Write(", ");
    
    ShowPrice(MsgData + 16);

    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowCB2 ##########################
*   Purpose....: Show CB2             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowCB2(const char *MsgData)
{
    Write("CB2 ");
    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowMode ##########################
*   Purpose....: Show dispenser mode / command 				      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowMode(char mode)
{
	char str[30];

    switch (mode)
    {
        case STATUS_RESET:
            Write("RESET");
            break;

        case STATUS_RESET_CALL:
            Write("RESET, CALL");
            break;

        case STATUS_AUTHORIZED:
            Write("AUTHORIZED");
            break;

        case STATUS_FILLING:
            Write("FILLING");
            break;

        case STATUS_COMPLETED:
            Write("COMPLETED");
            break;

        case STATUS_COMPLETED_CALL:
            Write("COMPLETED, CALL");
            break;

        case STATUS_MAX_AMOUNT:
            Write("MAX AMOUNT");
            break;

        default:
        	sprintf(str, "MODE:%02HX", mode);
        	Write(str);
        	break;
    }
}

/*##################  TWayneClProtocolAnalyser::ShowCB3 ##########################
*   Purpose....: Show CB3             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowCB3(const char *MsgData)
{
    char mode;
    char Mask;
    int bit;

    Write("CB3 ");

    if (FAdr >= 0x50 && FAdr < 0x60)
    {
        mode = *(MsgData + FAdr - 0x50);
        ShowMode(mode);
		Write(", ");
    }

    Write("GRADES: ");
    Mask = MsgData[16];
    for (bit = 0; bit < 5; bit++)
    {
        if (Mask & (1 << bit))
            Write("1");
        else
            Write("0");
    }
    
    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowDB0 ##########################
*   Purpose....: Show DB0             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowDB0(const char *MsgData)
{
    char Str[80];
    int Price;
    int Grade;
    int Volume;
    int Amount;
    char mode;
    char alarm;
    
    Write("DB0 ");

    mode = MsgData[17];
    ShowMode(mode);
    Write(", ");

    alarm = MsgData[18];
    
    if (alarm & 4)
        Write("DOUBLE PULSE ERROR, ");

    if (alarm & 8)
        Write("CURR PULSE ERROR, ");

    if (alarm & 0x10)
        Write("COMM ERROR, ");

    if (alarm & 0x20)
        Write("CPU RESET, ");
            
	if (sscanf( MsgData, "%04d%1d%06d%06d", 
	            &Price,
	            &Grade,
	            &Volume,
	            &Amount) == 4)
    {
        sprintf(Str, "PRICE: %d, GRADE: %d, VOLUME: %d, AMOUNT: %d",
                Price, Grade, Volume, Amount);
        Write(Str);
    }
    
    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowInvalidCode ##########################
*   Purpose....: Show invalid code             	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowInvalidCode(char MessCode, const char *MsgData)
{
	char str[30];

	sprintf(str, "MSG:%c ", MessCode);
	Write(str);
    Write(MsgData);
    Write("\r\n");
}

/*##################  TWayneClProtocolAnalyser::ShowReq ##########################
*   Purpose....: Show message code  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowReq(char Code, const char *MsgData)
{
	switch (Code)
	{
	    case '0':
	        ShowCB0(MsgData);
	        break;

	    case '1':
	        ShowCB1(MsgData);
	        break;

	    case '2':
	        ShowCB2(MsgData);
	        break;

	    case '3':
	        ShowCB3(MsgData);
	        break;

	    default:
	        ShowInvalidCode(Code, MsgData);
	        break;
	}
}

/*##################  TWayneClProtocolAnalyser::ShowReply ##########################
*   Purpose....: Show message code  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowReply(char Code, const char *MsgData)
{
	switch (Code)
	{
	    case '0':
	        ShowDB0(MsgData);
	        break;

	    default:
	        ShowInvalidCode(Code, MsgData);
	        break;
	}
}

/*##################  TWayneClProtocolAnalyser::ShowPumpMsg ##########################
*   Purpose....: Show wayne current loop pump msg	   		     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowPumpMsg(char ToAdr, char FromAdr, char MessCode, const char *MsgData)
{
    if (FTime)
        ShowLongTime(FTime);
        
	if (FromAdr == 0x71)
    {
        ShowAddress(ToAdr);
	    ShowReq(MessCode, MsgData);
    }

    if (ToAdr == 0x71)
    {
        ShowAddress(FromAdr);
        ShowReply(MessCode, MsgData);
    }
}

/*##################  TWayneClProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show current loop msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TWayneClProtocolAnalyser::ShowMsg()
{
	char ToAdr;
	char FromAdr;
	char MessCode;

	if (FSize == 30)
	{
	    ToAdr = FMsg[0];
	    FromAdr = FMsg[1];
        MessCode = FMsg[3];
        if (ToAdr == 0x71 || FromAdr == 0x71)
            ShowPumpMsg(ToAdr, FromAdr, MessCode, &FMsg[4]);
        else
            TProtocolAnalyser::ShowMsg();
	}
	else
	    TProtocolAnalyser::ShowMsg();
}
