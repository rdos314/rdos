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
# cbus.cpp
# CBUS protocol translator
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "cbus.h"

#define FALSE	0
#define TRUE	!FALSE

/* Macro to convert an ascii hex-value ('0' - 'F') to a binary value (0 - 15) */
#define     HexBin1(x)      (((x) >= 'A') ? (((x) - 'A' + 10) & 0x0f) : (((x) - '0') & 0x0f))
#define     HexBin2(x)      (((x) >= 'A') ? ((((x) - 'A' + 10) & 0x0f) << 4 ) : ((((x) - '0') & 0x0f) << 4 ))

/* Macro to convert a binary value (0 - 15) to an ascii hex-value ('0' - 'F') */
#define     BinHex1(x)      ((((x) & 0xf) > 9) ? (((x) & 0xf) + 'A' - 10) : (((x) & 0xf) + '0'))
#define     BinHex2(x)      (((((x) >> 4) & 0xf) > 9) ? ((((x) >> 4) & 0xf) + 'A' - 10) : ((((x) >> 4) & 0xf) + '0'))

/*##################  HexToBinaryByte          ##########################
*   Purpose....: Primitive for hex_to_binary_byte and fast in-line function #
*                to be used internally in module.                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 95-11-13 an                                                #
*                All code from old hex_to_binary_byte() (by JS).            #
*##########################################################################*/
static int HexToBinaryByte(const char ConvertStr[])
{
	unsigned char a;
	unsigned char b;

	a = ConvertStr[0];

	/* if check that chars are 0 - 9 or A - F use these tests 	*/
	/* and make a and b and return value int					*/

	if ((a < '0' || a > 'F') || (a > '9' && a < 'A'))
		return (-1000);
	else
	{
		if (a > '9')
			a -= 'A' - 0xA;
		else
			a -= '0';
	}

	b = ConvertStr[1];

	if ((b < '0' || b > 'F') || (b > '9' && b < 'A'))
		return (-1000);
	else
	{
		if (b > '9')
			b -= 'A' - 0xA;
		else
			b -= '0';
	}

	return ((a << 4) | b);
}

