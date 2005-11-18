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
#include "devana.h"

#define FALSE	0
#define TRUE	!FALSE

#define DEVICE_DATA_UNKNOWN         0
#define DEVICE_DATA_NONE            1
#define DEVICE_DATA_UNSIGNED8       2
#define DEVICE_DATA_UNSIGNED16      3
#define DEVICE_DATA_UNSIGNED32      4
#define DEVICE_DATA_SIGNED8         5
#define DEVICE_DATA_SIGNED16        6
#define DEVICE_DATA_SIGNED32        7	
#define DEVICE_DATA_CHAR            8
#define DEVICE_DATA_FLOAT1          9
#define DEVICE_DATA_FLOAT2          10
#define DEVICE_DATA_FLOAT3          11
#define DEVICE_DATA_FLOAT4          12
#define DEVICE_DATA_JULIANDATE      13
#define DEVICE_DATA_BINARY8         14
#define DEVICE_DATA_BINARY16        15
#define DEVICE_DATA_STRING8         16
#define DEVICE_DATA_STRING16        17
#define DEVICE_DATA_BOOLEAN         18
#define DEVICE_DATA_BOOLARRAY       19
#define DEVICE_DATA_BYTEARRAY       20
#define DEVICE_DATA_SHORTSTRING     128

const int DaysInMonth[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

/*##################  PassedDays  ###############
*   Purpose....: Return passed days since 1/1 1970			                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
static long PassedDays(int year, int month, int day)
{
	int i;
	long days = 0;

	if (year >= 1970)
	{
		for (i = 1970; i < year; i++)
			if (i % 4)
				days += 365;
			else
				days += 366;
	}
	else
	{
		for (i = 0; i < year; i++)
			if (i % 4)
				days += 365;
			else
				days += 366;
	}

	for (i = 1; i < month; i++)
		if (i == 2)
		{
			if (year % 4)
				days += 28;
			else
				days += 29;	
		}
		else
			days += DaysInMonth[i - 1];
	days += day - 1;

	return days;
}

/*##################  BinaryToTime  #########################################
*   Purpose....: Convert time from binary form			                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
static void BinaryToTime(long time, int *year, int *month, int *day, int *hour, int *min, int *sec)
{
	*sec = (int)(time % 60L);
	time = time / 60L;
	*min = (int)(time % 60L);
	time = time / 60L;
	*hour = (int)(time % 24L);
	time = time / 24L;
	*year = (int)(1970L + time / 365L);	// based on 1/1 1970 05.00
	time -= PassedDays(*year, 1, 1);
	while (time < 0)
	{
		(*year)--;
		if ((*year) % 4)
			time += 365L;
		else
			time += 366L;
	}

	*month = 1;
	while (time >= 0)
	{
		if (*month == 2)
		{
			if ((*year) % 4)
				time -= 28L;
			else
				time -= 29L;
		}
		else
			time -= DaysInMonth[(*month) - 1];
		(*month)++;
	}

	(*month)--;
	if (*month == 2)
	{
		if ((*year) % 4)
			time += 28L;
		else
			time += 29L;
	}
	else
		time += DaysInMonth[(*month) - 1];

	*day = (int)time + 1;
}

/*##################  TDeviceProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TDeviceProtocolAnalyser::GetMsg()
{
	char *str;
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int count;
	unsigned char uch;
	short int size;
	int i;
	TSerialDebug Debug;
	int StartPos;
	int Pos;

    if (FRawFile->GetSize() <= FRawFile->GetPos())
        return FALSE;

	StartPos = FRawFile->GetPos();

	if (FTime)
		delete FTime;
	FTime = 0;

	str = FMsg;
	FSize = 0;

	for (i = 0; i < 6; i++)
	{
		if (FRawFile->GetSize() > FRawFile->GetPos())
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
		}
		else
		{
			FRawFile->SetPos(StartPos);
			return FALSE;
		}

		uch = (unsigned char)ch;
		switch (i)
		{
			case 0:
				if (uch != 0xDE)
					return TRUE;
				break;

			case 1:
				if (uch != 0x01)
					return TRUE;
				break;

			case 2:
				if (uch != 0xCE)
					return TRUE;
				break;

			case 3:
				if (uch != 0x01)
					return TRUE;
				break;
		}
	}

	size = 0;
	memcpy(&size, str - 2, 2);

	if (size < 0)
		return TRUE;

	for (i = 0; i < size + 2; i++)
	{
		if (FRawFile->GetSize() > FRawFile->GetPos())
		{
			Pos = FRawFile->GetPos();
			FRawFile->Read(&Debug, sizeof(TSerialDebug));

			if (Channel != Debug.Channel)
			{
				FRawFile->SetPos(Pos);
				return TRUE;
			}

			Elapsed = Debug.TimeLSB - LastTime;
			if (Elapsed > 1193 * 500)
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
		}
		else
		{
			FRawFile->SetPos(StartPos);
			return FALSE;
		}
	}

	return TRUE;
}

/*##################  TDeviceProtocolAnalyser::WriteVarType ##########################
*   Purpose....: Write var type	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::WriteVarType(TDeviceVar *var)
{
    switch (var->GetType())
    {
        case DEVICE_DATA_NONE:
            Write("None");
            break;

        case DEVICE_DATA_UNSIGNED8:
            Write("Unsigned 8");
            break;

        case DEVICE_DATA_UNSIGNED16:
            Write("Unsigned 16");
            break;

        case DEVICE_DATA_UNSIGNED32:
            Write("Unsigned 32");
            break;

        case DEVICE_DATA_SIGNED8:
            Write("Signed 8");
            break;

        case DEVICE_DATA_SIGNED16:
            Write("Signed 16");
            break;

        case DEVICE_DATA_SIGNED32:
            Write("Signed 32");
            break;

        case DEVICE_DATA_CHAR:
            Write("Char");
            break;

        case DEVICE_DATA_FLOAT1:
            Write("Float 1");
            break;

        case DEVICE_DATA_FLOAT2:
            Write("Float 2");
            break;

        case DEVICE_DATA_FLOAT3:
            Write("Float 3");
            break;

        case DEVICE_DATA_FLOAT4:
            Write("Float 4");
            break;

        case DEVICE_DATA_JULIANDATE:
            Write("Julian Date");
            break;

        case DEVICE_DATA_BINARY8:
            Write("Binary 8");
            break;

        case DEVICE_DATA_BINARY16:
            Write("Binary 16");
            break;

        case DEVICE_DATA_STRING8:
            Write("String 8");
            break;

        case DEVICE_DATA_STRING16:
            Write("String 16");
            break;

        case DEVICE_DATA_BOOLEAN:
            Write("Boolean");
            break;

        case DEVICE_DATA_BOOLARRAY:
            Write("BoolArray");
            break;

        case DEVICE_DATA_BYTEARRAY:
            Write("ByteArray");
            break;

        default:
            if (var->GetType() < 0)
                Write("ShortString");
            else
                Write("UNKNOWN DATATYPE");
            break;
    }
}

/*##################  TDeviceProtocolAnalyser::WriteVarData ##########################
*   Purpose....: Write var data	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::WriteVarData(TDeviceVar *var)
{
    char str[80];
    long double temp;
    const char *ptr;
    int size;
    int year, month, day;
    int hour, min, sec;
    int i, j;

	switch (var->GetType())
	{
		case DEVICE_DATA_NONE:
            break;

        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
			sprintf(str, "%lu", var->GetUnsigned32());
			Write(str);
			break;

		case DEVICE_DATA_SIGNED8:
		case DEVICE_DATA_SIGNED16:
		case DEVICE_DATA_SIGNED32:
			sprintf(str, "%ld", var->GetSigned32());
			Write(str);
			break;

		case DEVICE_DATA_CHAR:
			str[0] = var->GetChar();
			str[1] = 0;
			Write(str);
			break;

		case DEVICE_DATA_FLOAT1:
			temp = var->GetFloat1() / 10.0;
			sprintf(str, "%1.1Lf", temp);
			Write(str);
			break;

		case DEVICE_DATA_FLOAT2:
			temp = var->GetFloat2() / 100.0;
			sprintf(str, "%1.2Lf", temp);
			Write(str);
			break;

		case DEVICE_DATA_FLOAT3:
			temp = var->GetFloat3() / 1000.0;
			sprintf(str, "%1.3Lf", temp);
			Write(str);
			break;

		case DEVICE_DATA_FLOAT4:
			temp = var->GetFloat4() / 10000.0;
			sprintf(str, "%1.4Lf", temp);
            Write(str);
            break;

		case DEVICE_DATA_JULIANDATE:
            BinaryToTime(var->GetJulian(), &year, &month, &day, &hour, &min, &sec);
			sprintf(str, "%4d-%02d-%02d %02d.%02d.%02d", year, month, day, hour, min, sec);
			Write(str);
            break;

        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
            ptr = (const char *)var->GetBinary(&size);
            for (i = 0; i < size; i++)
            {
                sprintf(str, "04%hX", *ptr);
        		str[0] = str[2];
		        str[1] = str[3];
		        str[2] = 0;
                Write(str);
                if (i != size)
                    Write(" ");
            }
            break;

        case DEVICE_DATA_STRING8:
        case DEVICE_DATA_STRING16:
            Write(var->GetString());
            break;

        case DEVICE_DATA_BOOLEAN:
			if (var->GetBoolean())
				Write("True");
            else
                Write("False");
            break;

        case DEVICE_DATA_BOOLARRAY:
            ptr = var->GetBoolArray(&size);
			for (i = 0; i < size; i++)
			{
				for (j = 0; j < 8; j++)
				{
					if (((*ptr) & (1 << j)) == 0)
					    Write("0");
					else
					    Write("1");
				}
				ptr++;
			}
            break;

        case DEVICE_DATA_BYTEARRAY:
            ptr = (const char *)var->GetByteArray(&size);
			for (i = 0; i < size; i++)
            {
				sprintf(str, "04%hX", *ptr);
				str[0] = str[2];
		        str[1] = str[3];
		        str[2] = 0;
                Write(str);
                if (i != size)
                    Write(" ");
            }
            break;

        default:
            if (var->GetType() < 0)
                Write(var->GetString());
            break;
    }
}

/*##################  TDeviceProtocolAnalyser::WriteVarName ##########################
*   Purpose....: Write var name	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::WriteVarName(TDeviceVar *var)
{
	char str[80];

	switch (var->GetID())
	{
		case DEVICE_VAR_UnitType:
			Write("Unit Type");
			break;

		case DEVICE_VAR_UnitID:
			Write("Unit ID");
			break;

		case DEVICE_VAR_PhysicalDevice:
			Write("Physical Device");
			break;

		case DEVICE_VAR_MsgID:
			Write("MsgID");
			break;

		case DEVICE_VAR_Open:
			Write("Open");
			break;

		case DEVICE_VAR_Enabled:
			Write("Enabled");
			break;

		case DEVICE_VAR_Online:
			Write("Online");
			break;

		case DEVICE_VAR_Busy:
			Write("Busy");
			break;

		case DEVICE_VAR_Name:
			Write("Name");
			break;

		case DEVICE_VAR_BadCard:
			Write("Bad Card");
			break;

		case DEVICE_VAR_TurnedCard:
			Write("Turned Card");
			break;

		case DEVICE_VAR_Strip:
			Write("Strip");
			break;

    	case DEVICE_VAR_TakeCard:               
			Write("Take Card");
			break;

    	case DEVICE_VAR_ForgottenCard:               
            Write("Forgotten Card");
			break;

    	case DEVICE_VAR_TimeoutCard:               
            Write("Timeout Card");
			break;

		case DEVICE_VAR_EjectCard:
			Write("Eject Card");
			break;

		case DEVICE_VAR_Clear:
			Write("Clear");
			break;

		case DEVICE_VAR_Key:
			Write("Key");
			break;

		case DEVICE_VAR_x:
			Write("x");
			break;

		case DEVICE_VAR_y:
			Write("y");
			break;

		case DEVICE_VAR_Size:
			Write("Size");
			break;

		case DEVICE_VAR_Text:
			Write("Text");
			break;

		case DEVICE_VAR_PictureID:
			Write("PictureID");
			break;

		case DEVICE_VAR_ManualReader:
			Write("Manual Reader");
			break;

		case DEVICE_VAR_Beep:
			Write("Beep");
			break;

		case DEVICE_VAR_PumpType:
			Write("Pump Type");
			break;

		case DEVICE_VAR_Index:
			Write("Index");
			break;

		case DEVICE_VAR_PulseVol:
			Write("Pulse Vol");
			break;

		case DEVICE_VAR_Lifted:
			Write("Lifted");
			break;

		case DEVICE_VAR_MaxVolume:
			Write("Max Volume");
			break;

		case DEVICE_VAR_MaxAmount:
			Write("Max Amount");
			break;

		case DEVICE_VAR_Volume:
			Write("Volume");
			break;

		case DEVICE_VAR_Product:
			Write("Product");
			break;

		case DEVICE_VAR_Price:
			Write("Price");
			break;

		case DEVICE_VAR_Amount:
			Write("Amount");
			break;

		case DEVICE_VAR_PulseDiff:
			Write("Pulse Diff");
			break;

		case DEVICE_VAR_Count:
			Write("Count");
			break;

		case DEVICE_VAR_Width:
			Write("Width");
			break;

		case DEVICE_VAR_AlwaysPrint:
			Write("Always Print");
			break;

		case DEVICE_VAR_Jammed:
			Write("Jammed");
			break;

		case DEVICE_VAR_PaperLow:
			Write("Paper Low");
			break;

		case DEVICE_VAR_PaperEnd:
			Write("Paper End");
			break;

		case DEVICE_VAR_Cut:
			Write("Cut");
			break;

		case DEVICE_VAR_Printing:
			Write("Printing");
			break;

		case DEVICE_VAR_PaperInPresenter:
			Write("Paper In Presenter");
			break;

		case DEVICE_VAR_ForgottenReceipt:
			Write("Forgotten Receipt");
			break;

		case DEVICE_VAR_TerminalName:
			Write("Terminal Name");
			break;

		case DEVICE_VAR_TerminalID:
			Write("Terminal ID");
			break;

		case DEVICE_VAR_Pump:
			Write("Pump");
			break;

		case DEVICE_VAR_FillTime:
			Write("Fill Time");
			break;

		case DEVICE_VAR_Company:
			Write("Company");
			break;

		case DEVICE_VAR_Customer:
			Write("Customer");
			break;

		case DEVICE_VAR_MasterSeq:
			Write("Master Seq");
			break;

		case DEVICE_VAR_Km:
			Write("Km");
			break;

		case DEVICE_VAR_Vat:
			Write("Vat");
			break;

		case DEVICE_VAR_ID:
			Write("ID");
			break;

		case DEVICE_VAR_CardType:
			Write("Card Type");
			break;

		case DEVICE_VAR_Code:
			Write("Code");
			break;

		case DEVICE_VAR_ControlNumber:
			Write("Control Number");
			break;

		case DEVICE_VAR_Unit:
			Write("Unit");
			break;

		case DEVICE_VAR_Version:
			Write("Version");
			break;

		default:
			sprintf(str, "<Unknown Variable (%d)>", var->GetID());
			Write(str);
			break;
	}
}

/*##################  TDeviceProtocolAnalyser::WriteTagName ##########################
*   Purpose....: Write tag name	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::WriteTagName(TDeviceTag *tag)
{
	char str[80];

	switch (tag->GetID())
	{
		case DEVICE_TAG_HEADER:
			Write("<Header>");
			break;

		case DEVICE_TAG_ACK:
			Write("<Ack>");
			break;

		case DEVICE_TAG_REQ:
			Write("<Req>");
			break;

		case DEVICE_TAG_REPLY:
			Write("<Reply>");
			break;

		case DEVICE_TAG_INFO:
			Write("<Info>");
			break;

		case DEVICE_TAG_INSTALL_REQ:
			Write("<Install Req>");
			break;

		case DEVICE_TAG_INSTALL_ACCEPT:
			Write("<Install Accept>");
			break;

		case DEVICE_TAG_RESET_REQ:
			Write("<Reset Req>");
			break;

		case DEVICE_TAG_RESET_ACK:
			Write("<Reset Ack>");
			break;

		case DEVICE_TAG_POLL_REQ:
			Write("<Poll Req>");
			break;

		case DEVICE_TAG_POLL_ACK:
			Write("<Poll Ack>");
			break;

		case DEVICE_TAG_CONFIG_REQ:
			Write("<Config Req>");
			break;

		case DEVICE_TAG_CONFIG_ACK:
			Write("<Config Ack>");
			break;

		case DEVICE_TAG_SmallText:
			Write("<Small Text>");
			break;

		case DEVICE_TAG_BigText:
			Write("<Big Text>");
			break;

		case DEVICE_TAG_Line:
			Write("<Line>");
			break;

		case DEVICE_TAG_Picture:
			Write("<Picture>");
			break;

		case DEVICE_TAG_Reverse:
			Write("<Reverse>");
			break;

		case DEVICE_TAG_Unreverse:
			Write("<Unreverse>");
			break;

		case DEVICE_TAG_Nozzle:
			Write("<Nozzle>");
			break;

		case DEVICE_TAG_Authorize:
			Write("<Authorize>");
			break;

		case DEVICE_TAG_Fill:
			Write("<Fill>");
			break;

		case DEVICE_TAG_Product:
			Write("<Product>");
			break;

		case DEVICE_TAG_ZeroFill:
			Write("<Zero Fill>");
			break;

		case DEVICE_TAG_NoFill:
			Write("<No Fill>");
			break;

		case DEVICE_TAG_PulseError:
			Write("<Pulse Error>");
			break;

		case DEVICE_TAG_FillCompleted:
			Write("<Fill Completed>");
			break;

		case DEVICE_TAG_Print:
			Write("<Print>");
			break;

		case DEVICE_TAG_Card:
			Write("<Card>");
			break;

		default:
			sprintf(str, "<Unknown Tag (%d)>", tag->GetID());
			Write(str);
			break;
	}
}

/*##################  TDeviceProtocolAnalyser::ShowDeviceVar ##########################
*   Purpose....: Show var	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::ShowDeviceVar(TDeviceVar *var, int level)
{
	int i;

	for (i = 0; i < level; i++)
		Write("  ");

	WriteVarName(var);
	Write("=");

	if (var->GetID() == DEVICE_VAR_UnitType)
	{
		switch (var->GetSigned32())
		{
			case DEVICE_TYPE_CARD:
				Write("Card Reader");
				break;

			case DEVICE_TYPE_KEYBOARD:
				Write("Keyboard");
				break;

			case DEVICE_TYPE_DISPLAY:
				Write("Display");
				break;

			case DEVICE_TYPE_BUZZER:
				Write("Buzzer");
				break;

			case DEVICE_TYPE_PUMP:
				Write("Pump");
				break;

			case DEVICE_TYPE_RECEIPT:
				Write("Receipt");
				break;

			case DEVICE_TYPE_SYSTEM:
				Write("System");
				break;

			default:
				WriteVarData(var);
				break;
		}
	}
	else
		WriteVarData(var);

//	Write(" (");
//	WriteVarType(var);
//  Write")");
	Write("\r\n");
}

/*##################  TDeviceProtocolAnalyser::ShowDeviceTag ##########################
*   Purpose....: Show tag	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::ShowDeviceTag(TDeviceTag *RootTag, int level)
{
	int i;
	TDeviceTag *tag;
	TDeviceVar *var;

	for (i = 0; i < level; i++)
		Write("  ");

	WriteTagName(RootTag);
	Write("\r\n");

	tag = RootTag->GotoFirstTag();
	while (tag)
	{
		ShowDeviceTag(tag, level + 1);
		tag = RootTag->GotoNextTag();
	}

	var = RootTag->GotoFirstVar();
	while (var)
	{
		ShowDeviceVar(var, level + 1);
		var = RootTag->GotoNextVar();
	}
}

/*##################  TDeviceProtocolAnalyser::ShowDevice ##########################
*   Purpose....: Show msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::ShowDevice(TDeviceMsg *msg)
{
	TDeviceTag *tag;

	if (FTime)
		ShowLongTime(FTime);
	Write("\r\n");

	tag = msg->GotoFirstTag();
	while (tag)
	{
		ShowDeviceTag(tag, 0);
		tag = msg->GotoNextTag();
	}
}

/*##################  TDeviceProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TDeviceProtocolAnalyser::ShowMsg()
{
	TDeviceMsg msg(0x10000);

    if (msg.Parse(0x1CE01DE, FMsg, FSize + 8))
        ShowDevice(&msg);
	else
	{
		if (FTime)
			ShowLongTime(FTime);
		ShowMneMsg();
	}
}

/*##################  TDeviceProtocolAnalyser::TDeviceProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TDeviceProtocolAnalyser::TDeviceProtocolAnalyser(TFile *RawFile, int MaxSize)
  : TProtocolAnalyser(RawFile, MaxSize)
{
}

/*##################  TDeviceProtocolAnalyser::~TDeviceProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TDeviceProtocolAnalyser::~TDeviceProtocolAnalyser()
{
}
