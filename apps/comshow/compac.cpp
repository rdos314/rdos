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
# compac.cpp
# Compac protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "compac.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TCompacProtocolAnalyser::CalcLrc ##########################
*   Purpose....: Calculate LRC	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
char TCompacProtocolAnalyser::CalcLrc(const char *str, int size)
{
	int i;
    char sum = 0;

    for (i = 0; i < size; i++)
        sum += str[i];

	sum = ~sum;
    sum &= 0x3F;
    sum += 0x30;     

    return sum;        
}

/*##################  TCompacProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next Compac message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TCompacProtocolAnalyser::GetMsg()
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

        if (ch == '*')
            done = TRUE;

		LastTime = Debug.TimeLSB;
		FSize++;
	}

	if (!done)
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

		if (ch == '\r')
		    done = TRUE;

		FSize++;
	}

	if (!done)
	{
	    FRawFile->SetPos(StartPos);
	    return FALSE;
	}

	return TRUE;
}

/*##################  TCompacProtocolAnalyser::ShowPump ##########################
*   Purpose....: Show Pump	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowPump(int Pump)
{
	char str[30];

	sprintf(str, " %d ", Pump);
	Write(str);
}

/*##################  TCompacProtocolAnalyser::ShowPrePay ##########################
*   Purpose....: Show Prepay	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowPrePay(int PrePay)
{
    if (PrePay)
		Write("PREPAY  ");
	else
		Write("POSTPAY ");
}

/*##################  TCompacProtocolAnalyser::ShowLockout ##########################
*   Purpose....: Show Lockout	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowLockout(char Lockout)
{
	char str[80];

	switch (Lockout)
	{
		case '1':
			Write("RELEASE ONE ");
			break;

		case '3':
			Write("ABORT IM ");
			break;

		case '4':
			Write("TEMP STOP ");
			break;

		case '5':
			Write("CLEAR TEMP STOP ");
			break;

		case '6':
			Write("CLEAR END DELIVERY ");
			break;

		case '7':
			Write("ALLOW PRICE CHANGE ");
			break;

		case '8':
			Write("ALLOW PRICE IM ");
			break;

		case '9':
			Write("CLEAR STARTUP ");
			break;

		default:
			sprintf(str, "INVALID LOCKOUT (%c)", Lockout);
			Write(str);
			break;
	}
}

/*##################  TCompacProtocolAnalyser::ShowPollType ##########################
*   Purpose....: Show Polltype	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowPollType(char PollType)
{
	char str[80];

	switch (PollType)
	{
		case 'X':
			Write("CMD ONLY ");
			break;

		case 'Q':
			Write("REPORT REQ ");
			break;

		case '$':
			Write("PRESET AMOUNT ");
			break;

		case 'D':
			Write("REQ DELIVERY QUAL & AMOUNT ");
			break;

		case 'G':
			Write("REMOTE PRICES ");
			break;

		case 'C':
			Write("REQ DELIVERY PRICE ");
			break;

		case 'T':
			Write("REQ DELIVERY TOTALS ");
			break;

		case 'P':
			Write("SET REMOTE PRICE ");
			break;

		case 'A':
			Write("ALLOW GRADES ");
			break;

		case 'U':
			Write("GET REMOTE PRICE ");
			break;

		case 'F':
			Write("SET FLOOR LIMITS ");
			break;

		case 'I':
			Write("ILLUMINATION ");
			break;

		case 'R':
			Write("REQ TOTALS ");
			break;

		default:
			sprintf(str, "INVALID POLL-TYPE (%c)", PollType);
			Write(str);
			break;
	}
}

/*##################  TCompacProtocolAnalyser::ShowNozzle ##########################
*   Purpose....: Show Nozzle	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowNozzle(char Nozzle)
{
	int val;
	int PumpIdle;
	int NozzleStowed;
	int DisplayZero;
	int HoseNumber;
	int Cash;
	char str[10];

	if (Nozzle >= 0x3B)
	{
		val = (signed int)Nozzle - 0x3B;
		PumpIdle = val & 1;
		NozzleStowed = val & 2;
		DisplayZero = val & 4;
		HoseNumber = (3 - ((val & 0x18) >> 3)) & 3;
		Cash = val & 0x20;

		if (Cash)
			Write("CASH ");

		sprintf(str, "NOZZLE: %d ", HoseNumber);
		Write(str);

		if (DisplayZero)
			Write("DISLAY ZERO ");

		if (NozzleStowed)
			Write("NOZZLE STOWED ");

		if (PumpIdle)
			Write("IDLE ");
		else
			Write("BUSY ");
	}
	else
		Write("INVALID NOZZLE ");
}

/*##################  TCompacProtocolAnalyser::ShowStatus ##########################
*   Purpose....: Show Status	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowStatus(char Status)
{
	char str[80];

	switch (Status)
	{
		case '0':
			Write("HOLD ");
			break;

		case '1':
			Write("IDLE, AUTHORIZED ");
			break;

		case '2':
			Write("PRE DELIVERY ");
			break;

		case '3':
			Write("DELIVERY ");
			break;

		case '4':
			Write("SLOW FLOW ");
			break;

		case '5':
			Write("SHUTTING DOWN, PRESET ");
			break;

		case '6':
			Write("SHUTTING DOWN, NOZZLE IN ");
			break;

		case '7':
			Write("ZERO DELIVERY ");
			break;

		case '8':
			Write("END OF DELIVERY, SHORT PREPAY ");
			break;

		case '9':
			Write("PRICE CHANGE, TIMEOUT ");
			break;

		case ':':
			Write("END OF DELIVERY ");
			break;

		case '?':
			Write("POWER ON ");
			break;

		default:
			sprintf(str, "INVALID STATUS (%c)", Status);
			Write(str);
			break;
	}
}

/*##################  TCompacProtocolAnalyser::ShowFID ##########################
*   Purpose....: Show a single FID  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
const char *TCompacProtocolAnalyser::ShowFID(const char *str)
{
	char *ptr;
	char buf[20];

	switch (*str)
	{
		case '$':
			Write("PREPAY AMOUNT:");
			break;

		case 'D':
			Write("DELIVERY AMOUNT:");
			break;

		case 'L':
			Write("DELIVERY QUANTITY:");
			break;

		case 'K':
			Write("PRESET AMOUNT:");
			break;

		case 'C':
			Write("DISPENSER PRICE:");
			break;

		case 'G':
			Write("MICRO-M PRICE:");
			break;

		case 'H':
			Write("HOSE NO:");
			break;

		case 'A':
			Write("PRODUCT ALLOWED:");
			break;

		case 'F':
			Write("ALLOCATION FLOOR:");
			break;

		case 'I':
			Write("ILLUM:");
			break;

		case 'M':
			Write("TOTAL MONEY:");
			break;

		case 'Q':
			Write("TOTAL QUANTITY:");
			break;

		case 'N':
			Write("# OF DELIVERIES:");
			break;

		default:
			Write("UNKNOWN FID");
			return 0;

	}

	buf[1] = 0;

	ptr = (char *)str;

	ptr++;

	while (isdigit(*ptr))
		ptr++;

	if (*ptr == '%')
	{
		ptr = buf;
		str++;

		while (isdigit(*str))
		{
			*ptr = *str;
			str++;
			ptr++;
		}
		*ptr = 0;

	}
	else
	{
		ptr--;
		buf[0] = *ptr;
		ptr = buf;
		ptr++;
		str++;

		while (isdigit(*str))
		{
			*ptr = *str;
			str++;
			ptr++;
		}

		ptr--;
		*ptr = 0;
	}

	if (*str == '%')
		str++;

	Write(buf);
	Write(" ");

	if (*str)
		return str;
	else
		return 0;
}

/*##################  TCompacProtocolAnalyser::ShowMasterMsg ##########################
*   Purpose....: Show master message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowMasterMsg(int Pump, int PrePay, char Lockout, char PollType, const char *MsgData)
{
	const char *str;

	ShowLongTime(FTime);
	ShowPump(Pump);
	ShowPrePay(PrePay);
	ShowLockout(Lockout);
	ShowPollType(PollType);

	str = MsgData;
	if (*str)
		while (str)
			str = ShowFID(str);

	Write("\r\n");
}

/*##################  TCompacProtocolAnalyser::ShowSlaveMsg ##########################
*   Purpose....: Show slave message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowSlaveMsg(int Pump, int PrePay, char Nozzle, char Status, char Lockout, const char *MsgData)
{
	const char *str;

	ShowLongTime(FTime);
	ShowPump(Pump);
	ShowPrePay(PrePay);
	ShowNozzle(Nozzle);
	ShowStatus(Status);
	ShowLockout(Lockout);

	str = MsgData;
	if (*str)
		while (str)
			str = ShowFID(str);

	Write("\r\n");
}

/*##################  TCompacProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCompacProtocolAnalyser::ShowMsg()
{
	char MsgData[256];
	int MsgLen;
	char *str;
	char lrc;
	int ok;
	int master;
	int pump;
	int prepay;
	char lockout;
	char polltype;
	char nozzle;
	char status;

    MsgLen = strlen(FMsg);
	str = FMsg;

	ShowLongTime(FTime);
	ShowHexMsg();

	if (MsgLen >= 7)
	{

		lrc = CalcLrc(str+2, MsgLen-3);

		if (lrc == *(str+MsgLen-1))
			ok = TRUE;
		else
		{
			ShowLongTime(FTime);
			ShowHexMsg();
			ok = FALSE;
		}

		if (ok)
		{
			switch (*(str+1))
			{
				case 'T':
					master = TRUE;
					ok = TRUE;
					break;

				case 'F':
					master = FALSE;
					ok = TRUE;
					break;

				default:
					ok = FALSE;
					break;
			}
		}

		if (ok)
		{
			switch (*(str+2))
			{
				case '1':
				case '2':
				case '3':
				case '4':
				case '5':
				case '6':
				case '7':
				case '8':
				case '9':
				case ':':
				case ';':
				case '<':
				case '=':
				case '>':
				case '?':
				case '@':
					pump = *(str+2) - '0';
					ok = TRUE;
					break;

				case '!':
					pump = 0;
					ok = TRUE;
					break;

				default:
					ok = FALSE;
					break;
			}
		}

		if (ok && master)
		{
			switch (*(str+3))
			{
				case 'A':
					prepay = FALSE;
					ok = TRUE;
					break;

				case 'H':
					prepay = TRUE;
					ok = TRUE;
					break;

				default:
					ok = FALSE;
					break;
			}

			if (ok)
			{
				lockout = *(str+4);
				polltype = *(str+5);

				MsgLen -= 7;
				memcpy(MsgData, str+6, MsgLen);
				MsgData[MsgLen] = 0;
				ShowMasterMsg(pump, prepay, lockout, polltype, MsgData);
			}
		}

		if (ok && !master)
		{
			switch (*(str+5))
			{
				case 'A':
					prepay = FALSE;
					ok = TRUE;
					break;

				case 'H':
					prepay = TRUE;
					ok = TRUE;
					break;

				default:
					ok = FALSE;
					break;
			}

			if (ok)
			{
				nozzle = *(str+3);
				status = *(str+4);
				lockout = *(str+5);

				MsgLen -= 8;
				memcpy(MsgData, str+7, MsgLen);
				MsgData[MsgLen] = 0;
				ShowSlaveMsg(pump, prepay, nozzle, status, lockout, MsgData);
			}
		}

	}
}

/*##################  TCompacProtocolAnalyser::TCompacProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCompacProtocolAnalyser::TCompacProtocolAnalyser(TFile *RawFile, int MaxSize)
  : TProtocolAnalyser(RawFile, MaxSize)
{
	FCompacReqMsg = 0;
	FCompacReplyMsg = 0;
}

/*##################  TCompacProtocolAnalyser::~TCompacProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCompacProtocolAnalyser::~TCompacProtocolAnalyser()
{
	if (FCompacReqMsg)
        delete FCompacReqMsg;

    if (FCompacReplyMsg)
        delete FCompacReplyMsg;
}
