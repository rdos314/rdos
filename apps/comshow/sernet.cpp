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

struct TIpHeader
{
    char HdrVer;
    char Tos;
    short int Size;
    short int Id;
    short int Frags;
    char Ttl;
    char Protocol;
    short int Checksum;
    unsigned char Source[4];
    unsigned char Dest[4];
};


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

/*##################  TSernetProtocolAnalyser::ShowIpData ##########################
*   Purpose....: Show IP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowIpData(unsigned char Protocol, const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;

	sprintf(tempstr, "%d: ", Protocol);
	Write(tempstr);

	for (i = 0; i < Size; i++)
	{
		ch = *Msg;
		sprintf(tempstr, "%04hX", ch);
		tempstr[0] = tempstr[2];
		tempstr[1] = tempstr[3];
		tempstr[2] = ' ';
		tempstr[3] = 0;
		Write(tempstr);
		Msg++;
	}
	Write("\r\n");

}

/*##################  TSernetProtocolAnalyser::ShowSmp ##########################
*   Purpose....: Show SMP message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowSmp(const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;

	Write("SMP: ");

	for (i = 0; i < Size; i++)
	{
		ch = *Msg;
		sprintf(tempstr, "%04hX", ch);
		tempstr[0] = tempstr[2];
		tempstr[1] = tempstr[3];
		tempstr[2] = ' ';
		tempstr[3] = 0;
		Write(tempstr);
		Msg++;
	}
	Write("\r\n");

}

/*##################  TSernetProtocolAnalyser::ShowArp ##########################
*   Purpose....: Show ARP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowArp(const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;

	Write("ARP: ");

	for (i = 0; i < Size; i++)
	{
		ch = *Msg;
		sprintf(tempstr, "%04hX", ch);
		tempstr[0] = tempstr[2];
		tempstr[1] = tempstr[3];
		tempstr[2] = ' ';
		tempstr[3] = 0;
		Write(tempstr);
		Msg++;
	}
	Write("\r\n");

}

/*##################  TSernetProtocolAnalyser::ShowIp ##########################
*   Purpose....: Show IP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowIp(const char *Msg, int Size)
{
	char str[80];
	TIpHeader *IpHeader = (TIpHeader *)Msg;

    Msg += sizeof(TIpHeader);
    Size -= sizeof(TIpHeader);

    sprintf(str, "%d.%d.%d.%d->",
                IpHeader->Source[0],
                IpHeader->Source[1],
                IpHeader->Source[2],
                IpHeader->Source[3]);

    Write(str);

    sprintf(str, "%d.%d.%d.%d ",
                IpHeader->Dest[0],
                IpHeader->Dest[1],
                IpHeader->Dest[2],
                IpHeader->Dest[3]);

    Write(str);

    switch (IpHeader->Protocol)
    {
        case 121:
            ShowSmp(Msg, Size);
            break;

        default:
            ShowIpData(IpHeader->Protocol, Msg, Size);
            break;
    }
}

/*##################  TSernetProtocolAnalyser::ShowUnknown ##########################
*   Purpose....: Show unknown data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TSernetProtocolAnalyser::ShowUnknown(int DataType, const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;

	sprintf(tempstr, "Data %04hX: ", DataType);
	Write(tempstr);

	for (i = 0; i < Size; i++)
	{
		ch = *Msg;
		sprintf(tempstr, "%04hX", ch);
		tempstr[0] = tempstr[2];
		tempstr[1] = tempstr[3];
		tempstr[2] = ' ';
		tempstr[3] = 0;
		Write(tempstr);
		Msg++;
	}
	Write("\r\n");
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

	sprintf(str, "%02d Init\r\n", Source);
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

	sprintf(str, "%02d Request\r\n", Source);
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

	sprintf(str, "%02d Reply\r\n", Source);
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
	int DataSize;
	int DataType;

	Source = *Msg - 0x2C;
	Msg++;
	Size--;

	Dest = (unsigned char)*Msg - (unsigned char)0xAC;
	Msg++;
	Size--;

	DataSize = (unsigned char)*Msg << 8;
	Msg++;
	Size--;

	DataSize |= (unsigned char)*Msg;
	Msg++;
	Size--;

	DataType = (unsigned char)*Msg << 8;
	Msg++;
	Size--;

	DataType |= (unsigned char)*Msg;
	Msg++;
	Size--;

    if (Size < DataSize)
        DataSize = Size;

    if (Dest >= 0)
        sprintf(str, "%02d->%02d ", Source, Dest);
	else
    	sprintf(str, "%02d->All ", Source);
	Write(str);

    switch (DataType)
    {
	    case 0x800:
		    ShowIp(Msg, DataSize);
			break;

    	case 0x806:
	    	ShowArp(Msg, DataSize);
            break;

        default:
            ShowUnknown(DataType, Msg, DataSize);
            break;
            
    }	
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