/*##################  BccCalc  ##########################
*   Purpose....: TO CREATE A BCC CHECK SUM STRING					        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
static void BccCalc(const char *indata, char *bcc, int len )
{
	int value;
	int i;
	int temp;

	value = 0;
	for (i = 1; i <= len; i++)
	{
		temp = (int)*indata;
		value ^= temp;
		indata++;
	};
	bcc[0]	= (char)BinHex2(value);
	bcc[1] = (char)BinHex1(value);
}

/*##################  TCbusProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next CBUS message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TCbusProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int count;

	count = *FRawCount - FRawPos;

	if (count == 0)
		return FALSE;

    if (FTime)
        delete FTime;

	FTime = new TDateTime(FComMsg->TimeMSB, FComMsg->TimeLSB);

	str = FMsg;
	*str = 0;
	FSize = 0;

	Channel = FComMsg->Channel;
	LastTime = FComMsg->TimeLSB;
	ch = FComMsg->ch;
	FSize++;
	FComMsg++;
	FRawPos++;

	while (count > FSize && ch != ':')
	{
		if (Channel != FComMsg->Channel)
			return TRUE;

		Elapsed = FComMsg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
			return TRUE;

		LastTime = FComMsg->TimeLSB;
		ch = FComMsg->ch;
		FSize++;
		FComMsg++;
		FRawPos++;
	}

	while (count > FSize && ch != '\r')
	{
		*str = ch;
		str++;
		*str = 0;

		if (Channel != FComMsg->Channel)
			return TRUE;
		
		Elapsed = FComMsg->TimeLSB - LastTime;
		if (Elapsed > 1193 * 25)
			return TRUE;

		LastTime = FComMsg->TimeLSB;
		ch = FComMsg->ch;
		FSize++;
		FComMsg++;
		FRawPos++;
	}

	return TRUE;
}

/*##################  TCbusProtocolAnalyser::ShowDefault ##########################
*   Purpose....: Show default message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowDefault(TCbusMsg *Msg)
{
    char str[80];
    
	sprintf(str, "%02X <%s>", Msg->MessCode, Msg->MsgData);
//	Write(str);
}

/*##################  TCbusProtocolAnalyser::GetCbusPumpReqText ##########################
*   Purpose....: Get cbus pump req text	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowCbusPumpReqText()
{
	char str[80];
	int MaxPulses;
	int MaxAmount;
	int Price0;
	int Price1;
	int Price2;

	switch (FCbusReqMsg->MessCode)
	{
		case 0x51:
			if (strlen(FCbusReqMsg->MsgData) == 1)
				switch (FCbusReqMsg->MsgData[0])
				{
					case '0':
						Write("Stop");
						break;

					case '1':
						Write("Start");
						break;

					default:
						ShowDefault(FCbusReqMsg);
						break;
				}
			else
				ShowDefault(FCbusReqMsg);
			break;

		case 0x53:
			if (sscanf(	FCbusReqMsg->MsgData,
						"%06d%06d%04d%04d%04d",
						&MaxPulses,
						&MaxAmount,
						&Price0,
						&Price1,
						&Price2) == 5)
			{
				sprintf(	str,
							"Max vol=%d, Max amount=%d, Price1=%03d, Price2=%03d, Price3=%03d",
							MaxPulses,
							MaxAmount,
							Price0,
							Price1,
							Price2);
				Write(str);
			}
			else
				ShowDefault(FCbusReqMsg);
			break;

		case 0x55:
			break;

		case 0x57:
			break;

		default:
			ShowDefault(FCbusReqMsg);
			break;
	}
}

/*##################  TCbusProtocolAnalyser::ShowCbusPumpReplyText ##########################
*   Purpose....: Show cbus pump reply text	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowCbusPumpReplyText()
{
	int data;
	char str[80];
	int Pulses;
	int Amount;
	int FillGrade;
	int Price;

	switch (FCbusReplyMsg->MessCode)
	{
		case 0x51:
		case 0x52:
			if (strlen(FCbusReplyMsg->MsgData) == 4)
			{
				data = HexToBinaryByte(&FCbusReplyMsg->MsgData[0]);
				if (data & 1)
					Write(" Lifted");
				else
					Write(" Not lifted");

				if (data & 2)
					Write(", Fuel on");

				switch ((data >> 2) & 3)
				{
					case 0:
						Write(", Idle");
						break;

					case 1:
						Write(", Fill");
						break;

					case 2:
						Write(", Fill-end");
						break;
				}

				data = HexToBinaryByte(&FCbusReplyMsg->MsgData[2]);
				if (data)
				{
					sprintf(str, ", Error=%02X", data);
					Write(str);
				}
			}
			else
				ShowDefault(FCbusReplyMsg);
			break;

		case 0x53:
		case 0x54:
			break;

		case 0x55:
		case 0x56:
			if (sscanf(	FCbusReplyMsg->MsgData,
						"%6d %6d %1d %4d",
						&Pulses,
						&Amount,
						&FillGrade,
						&Price) == 4)
			{
				sprintf(str, "Vol=%d, Amount=%d, Prod=%d, Price=%03d",
						Pulses,
						Amount,
						FillGrade,
						Price);
				Write(str);
			}
			else
				ShowDefault(FCbusReplyMsg);
			break;

		case 0x57:
		case 0x58:
			break;

		default:
			ShowDefault(FCbusReplyMsg);
			break;
	}
}

/*##################  TCbusProtocolAnalyser::ShowAddress ##########################
*   Purpose....: Show message address  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowAddress(char Adr)
{
	char str[30];

	sprintf(str, " %d ", Adr);
	Write(str);
}

/*##################  TCbusProtocolAnalyser::ShowCode ##########################
*   Purpose....: Show message code  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowCode(char Code)
{
	char str[30];

	switch (Code)
	{
		case 0x51:
		case 0x52:
			Write("POLL ");
			break;

		case 0x53:
		case 0x54:
			Write("PRESET ");
			break;

		case 0x55:
		case 0x56:
			Write("DATA ");
			break;

		case 0x57:
		case 0x58:
			Write("END ");
			break;

		default:
			sprintf(str, "%02X ", Code);
			Write(str);
			break;
	}
}

/*##################  TCbusProtocolAnalyser::UpdatePump ##########################
*   Purpose....: Update CBUS pump msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::UpdatePump()
{
	if (FCbusReqMsg || FCbusReplyMsg)
	{
		ShowLongTime(FTime);

		if (FCbusReqMsg)
		{
			ShowAddress(FCbusReqMsg->Adr);
			ShowCode(FCbusReqMsg->MessCode);
			ShowCbusPumpReqText();
		}
		else
			Write("*** NO REQ ***");

		if (FCbusReplyMsg)
		{
			if (FCbusReqMsg == 0)
			{
				ShowAddress(FCbusReplyMsg->Adr);
				ShowCode(FCbusReplyMsg->MessCode);
			}
			ShowCbusPumpReplyText();
		}
		else
			Write("*** NO ANSWER ***");

		Write("\r\n");

		if (FCbusReqMsg)
			delete FCbusReqMsg;
		FCbusReqMsg = 0;

		if (FCbusReplyMsg)
			delete FCbusReplyMsg;
		FCbusReplyMsg = 0;

	}
}

/*##################  TCbusProtocolAnalyser::ShowPumpMsg ##########################
*   Purpose....: Show CBUS pump msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowPumpMsg(char ToAdr, char FromAdr, char MessCode, const char *MsgData)
{
	TCbusMsg *CbusMsg;

	CbusMsg = new TCbusMsg;
	CbusMsg->MessCode = MessCode;
	strcpy(CbusMsg->MsgData, MsgData);

	if (MessCode & 1)
	{
		CbusMsg->Adr = FromAdr;
		if (FCbusReqMsg)
			UpdatePump();
		FCbusReqMsg = CbusMsg;
	}
	else
	{
		CbusMsg->Adr = ToAdr;
		if (FCbusReplyMsg)
			UpdatePump();
		FCbusReplyMsg = CbusMsg;
		UpdatePump();
	}
}

/*##################  TCbusProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show CBUS msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCbusProtocolAnalyser::ShowMsg()
{
	int Len;
	int MsgLen;
	char Bcc[2];
	char MsgData[256];
	char ToAdr;
	char FromAdr;
	char MessCode;
	char *str;

	MsgLen = strlen(FMsg);
	str = FMsg;

	if (MsgLen >= 9 + 2)
	{
		Len = HexBin2(*(str+7)) + HexBin1(*(str+8));
		MsgLen -= 9 + 2;
		if (Len == MsgLen)
		{
			BccCalc(str+1, Bcc, 8 + Len);
			if (*(str+Len+9) == Bcc[0] && *(str+Len+10) == Bcc[1])
			{
				FromAdr = HexBin2(*(str+1)) + HexBin1(*(str+2));
				ToAdr = HexBin2(*(str+3)) + HexBin1(*(str+4));
				MessCode = HexBin2(*(str+5)) + HexBin1(*(str+6));
				memcpy(MsgData, str+9, Len);
				MsgData[Len] = 0;
				if (MessCode >= 0x50 && MessCode < 0x60)
					ShowPumpMsg(ToAdr, FromAdr, MessCode, MsgData);
//				else
//					ShowHexMsg();
			}
//			else
//				ShowHexMsg();
		}
//		else
//			ShowHexMsg();
	}
	else
	{
		UpdatePump();
//		ShowHexMsg();
	}
}

/*##################  TCbusProtocolAnalyser::TCbusProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCbusProtocolAnalyser::TCbusProtocolAnalyser(const char *MemMapName, int MaxSize)
  : TProtocolAnalyser(MemMapName, MaxSize)
{
	FCbusReqMsg = 0;
	FCbusReplyMsg = 0;
}

/*##################  TCbusProtocolAnalyser::~TCbusProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCbusProtocolAnalyser::~TCbusProtocolAnalyser()
{
	if (FCbusReqMsg)
        delete FCbusReqMsg;

    if (FCbusReplyMsg)
        delete FCbusReplyMsg;
}
