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
# zap.cpp
# Zap protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "zap.h"

#define FALSE	0
#define TRUE	!FALSE

#define BEGIN_K         0x10
#define BEGIN_D         0x20
#define END             0x36

#define BLOCK_CMD       0x69
#define LINETEST_CMD    0x6A
#define PRICE_CMD       0x5C
#define PROG_I_CMD      0x70
#define PROG_W_CMD      0x75
#define PROG_PRC_CMD    0xA9
#define STATE_CMD       0x4B
#define STOP_CMD        0x2F
#define UNBLOCK_CMD     0x77
#define NR_CMD          0xC3
#define TANK_CMD        0xC5
#define VOLUME_CMD      0x45

#define OK_ANSW         0x1E
#define ERROR_ANSW      0x25

/*##################  IntToString4 ############################
*   Purpose....: Convert price to 4-byte string        		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void IntToString4(char *str, int val)
{
    char ch;
    
	sprintf(str, "%04d", val);

    ch = str[0];
    str[0] = str[3];
    str[3] = ch;
    ch = str[1];
    str[1] = str[2];
    str[2] = ch;
}

/*##################  LongToString5 ############################
*   Purpose....: Convert long to 5-byte string        		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void LongToString5(char *str, long val)
{
    char ch;
    
	sprintf(str, "%05ld", val);

    ch = str[0];
    str[0] = str[4];
    str[4] = ch;
    ch = str[1];
    str[1] = str[3];
    str[3] = ch;
}

/*##################  LongToString6 ############################
*   Purpose....: Convert long to 6-byte string        		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static void LongToString6(char *str, long val)
{
    char ch;
    
	sprintf(str, "%06ld", val);

    ch = str[0];
    str[0] = str[5];
    str[5] = ch;
    ch = str[1];
    str[1] = str[4];
    str[4] = ch;
    ch = str[2];
    str[2] = str[3];
    str[3] = ch;
}

/*##################  String4ToInt ############################
*   Purpose....: Convert 4-byte string to int        		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int String4ToInt(const char *str)
{
    char tempstr[5];
    
    tempstr[0] = str[3];
    tempstr[3] = str[0];
    tempstr[1] = str[2];
    tempstr[2] = str[1];
    tempstr[4] = 0;

    return atoi(tempstr);
}

/*##################  String5ToLong ############################
*   Purpose....: Convert 5-byte string to long        		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static long String5ToLong(const char *str)
{
    char tempstr[6];
    
    tempstr[0] = str[4];
    tempstr[4] = str[0];
    tempstr[1] = str[3];
    tempstr[3] = str[1];
    tempstr[2] = str[2];
    tempstr[5] = 0;

    return atol(tempstr);
}

/*##################  String6ToLong ############################
*   Purpose....: Convert 6-byte string to long       		          			#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static long String6ToLong(const char *str)
{
    char tempstr[7];

    tempstr[0] = str[5];
    tempstr[5] = str[0];
    tempstr[1] = str[4];
    tempstr[4] = str[1];
    tempstr[2] = str[3];
    tempstr[3] = str[2];
    tempstr[6] = 0;
    
	return atol(tempstr);
}

/*##################  TZapProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next Compac message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TZapProtocolAnalyser::GetMsg()
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
	int size;

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
		if (Elapsed > 1193 * 250)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		ch = Debug.ch;

        if (ch == BEGIN_K || ch == BEGIN_D)
            done = TRUE;

		LastTime = Debug.TimeLSB;
		FSize++;
	}

	if (!done)
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

	if (FRawFile->GetSize() > FRawFile->GetPos())
	{
		*str = ch;
		str++;
		*str = 0;

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
		if (Elapsed > 1193 * 250)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		ch = Debug.ch;

		size = ch;

		LastTime = Debug.TimeLSB;
		FSize++;
	}
	else
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

    done = FALSE;

	while (FRawFile->GetSize() > FRawFile->GetPos() && !done)
	{
		*str = ch;
		str++;
		*str = 0;

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

		FSize++;

		if (FSize == size)
		    done = TRUE;
	}

	if (!done)
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

	return TRUE;
}

/*##################  TZapProtocolAnalyser::ShowAddress ##########################
*   Purpose....: Show address       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowAddress(char Adr)
{
	char str[30];

    if (Adr == 0x20)
        Write(" * ");
    else
    {
    	sprintf(str, " %d ", Adr - 0x21);
	    Write(str);
	}
}

/*##################  TZapProtocolAnalyser::ShowType ##########################
*   Purpose....: Show msg type	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowType(char typ)
{
	char str[40];
	unsigned char uch = (unsigned char)typ;

	switch (uch)
	{
		case BLOCK_CMD:
			Write("BLOCK");
			break;

		case LINETEST_CMD:
			Write("LINETEST");
			break;

		case PRICE_CMD:
			Write("PRICE");
			break;

		case PROG_I_CMD:
			Write("PROG_I_CMD");
			break;

		case PROG_W_CMD:
			Write("PROG_W_CMD");
			break;

		case PROG_PRC_CMD:
			Write("PROG_PRC_CMD");
			break;

		case STATE_CMD:
			Write("STATE");
			break;

		case STOP_CMD:
			Write("STOP");
			break;

		case UNBLOCK_CMD:
			Write("UNBLOCK");
			break;

		case NR_CMD:
			Write("NR");
			break;

		case TANK_CMD:
			Write("TANK");
			break;

		case VOLUME_CMD:
			Write("VOLUME");
			break;

		case OK_ANSW:
			Write("OK");
			break;

		case ERROR_ANSW:
			Write("ERROR");
			break;

		default:
			sprintf(str, "UNKNOWN (%ud)", uch);
			Write(str);
			break;
	}
}

/*##################  TZapProtocolAnalyser::ShowState ##########################
*   Purpose....: Show dispenser state	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowState(const char *str)
{
    int Nozzle = 0;
	char tempstr[10];

	if (*str & 1)
		Nozzle++;

	if (*str & 2)
		Write(" BUSY, ");
	else
		Write(" FREE, ");


	if (*str & 4)
		Write("LIFTED, ");

	if (*str & 8)
		Write("AUTO, ");
	else
		Write("MANUAL, ");

	if (*str & 0x80)
		Nozzle += 2;

	sprintf(tempstr, "NOZZLE: %d", Nozzle + 1);
	Write(tempstr);

	switch (*str & 0x60)
	{
		case 0:
			Write(" FATAL ERROR");
            break;

        case 0x20:
            Write(" ERROR");
            break;
    }   
}

/*##################  TZapProtocolAnalyser::ShowReqMsg ##########################
*   Purpose....: Show msg part	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowReqMsg()
{
	unsigned char utype = (unsigned char)FZapReqMsg->Type;
	int intval;
	long longval;
	char tempstr[10];

	ShowType(FZapReqMsg->Type);

	switch (utype)
	{
	    case NR_CMD:
	        Write(": ");
	        Write(FZapReqMsg->MsgData);
	        break;

        case PROG_PRC_CMD:
            intval = String4ToInt(FZapReqMsg->MsgData);
            sprintf(tempstr, ": %d", intval);
            Write(tempstr);
            break;

        case PROG_I_CMD:
        case PROG_W_CMD:
            longval = String5ToLong(FZapReqMsg->MsgData);
            sprintf(tempstr, ": %ld", longval);
            Write(tempstr);
            break;
    }            	    
}

/*##################  TZapProtocolAnalyser::ShowReplyMsg ##########################
*   Purpose....: Show msg part	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowReplyMsg()
{
	long longval;
    char tempstr[10];
	unsigned char utype = (unsigned char)FZapReplyMsg->Type;

	if (FZapReqMsg == 0 || FZapReqMsg->Type != FZapReplyMsg->Type)
	{
		Write(", ");
		ShowType(FZapReplyMsg->Type);
	}

	switch (utype)
	{
		case STATE_CMD:
		    ShowState(FZapReplyMsg->MsgData);
        	break;

        case VOLUME_CMD:
            if (strlen(FZapReplyMsg->MsgData) == 5)
                longval = String5ToLong(FZapReplyMsg->MsgData);
            else
                longval = String6ToLong(FZapReplyMsg->MsgData);

            sprintf(tempstr, ": %ld", longval);
            Write(tempstr);
            break;
	}
}

/*##################  TZapProtocolAnalyser::UpdatePump ##########################
*   Purpose....: Update pump        	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::UpdatePump()
{
	if (FZapReqMsg || FZapReplyMsg)
	{
		ShowLongTime(FTime);

		if (FZapReqMsg)
		{
			ShowAddress(FZapReqMsg->Adr);
			ShowReqMsg();
		}
		else
			Write("*** NO REQ ***");

		if (FZapReplyMsg)
		{
			if (FZapReqMsg == 0)
				ShowAddress(FZapReplyMsg->Adr);

			ShowReplyMsg();
		}
		else
			Write("*** NO ANSWER ***");

		Write("\r\n");
    	
		if (FZapReqMsg)
		{
			delete FZapReqMsg;
			FZapReqMsg = 0;
		}

		if (FZapReplyMsg)
		{
			delete FZapReplyMsg;
			FZapReplyMsg = 0;
		}
    }
}

/*##################  TZapProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TZapProtocolAnalyser::ShowMsg()
{
    char Crc;
    int i;
    TZapMsg *msg;

    Crc = 0;
    
    for (i = 0; i < FSize - 1; i++)
		Crc = Crc ^ FMsg[i];

    if (Crc)
    {
    	ShowLongTime(FTime);
	    ShowHexMsg();
        UpdatePump();
        Write("Wrong CRC");
    }
    else
    {
        if (FSize >= 6 && FMsg[1] == FSize)
        {
            msg = new TZapMsg;
            msg->Adr = FMsg[2];
            msg->Type = FMsg[3];
            memcpy(msg->MsgData, &FMsg[4], FSize - 6);
            msg->MsgData[FSize - 6] = 0;
                        
            switch (FMsg[0])
            {
                case BEGIN_K:
                    if (FZapReqMsg)
                        UpdatePump();
                    FZapReqMsg = msg;
                    break;

                case BEGIN_D:
                    if (FZapReplyMsg)
                        UpdatePump();
                    FZapReplyMsg = msg;
                    UpdatePump();
                    break;
            }
        }
        else
        {
        	ShowLongTime(FTime);
        	ShowHexMsg();
            UpdatePump();
            Write("Wrong size");
        }
    }
}

/*##################  TZapProtocolAnalyser::TZapProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TZapProtocolAnalyser::TZapProtocolAnalyser(TFile *RawFile)
  : TProtocolAnalyser(RawFile, 0x100)
{
	FZapReqMsg = 0;
	FZapReplyMsg = 0;
}

/*##################  TZapProtocolAnalyser::~TZapProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TZapProtocolAnalyser::~TZapProtocolAnalyser()
{
	if (FZapReqMsg)
        delete FZapReqMsg;

    if (FZapReplyMsg)
        delete FZapReplyMsg;
}
