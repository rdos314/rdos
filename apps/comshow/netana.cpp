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
# netana.cpp
# Network protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "netana.h"

#define FALSE	0
#define TRUE	!FALSE

#define LT_READ		1
#define LT_WRITE	2

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

struct TArp
{
	short int Class;
	short int Type;
	unsigned char HwLen;
	unsigned char ProtLen;
	short int Op;
	unsigned char NetAdr1[6];
	unsigned char Ip1[4];
	unsigned char NetAdr2[6];
	unsigned char Ip2[4];
};

#define SOM		1
#define EOM		2
#define REQ		4
#define RPY		8
#define NAM		0x10

struct TSmpHeader
{
	long Connection;
	long OffsetSize;
	short int Mailslot;
	short int Size;
	unsigned char Flags;
	unsigned char Responses;
	short int Checksum;
};

#define ACTION_RESET		1
#define ACTION_ACK			2
#define ACTION_TOO_LARGE	3
#define ACTION_BUSY			4

struct TSmpResponse
{
	long Connection;
	short int Mailslot;
	char Size;
	char Action;
};

/*##################  SwapLong ##########################
*   Purpose....: Swap long	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static long SwapLong(long Val)
{
	_asm
	{
		mov eax,Val
		xchg al,ah
		ror eax,16
		xchg al,ah
	}
}

/*##################  SwapShort ##########################
*   Purpose....: Swap short	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static short int SwapShort(short int Val)
{
	_asm
	{
		mov ax,Val
		xchg al,ah
	}
}

/*##################  TNetProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next net message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TNetProtocolAnalyser::GetMsg()
{
	long StartPos;

    if (FRawFile->GetSize() - FRawFile->GetPos() < sizeof(TLogHeader))
        return FALSE;

	StartPos = FRawFile->GetPos();

	FRawFile->Read(&FHdr, sizeof(TLogHeader));

	if (FRawFile->GetSize() - FRawFile->GetPos() < FHdr.Size)
	{
		FRawFile->SetPos(StartPos);
		return FALSE;
	}

	if (FTime)
		delete FTime;
	FTime = 0;

    FTime = new TDateTime(FHdr.MsbTime, FHdr.LsbTime);
	FSize = FHdr.Size;
	FRawFile->Read(FMsg, FSize);

	return TRUE;
}

/*##################  TNetProtocolAnalyser::ShowIpData ##########################
*   Purpose....: Show IP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowIpData(unsigned char Protocol, const char *Msg, int Size)
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

/*##################  TNetProtocolAnalyser::ShowSmp ##########################
*   Purpose....: Show SMP message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowSmp(const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;
	TSmpHeader *Smp;
	TSmpResponse *Response;
	int MsgSize;
    int Responses;
	int Nam;
	int Req;
	int Reply;
	int RespSize;

	Write("SMP: ");

	if (Size >= sizeof(TSmpHeader))
	{
		Smp = (TSmpHeader *)Msg;

		if (Smp->Flags & NAM)
			Nam = TRUE;
		else
			Nam = FALSE;

		if (Smp->Flags & REQ)
			Req = TRUE;
		else
			Req = FALSE;

		if (Smp->Flags & RPY)
			Reply = TRUE;
		else
			Reply = FALSE;

		if ((Req && !Nam) || Reply)
		{
			sprintf(tempstr, "Conn = %08lX, ", SwapLong(Smp->Connection));
			Write(tempstr);
		}

		if (Nam && Reply)
		{
			sprintf(tempstr, "Maxsize = %ld, ", SwapLong(Smp->OffsetSize));
			Write(tempstr);	
		}

		if (!Nam && (Req || Reply))
		{
			sprintf(tempstr, "Size = %0ld, ", SwapLong(Smp->OffsetSize));
			Write(tempstr);	
		}

		if ((Req && !Nam) || Reply)
		{
			sprintf(tempstr, "Slot = %04hX", SwapShort(Smp->Mailslot));
			Write(tempstr);
		}

		if (Nam)
		{
			if (Req)
				Write("NAM");
			else
				Write(", NAM");
		}

		if (Req)
			Write(", REQ");

		if (Reply)
			Write(", RPY");

		if (Smp->Flags & SOM)
			Write(", SOM");

		if (Smp->Flags & EOM)
			Write(", EOM");

		MsgSize = SwapShort(Smp->Size);
		Responses = Smp->Responses;

		Msg += sizeof(TSmpHeader);

		for (i = 0; i < Responses; i++)
		{
			Write(", (");

			Response = (TSmpResponse *)Msg;

			switch (Response->Action)
			{
				case ACTION_RESET:
					Write("Reset ");
					break;

				case ACTION_ACK:
					Write("Ack ");
					break;

				case ACTION_TOO_LARGE:
					Write("Too large ");
					break;

				case ACTION_BUSY:
					Write("Busy ");
					break;

				default:
					Write(" Illegal action ");
					break;
			}
			sprintf(tempstr, "Conn = %08lX, ", SwapLong(Response->Connection));
			Write(tempstr);

			sprintf(tempstr, "Slot = %04hX", SwapShort(Response->Mailslot));
			Write(tempstr);

			RespSize = Response->Size;
			Msg += sizeof(TSmpResponse);

			Write(" ");
			for (i = 0; i < RespSize; i++)
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

			Write(")");
		}

		if (Nam)
		{
			if (Req)
			{
				Write(" Name: <");
				Write(Msg);
				Write(">");
			}
			else
			{
				sprintf(tempstr, " Max connections = %d", SwapShort(*(short int *)Msg));
				Write(tempstr);

				Msg += 2;
				Write(" Name: <");
				Write(Msg);
				Write(">");
			}
		}
		else
		{
			Write(" ");
			for (i = sizeof(TSmpHeader); i < MsgSize; i++)
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
		}

	}
	else
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

/*##################  TNetProtocolAnalyser::ShowNetAddress ##########################
*   Purpose....: Show network address		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowNetAddress(const char *Msg)
{
	int i;
	char str[8];

	for (i = 0; i < 6; i++)
	{
		sprintf(str, "%04hX", *Msg);
		str[0] = str[2];
		str[1] = str[3];
		str[2] = 0;
		Write(str); 
		if (i != 5)
			Write("-");
		Msg++;
	}
}

/*##################  TNetProtocolAnalyser::ShowArp ##########################
*   Purpose....: Show ARP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowArp(const char *Msg, int Size)
{
	char tempstr[100];
	char ch;
	int i;
	TArp *Arp;
	short int Val;

	Write("ARP: ");

	if (Size >= sizeof(TArp))
	{
		Arp = (TArp *)Msg;

		Write("Class = ");
		sprintf(tempstr, "%04hX", Arp->Class);
		ch = tempstr[0];
		tempstr[0] = tempstr[2];
		tempstr[2] = ch;
		ch = tempstr[1];
		tempstr[1] = tempstr[3];
		tempstr[3] = ch;
		Write(tempstr);
		Write(", ");

		Write("Type = ");
		sprintf(tempstr, "%04hX", Arp->Type);
		ch = tempstr[0];
		tempstr[0] = tempstr[2];
		tempstr[2] = ch;
		ch = tempstr[1];
		tempstr[1] = tempstr[3];
		tempstr[3] = ch;
		Write(tempstr);
		Write(", ");

		Write("Op = ");
		sprintf(tempstr, "%04hX", Arp->Op);
		ch = tempstr[0];
		tempstr[0] = tempstr[2];
		tempstr[2] = ch;
		ch = tempstr[1];
		tempstr[1] = tempstr[3];
		tempstr[3] = ch;
		Write(tempstr);
		Write("\r\n");

		sprintf(tempstr, "%d.%d.%d.%d",
					Arp->Ip1[0],
					Arp->Ip1[1],
					Arp->Ip1[2],
					Arp->Ip1[3]);

		Write(tempstr);
		Write(" = ");

		ShowNetAddress(Arp->NetAdr1);

		Write("\r\n");

		sprintf(tempstr, "%d.%d.%d.%d",
					Arp->Ip2[0],
					Arp->Ip2[1],
					Arp->Ip2[2],
					Arp->Ip2[3]);

		Write(tempstr);
		Write(" = ");

		ShowNetAddress(Arp->NetAdr2);

	}
	else
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

/*##################  TNetProtocolAnalyser::ShowIcmp ##########################
*   Purpose....: Show ICMP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowIcmp(const char *Msg, int Size)
{
	char tempstr[100];
	char ch;

	Write("ICMP: ");

	if (Size >= 2)
	{
		ch = *Msg;
		switch (ch)
		{
			case 0:
				Write("Echo Reply, ");
				break;

			case 8:
				Write("Echo Req, ");
				break;

			default:
				Write("Unknown type");
				break;
		}

		switch (ch)
		{
			case 0:
			case 8:
				if (Size > 8 && Size < 107)
				{
					Write("Id = ");
					sprintf(tempstr, "%08lX", *(int *)(Msg + 4));
					Write(tempstr);
					Write(" ");

					Msg += 8;
					Size -= 8;
					memcpy(tempstr, Msg, Size);
					tempstr[Size] = 0;
					Write(tempstr);
				}
				break;

			default:
				Write("Code = ");
				ch = *(Msg + 1);
				sprintf(tempstr, "%04hX", ch);
				tempstr[0] = tempstr[2];
				tempstr[1] = tempstr[3];
				tempstr[2] = ' ';
				tempstr[3] = 0;
				Write(tempstr);
				Msg += 4;
				Size -= 4;
				break;
		}
	}

	Write("\r\n");
}

/*##################  TNetProtocolAnalyser::ShowUdp ##########################
*   Purpose....: Show UDP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowUdp(const char *Msg, int Size)
{
	Write("UDP:");
	Write("\r\n");
}

/*##################  TNetProtocolAnalyser::ShowTcp ##########################
*   Purpose....: Show TCP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowTcp(const char *Msg, int Size)
{
	Write("TCP:");
	Write("\r\n");
}

/*##################  TNetProtocolAnalyser::ShowIp ##########################
*   Purpose....: Show IP data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowIp(const char *Msg, int Size)
{
	char str[80];
	short int len;
	TIpHeader *IpHeader = (TIpHeader *)Msg;

	Msg += sizeof(TIpHeader);
	Size -= sizeof(TIpHeader);

	len = SwapShort(IpHeader->Size);
	sprintf(str, "Size = %d, ",
			len);
	Write(str);

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
	Write("\r\n");

	switch (IpHeader->Protocol)
	{
		case 1:
			ShowIcmp(Msg, Size);
			break;

		case 6:
			ShowTcp(Msg, Size);
			break;

		case 17:
			ShowUdp(Msg, Size);
			break;

		case 121:
			ShowSmp(Msg, Size);
			break;

		default:
			ShowIpData(IpHeader->Protocol, Msg, Size);
			break;
	}
}

/*##################  TNetProtocolAnalyser::ShowNet ##########################
*   Purpose....: Show network addresses		   				      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowNet(const char *Msg, int Size)
{
	Write("NET: ");
	if (Size >= 12)
	{
		ShowNetAddress(Msg + 6);
		Write(" -> ");
		ShowNetAddress(Msg);
		Write("\r\n");
	}
}

/*##################  TNetProtocolAnalyser::ShowUnknown ##########################
*   Purpose....: Show unknown data message		   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowUnknown(int DataType, const char *Msg, int Size)
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

/*##################  TNetProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TNetProtocolAnalyser::ShowMsg()
{
	char *str;
	int size;
	int DataType;

	ShowLongTime(FTime);

	if (FSize >= 14)
		ShowNet(FMsg, FSize);
	else
		return;
	
	str = FMsg + 12;
	size = FSize - 12;

	DataType = SwapShort(*(short int *)str);
	str = str + 2;
	size = size - 2;
	
    switch (DataType)
    {
	    case 0x800:
		    ShowIp(str, size);
			break;

    	case 0x806:
	    	ShowArp(str, size);
            break;

        default:
            ShowUnknown(DataType, str, size);
            break;
            
    }	
}

/*##################  TNetProtocolAnalyser::TNetProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TNetProtocolAnalyser::TNetProtocolAnalyser(TFile *RawFile)
  : TProtocolAnalyser(RawFile, 4096)
{
}

/*##################  TNetProtocolAnalyser::~TNetProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TNetProtocolAnalyser::~TNetProtocolAnalyser()
{
}
