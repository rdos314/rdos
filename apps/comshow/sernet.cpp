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
# sernet.cpp
# SERNET protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "sernet.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TSernetProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next CBUS message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSernetProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int count;
	int Size;
	TComMsg *CurrMsg = FComMsg;

	count = *FRawCount - FRawPos;

	if (count == 0)
		return FALSE;

	if (FTime)
		delete FTime;

	FTime = new TDateTime(CurrMsg->TimeMSB, FComMsg->TimeLSB);

	str = FMsg;
	*str = 0;
	Size = 0;

	Channel = CurrMsg->Channel;
	LastTime = CurrMsg->TimeLSB;
	ch = CurrMsg->ch;
	Size++;
	CurrMsg++;

	while (count > Size && ch != (char)0x9B)
	{
		if (Channel != CurrMsg->Channel)
		{
			FComMsg = CurrMsg;
			FSize = Size;
			FRawPos += Size;
			return TRUE;
		}
		LastTime = CurrMsg->TimeLSB;
		ch = CurrMsg->ch;
		Size++;
		CurrMsg++;
	}

	if (Size > 1)
	{
		FComMsg = CurrMsg - 1;
		FSize = Size - 1;
		FRawPos += Size - 1;
		return TRUE;
	}

	while (count > Size)
	{
		*str = ch;
		str++;
		*str = 0;

		if (Channel != CurrMsg->Channel)
		{
			FComMsg = CurrMsg;
			FSize = Size;
			FRawPos += Size;
			return TRUE;
		}

		Elapsed = CurrMsg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
		{
			FComMsg = CurrMsg;
			FSize = Size;
			FRawPos += Size;
			return TRUE;
		}

		LastTime = CurrMsg->TimeLSB;
		ch = CurrMsg->ch;
		Size++;
		CurrMsg++;
	}

	return FALSE;
}

/*##################  TSernetProtocolAnalyser::ShowInitMsg ##########################
*   Purpose....: Show init message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowInitMsg(const char *Msg, int Size)
{
	int Source = *Msg - 0x2C;
	char str[40];

	sprintf(str, "Init %d\r\n", Source);
	Write(str);
}

/*##################  TSernetProtocolAnalyser::ShowReqMsg ##########################
*   Purpose....: Show req message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowReqMsg(const char *Msg, int Size)
{
	int Source = *Msg - 0x2C;
	char str[40];

	sprintf(str, "Request %d\r\n", Source);
	Write(str);
}

/*##################  TSernetProtocolAnalyser::ShowReplyMsg ##########################
*   Purpose....: Show reply message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowReplyMsg(const char *Msg, int Size)
{
	int Source = *Msg - 0x2C;
	char str[40];

	sprintf(str, "Reply %d\r\n", Source);
	Write(str);
}

/*##################  TSernetProtocolAnalyser::ShowDataMsg ##########################
*   Purpose....: Show data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowDataMsg(const char *Msg, int Size)
{
	int Source;
	int Dest;
	char str[40];

	Source = *Msg - 0x2C;
	Msg++;
	Size--;

	Dest = *Msg - 0xAC;

	sprintf(str, "Data %d->%d\r\n", Source, Dest);
	Write(str);
}

/*##################  TSernetProtocolAnalyser::CheckCrc ##########################
*   Purpose....: Check CRC	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TSernetProtocolAnalyser::CheckCrc()
{
	int crc;
	int ind;
	int i;
	char *Msg = FMsg;

	crc = 0;
	for (i = 0; i < FSize - 2; i++)
	{
		ind = crc >> 8;
		ind = ind ^ *Msg;
		ind = ind & 0xFF;
		ind = FCrcTable[ind];
		crc = ind ^ (crc << 8);
		Msg++;
	}

	if (((crc >> 8) & 0xFF) != ((*Msg) & 0xFF))
		return FALSE;

	Msg++;

	if ((crc & 0xFF) == ((*Msg) & 0xFF))
		return TRUE;
	else
		return FALSE;
}

/*##################  TSernetProtocolAnalyser::ShowAll ##########################
*   Purpose....: Show all message types	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowAll(const char *Msg, int Size)
{
	switch (*Msg)
	{
		case 0x7C:
			ShowInitMsg(Msg + 1, Size - 1);
			break;

		case 0x7D:
			ShowReqMsg(Msg + 1, Size - 1);
			break;

		case 0x7E:
			ShowReplyMsg(Msg + 1, Size - 1);
			break;

		case 0x7F:
			ShowDataMsg(Msg + 1, Size - 1);
			break;

		default:
			ShowHexMsg();
			break;
	}
}

/*##################  TSernetProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowMsg()
{
	char *str;

    str = FMsg;

	ShowLongTime(FTime);

	if (CheckCrc())
	{
		if (FSize > 4 && *str == (char)0x9B)
			ShowAll(str + 1, FSize - 1);
		else
			ShowHexMsg();
	}
	else
		ShowHexMsg();
}

/*##################  TSernetProtocolAnalyser::TSernetProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSernetProtocolAnalyser::TSernetProtocolAnalyser(const char *MemMapName, int MaxSize)
  : TProtocolAnalyser(MemMapName, MaxSize)
{
	int i, j;
    int val;
	int acc;

    for (i = 0; i < 256; i++)
    {
        acc = 0;
        val = i << 8;
        for (j = 8; j; j--)
        {
			if (((val ^ acc) & 0x8000) == 0)
				acc = acc << 1;
			else
				acc = (acc << 1) ^ 0x1021;
			val = val << 1;
		}
        FCrcTable[i] = acc;
    }
}

/*##################  TSernetProtocolAnalyser::~TSernetProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TSernetProtocolAnalyser::~TSernetProtocolAnalyser()
{
}
