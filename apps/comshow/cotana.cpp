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
#include "cotana.h"

#define FALSE	0
#define TRUE	!FALSE

#define COFLEX_DATA_UNKNOWN         0
#define COFLEX_DATA_NONE            1
#define COFLEX_DATA_UNSIGNED8       2
#define COFLEX_DATA_UNSIGNED16      3
#define COFLEX_DATA_UNSIGNED32      4
#define COFLEX_DATA_SIGNED8         5
#define COFLEX_DATA_SIGNED16        6
#define COFLEX_DATA_SIGNED32        7	
#define COFLEX_DATA_CHAR            8
#define COFLEX_DATA_FLOAT1          9
#define COFLEX_DATA_FLOAT2          10
#define COFLEX_DATA_FLOAT3          11
#define COFLEX_DATA_FLOAT4          12
#define COFLEX_DATA_JULIANDATE      13
#define COFLEX_DATA_BINARY8         14
#define COFLEX_DATA_BINARY16        15
#define COFLEX_DATA_STRING8         16
#define COFLEX_DATA_STRING16        17
#define COFLEX_DATA_BOOLEAN         18
#define COFLEX_DATA_BOOLARRAY       19
#define COFLEX_DATA_BYTEARRAY       20
#define COFLEX_DATA_SHORTSTRING     128

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

/*##################  TCotexProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next Cotex message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TCotexProtocolAnalyser::GetMsg()
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
	TComMsg *ComPtr = FComMsg;

	count = *FRawCount - FRawPos;

	if (count == 0)
		return FALSE;

	if (FTime)
		delete FTime;

	FTime = new TDateTime(FComMsg->TimeMSB, FComMsg->TimeLSB);

	str = FMsg;
	FSize = 0;

	Channel = ComPtr->Channel;
	LastTime = ComPtr->TimeLSB;

	for (i = 0; i < 6; i++)
	{
		if (count > FSize)
		{
			if (Channel != ComPtr->Channel)
			{
				FRawPos += FSize;
				FComMsg = ComPtr;
				return TRUE;
			}

			Elapsed = ComPtr->TimeLSB - LastTime;
			if (Elapsed > 1193 * 1000)
			{
				FRawPos += FSize;
				FComMsg = ComPtr;
				return TRUE;
			}

			LastTime = ComPtr->TimeLSB;
			ch = ComPtr->ch;
			FSize++;
			ComPtr++;
			*str = ch;
			str++;
			*str = 0;
		}
		else
			return FALSE;

		uch = (unsigned char)ch;
		switch (i)
		{
			case 0:
				if (uch != 0xC0)
				{
					FRawPos += FSize;
					FComMsg = ComPtr;
					return TRUE;
				}
				break;

			case 1:
				if (uch != 0xDA)
				{
					FRawPos += FSize;
					FComMsg = ComPtr;
					return TRUE;
				}
				break;

			case 2:
				if (uch != 0xB0)
				{
					FRawPos += FSize;
					FComMsg = ComPtr;
					return TRUE;
				}
				break;

			case 3:
				if (uch != 0x1A)
				{
					FRawPos += FSize;
					FComMsg = ComPtr;
					return TRUE;
				}
				break;
		}
	}

	size = 0;
	memcpy(&size, str - 2, 2);

	if (size < 0 || size > 0x2000)
	{
		FRawPos += FSize;
		FComMsg = ComPtr;
		return TRUE;
	}

	for (i = 0; i < size + 2; i++)
	{
		if (count > FSize)
		{
			if (Channel != ComPtr->Channel)
			{
				FRawPos += FSize;
				FComMsg = ComPtr;
				return TRUE;
			}

			Elapsed = ComPtr->TimeLSB - LastTime;
			if (Elapsed > 1193 * 10000)
			{
				FRawPos += FSize;
				FComMsg = ComPtr;
				return TRUE;
			}

			LastTime = ComPtr->TimeLSB;
			ch = ComPtr->ch;
			FSize++;
			ComPtr++;
			*str = ch;
			str++;
			*str = 0;
		}
		else
			return FALSE;

	}

	FRawPos += FSize;
	FComMsg = ComPtr;
	return TRUE;
}

/*##################  TCotexProtocolAnalyser::WriteVarType ##########################
*   Purpose....: Write var type	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::WriteVarType(TCotexVar *var)
{
    switch (var->GetType())
    {
        case COFLEX_DATA_NONE:
            Write("None");
            break;

        case COFLEX_DATA_UNSIGNED8:
            Write("Unsigned 8");
            break;

        case COFLEX_DATA_UNSIGNED16:
            Write("Unsigned 16");
            break;

        case COFLEX_DATA_UNSIGNED32:
            Write("Unsigned 32");
            break;

        case COFLEX_DATA_SIGNED8:
            Write("Signed 8");
            break;

        case COFLEX_DATA_SIGNED16:
            Write("Signed 16");
            break;

        case COFLEX_DATA_SIGNED32:
            Write("Signed 32");
            break;

        case COFLEX_DATA_CHAR:
            Write("Char");
            break;

        case COFLEX_DATA_FLOAT1:
            Write("Float 1");
            break;

        case COFLEX_DATA_FLOAT2:
            Write("Float 2");
            break;

        case COFLEX_DATA_FLOAT3:
            Write("Float 3");
            break;

        case COFLEX_DATA_FLOAT4:
            Write("Float 4");
            break;

        case COFLEX_DATA_JULIANDATE:
            Write("Julian Date");
            break;

        case COFLEX_DATA_BINARY8:
            Write("Binary 8");
            break;

        case COFLEX_DATA_BINARY16:
            Write("Binary 16");
            break;

        case COFLEX_DATA_STRING8:
            Write("String 8");
            break;

        case COFLEX_DATA_STRING16:
            Write("String 16");
            break;

        case COFLEX_DATA_BOOLEAN:
            Write("Boolean");
            break;

        case COFLEX_DATA_BOOLARRAY:
            Write("BoolArray");
            break;

        case COFLEX_DATA_BYTEARRAY:
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

/*##################  TCotexProtocolAnalyser::WriteVarData ##########################
*   Purpose....: Write var data	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::WriteVarData(TCotexVar *var)
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
        case COFLEX_DATA_NONE:
            break;

        case COFLEX_DATA_UNSIGNED8:
        case COFLEX_DATA_UNSIGNED16:
        case COFLEX_DATA_UNSIGNED32:
			sprintf(str, "%lu", var->GetUnsigned32());
			Write(str);
			break;

		case COFLEX_DATA_SIGNED8:
		case COFLEX_DATA_SIGNED16:
		case COFLEX_DATA_SIGNED32:
			sprintf(str, "%ld", var->GetSigned32());
			Write(str);
			break;

		case COFLEX_DATA_CHAR:
			str[0] = var->GetChar();
			str[1] = 0;
			Write(str);
			break;

		case COFLEX_DATA_FLOAT1:
			temp = var->GetFloat1() / 10.0;
			sprintf(str, "%1.1Lf", temp);
			Write(str);
			break;

		case COFLEX_DATA_FLOAT2:
			temp = var->GetFloat2() / 100.0;
			sprintf(str, "%1.2Lf", temp);
			Write(str);
			break;

		case COFLEX_DATA_FLOAT3:
			temp = var->GetFloat3() / 1000.0;
			sprintf(str, "%1.3Lf", temp);
			Write(str);
			break;

		case COFLEX_DATA_FLOAT4:
			temp = var->GetFloat4() / 10000.0;
			sprintf(str, "%1.4Lf", temp);
            Write(str);
            break;

        case COFLEX_DATA_JULIANDATE:
            BinaryToTime(var->GetJulian(), &year, &month, &day, &hour, &min, &sec);
            sprintf(str, "%4d-%02d-%02d %02d.%02d.%02d", year, month, day, hour, min, sec);
            Write(str);
            break;

        case COFLEX_DATA_BINARY8:
        case COFLEX_DATA_BINARY16:
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

        case COFLEX_DATA_STRING8:
        case COFLEX_DATA_STRING16:
            Write(var->GetString());
            break;

        case COFLEX_DATA_BOOLEAN:
            if (var->GetBoolean())
                Write("True");
            else
                Write("False");
            break;

        case COFLEX_DATA_BOOLARRAY:
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

        case COFLEX_DATA_BYTEARRAY:
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

/*##################  TCotexProtocolAnalyser::WriteVarName ##########################
*   Purpose....: Write var name	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::WriteVarName(TCotexVar *var)
{
    char str[80];
    
    switch (var->GetID())
    {
    	case COFLEX_VAR_AlarmCount:               
            Write("AlarmCount");
			break;

    	case COFLEX_VAR_AlarmFlag:                
            Write("AlarmFlag");
			break;

    	case COFLEX_VAR_AlramMax:                 
            Write("AlarmMax");
			break;

    	case COFLEX_VAR_BarListCount:             
            Write("BarListCount");
			break;

    	case COFLEX_VAR_BarListFlag:              
            Write("BarListFlag");
			break;

    	case COFLEX_VAR_BarListMax:               
            Write("BarListMax");
			break;

    	case COFLEX_VAR_BarSeq:                   
            Write("BarSeq");
			break;

    	case COFLEX_VAR_BarSeqEnd:                
            Write("BarSeqEnd");
			break;

    	case COFLEX_VAR_BarSeqStart:              
            Write("BarSeqStart");
			break;

    	case COFLEX_VAR_BlackListCount:           
            Write("BlackListCount");
			break;

    	case COFLEX_VAR_BlackListFlag:            
            Write("BlackListFlag");
			break;

    	case COFLEX_VAR_BlackListMax:             
            Write("BlackListMax");
			break;

    	case COFLEX_VAR_CardDraw:                 
            Write("CardDraw");
			break;

    	case COFLEX_VAR_CardID:                   
            Write("CardID");
			break;

    	case COFLEX_VAR_CardPublisherName:        
            Write("CardPublisherName");
			break;

    	case COFLEX_VAR_CardSeq:                  
            Write("CardSeq");
			break;

    	case COFLEX_VAR_CardSeqEnd:               
            Write("CardSeqEnd");
			break;

    	case COFLEX_VAR_CardSeqStart:             
            Write("CardSeqStart");
			break;

    	case COFLEX_VAR_CardType:                 
            Write("CardType");
			break;

    	case COFLEX_VAR_CashSeq:                  
            Write("CashSeq");
			break;

    	case COFLEX_VAR_CashSeqEnd:               
            Write("CashSeqEnd");
			break;

    	case COFLEX_VAR_CashSeqStart:             
            Write("CashSeqStart");
			break;

    	case COFLEX_VAR_CompanyID:                
            Write("CompanyID");
			break;

    	case COFLEX_VAR_CompanyName:              
            Write("CompanyName");
			break;

    	case COFLEX_VAR_ContinuedFlag:            
            Write("ContinuedFlag");
			break;

    	case COFLEX_VAR_CurrencyCount:            
            Write("CurrencyCount");
			break;

    	case COFLEX_VAR_CurrencyMax:              
            Write("CurrencyMax");
			break;

    	case COFLEX_VAR_CurrencyType:             
            Write("CurrencyType");
			break;

    	case COFLEX_VAR_CustomerID:               
            Write("CustomerID");
			break;

    	case COFLEX_VAR_CustomerName:             
            Write("CustomerName");
			break;

    	case COFLEX_VAR_DaylightSavingFlag:       
            Write("DaylightSavingFlag");
			break;

    	case COFLEX_VAR_DefaultVAT:               
            Write("DefaultVAT");
			break;

    	case COFLEX_VAR_EvaluationNumber:         
            Write("EvaluationNumber");
			break;

    	case COFLEX_VAR_FillTime:                 
            Write("FillTime");
			break;

    	case COFLEX_VAR_FirstFlag:                
            Write("FirstFlag");
			break;

    	case COFLEX_VAR_FunctionCardCount:        
            Write("FunctionCardCount");
			break;

    	case COFLEX_VAR_FunctionCardMax:          
            Write("FunctionCardMax");
			break;

    	case COFLEX_VAR_HostID:                   
            Write("HostID");
			break;

    	case COFLEX_VAR_KeyPress:                 
            Write("KeyPress");
			break;

    	case COFLEX_VAR_LayoutCount:              
            Write("LayoutCount");
			break;

    	case COFLEX_VAR_LayoutID:                 
            Write("LayoutID");
			break;

    	case COFLEX_VAR_LayoutListFlag:           
            Write("LayoutListFlag");
			break;

    	case COFLEX_VAR_LayoutMax:                
            Write("LayoutMax");
			break;

    	case COFLEX_VAR_LogFlag:                  
            Write("LogFlag");
			break;

    	case COFLEX_VAR_LogListCount:             
            Write("LogListCount");
			break;

    	case COFLEX_VAR_LogListMax:               
            Write("LogListMax");
			break;

    	case COFLEX_VAR_MasterSeq:                
            Write("MasterSeq");
			break;

    	case COFLEX_VAR_MasterSeqEnd:             
            Write("MasterSeqEnd");
			break;

    	case COFLEX_VAR_MasterSeqStart:           
            Write("MasterSeqStart");
			break;

    	case COFLEX_VAR_MaxAmount:                
            Write("MaxAmount");
			break;

    	case COFLEX_VAR_MaxFillTime:             
            Write("MaxFillTime");
			break;

    	case COFLEX_VAR_MaxVolume:                
            Write("MaxVolume");
			break;

    	case COFLEX_VAR_MessageID:                
            Write("MessageID");
			break;

    	case COFLEX_VAR_MeterReading:             
            Write("MeterReading");
			break;

    	case COFLEX_VAR_MeterReadingOn:           
            Write("MeterReadingOn");
			break;

    	case COFLEX_VAR_MeterReadingOff:          
            Write("MeterReadingOff");
			break;

    	case COFLEX_VAR_MeterReadingDefault:      
            Write("MeterReadingDefault");
			break;

    	case COFLEX_VAR_NoteSeq:                  
            Write("NoteSeq");
			break;

    	case COFLEX_VAR_NoteSeqEnd:               
            Write("NoteSeqEnd");
			break;

    	case COFLEX_VAR_NoteSeqStart:             
            Write("NoteSeqStart");
			break;

    	case COFLEX_VAR_NoteTimeout:              
            Write("NoteTimeout");
			break;

    	case COFLEX_VAR_NozzleSelectType:         
            Write("NozzleSelectType");
			break;

    	case COFLEX_VAR_NozzleTimeout:            
            Write("NozzleTimeout");
			break;

    	case COFLEX_VAR_OffLineFlag:              
            Write("OffLineFlag");
			break;

    	case COFLEX_VAR_OnLineFlag:               
            Write("OnLineFlag");
			break;

    	case COFLEX_VAR_PayAmount:                
            Write("PayAmount");
			break;

    	case COFLEX_VAR_PayType:                  
            Write("PayType");
			break;

    	case COFLEX_VAR_PCodeTimeout:             
            Write("PCodeTimeout");
			break;

    	case COFLEX_VAR_PinCode:                  
            Write("PinCode");
			break;

    	case COFLEX_VAR_PinCodeType:              
            Write("PinCodeType");
			break;

    	case COFLEX_VAR_PinCorrect:               
            Write("PinCorrect");
			break;

    	case COFLEX_VAR_PinOn:                    
            Write("PinOn");
			break;

    	case COFLEX_VAR_PriceOff:                 
            Write("PriceOff");
			break;

    	case COFLEX_VAR_PriceDefault:             
            Write("PriceDefault");
			break;

    	case COFLEX_VAR_Price:                    
            Write("Price");
			break;

    	case COFLEX_VAR_PriceIncludeVAT:          
            Write("PriceIncludeVAT");
			break;

    	case COFLEX_VAR_ProductCount:             
            Write("ProductCount");
			break;

    	case COFLEX_VAR_ProductID:                
            Write("ProductID");
			break;

    	case COFLEX_VAR_ProductMax:               
            Write("ProductMax");
			break;

    	case COFLEX_VAR_ProductName:              
            Write("ProductName");
			break;

    	case COFLEX_VAR_ProductVat:               
            Write("ProductVat");
			break;

    	case COFLEX_VAR_PulseTimeout:             
            Write("PulseTimeout");
			break;

    	case COFLEX_VAR_PulseVolume:              
            Write("PulseVolume");
			break;

    	case COFLEX_VAR_PumpCount:                
            Write("PumpCount");
			break;

    	case COFLEX_VAR_PumpID:                   
            Write("PumpID");
			break;

    	case COFLEX_VAR_PumpMax:                  
            Write("PumpMax");
			break;

    	case COFLEX_VAR_PumpPort:                 
            Write("PumpPort");
			break;

    	case COFLEX_VAR_PumpType:                 
            Write("PumpType");
			break;

    	case COFLEX_VAR_RemoteFlag:               
            Write("RemoteFlag");
			break;

    	case COFLEX_VAR_SectionID:                
            Write("SectionID");
			break;

    	case COFLEX_VAR_StatusInterval:           
            Write("StatusInterval");
			break;

    	case COFLEX_VAR_Strip:                    
            Write("Strip");
			break;

    	case COFLEX_VAR_StripCodeType:            
            Write("StripCodeType");
			break;

    	case COFLEX_VAR_StripMask:                
            Write("StripMask");
			break;

    	case COFLEX_VAR_TerminalID:               
            Write("TerminalID");
			break;

    	case COFLEX_VAR_TerminalSecondID:         
            Write("TerminalSecondID");
			break;

    	case COFLEX_VAR_Text:                     
            Write("Text");
			break;

    	case COFLEX_VAR_TransactionCount:         
            Write("TransactionCount");
			break;

    	case COFLEX_VAR_TransactionMax:           
            Write("TransactionMax");
			break;

    	case COFLEX_VAR_UnitID:                   
            Write("UnitID");
			break;

    	case COFLEX_VAR_ValidProducts:            
            Write("ValidProducts");
			break;

    	case COFLEX_VAR_WhiteListCount:           
            Write("WhiteListCount");
			break;

    	case COFLEX_VAR_WhiteListFlag:            
            Write("WhiteListFlag");
			break;

    	case COFLEX_VAR_WhiteListMax:             
            Write("WhiteListMax");
			break;

    	case COFLEX_VAR_Volume:                   
            Write("Volume");
			break;

    	case COFLEX_VAR_RouterExternal:           
            Write("RouterExternal");
			break;

    	case COFLEX_VAR_TerminalName:             
            Write("TerminalName");
			break;

    	case COFLEX_VAR_ReceiptHeader:            
            Write("ReceiptHeader");
			break;

    	case COFLEX_VAR_ReceiptFooter:            
            Write("ReceiptFooter");
			break;

    	case COFLEX_VAR_CurrentTime:              
            Write("CurrentTime");
			break;

    	case COFLEX_VAR_ProgramName:              
            Write("ProgramName");
			break;

    	case COFLEX_VAR_ProgramVersion:           
            Write("ProgramVersion");
			break;

    	case COFLEX_VAR_Info:                     
            Write("Info");
			break;

    	case COFLEX_VAR_RouterID:                 
            Write("RouterID");
			break;

    	case COFLEX_VAR_ReceiptPort:              
            Write("ReceiptPort");
			break;

    	case COFLEX_VAR_UseMeterReading:          
            Write("UseMeterReading");
			break;

        case COFLEX_VAR_UsePin:
            Write("UsePIN");
            break;

    	case COFLEX_VAR_PumpOpen:                 
            Write("PumpOpen");
			break;

    	case COFLEX_VAR_PumpZeroFill:             
            Write("PumpZeroFill");
			break;

    	case COFLEX_VAR_PumpPulseError:           
            Write("PumpPulseError");
			break;

    	case COFLEX_VAR_LastAccess:               
            Write("LastAccess");
			break;

    	case COFLEX_VAR_ID:                       
            Write("ID");
			break;

    	case COFLEX_VAR_PumpName:                 
            Write("PumpName");
			break;

    	case COFLEX_VAR_Result:                   
            Write("Result");
			break;

    	case COFLEX_VAR_Installed:                
            Write("Installed");
			break;

    	case COFLEX_VAR_Open:                     
            Write("Open");
			break;

		case COFLEX_VAR_Online:
            Write("OnLine");
			break;

    	case COFLEX_VAR_Busy:                     
            Write("Busy");
			break;

    	case COFLEX_VAR_SendDisplayInfo:          
            Write("SendDisplayInfo");
			break;

    	case COFLEX_VAR_DisplayTimeout:           
            Write("DisplayTimeout");
			break;

    	case COFLEX_VAR_DisplayInterval:          
            Write("DisplayInterval");
			break;

    	case COFLEX_VAR_DisplayWidth:             
            Write("DisplayWidth");
			break;

    	case COFLEX_VAR_DisplayHeight:            
            Write("DisplayHeight");
			break;

    	case COFLEX_VAR_FontType:                 
            Write("FontType");
			break;

    	case COFLEX_VAR_CoordX:                   
            Write("CoordX");
			break;

    	case COFLEX_VAR_CoordY:                   
            Write("CoordY");
			break;

    	case COFLEX_VAR_DisplayText:              
            Write("DisplayText");
			break;

    	case COFLEX_VAR_Reversed:                 
            Write("Reversed");
			break;

    	case COFLEX_VAR_Width:                    
            Write("Width");
			break;

    	case COFLEX_VAR_Height:                   
            Write("Height");
			break;

    	case COFLEX_VAR_PictureType:              
            Write("PictureType");
			break;

    	case COFLEX_VAR_EnterTime:                
            Write("EnterTime");
			break;

    	case COFLEX_VAR_TerminalVersion:          
            Write("TerminalVersion");
			break;

    	case COFLEX_VAR_WorkTimeout:              
            Write("WorkTimeout");
			break;

    	case COFLEX_VAR_WorkInterval:             
            Write("WorkInterval");
			break;

    	case COFLEX_VAR_WorkEnabled:              
            Write("WorkEnabled");
			break;

    	case COFLEX_VAR_Currency:                 
            Write("Currency");
			break;

    	case COFLEX_VAR_Value:                    
            Write("Value");
			break;

    	case COFLEX_VAR_CurrencyRate:             
            Write("CurrencyRate");
			break;

    	case COFLEX_VAR_Input:                    
            Write("Input");
			break;

    	case COFLEX_VAR_NoteInput:                
            Write("NoteInput");
			break;

    	case COFLEX_VAR_ResetTerminal:            
            Write("ResetTerminal");
			break;

    	case COFLEX_VAR_SystemMenu:               
            Write("SystemMenu");
			break;

    	case COFLEX_VAR_PollInterval:             
            Write("PollInterval");
			break;

    	case COFLEX_VAR_WorkIndex:                
            Write("WorkIndex");
			break;

    	case COFLEX_VAR_GroupID:                
            Write("GroupID");
			break;

    	case COFLEX_VAR_UseInOfflineMode:                
            Write("UseInOfflineMode");
			break;

    	case COFLEX_VAR_OfflineMaxAmount:                
            Write("OfflineMaxAmount");
			break;

    	case COFLEX_VAR_OfflineMaxVolume:                
            Write("OfflineMaxVolume");
			break;

    	case COFLEX_VAR_OfflineMaxFillings:                
            Write("OfflineMaxFillings");
			break;

    	case COFLEX_VAR_PinOff:                
            Write("PinOff");
			break;

    	case COFLEX_VAR_PinDefault:                
            Write("PinDefault");
			break;

    	case COFLEX_VAR_ForeignLayout:                
            Write("ForeignLayout");
			break;

    	case COFLEX_VAR_OfflineListType:                
            Write("OfflineListType");
			break;

    	case COFLEX_VAR_Blacked:                
            Write("Blacked");
			break;

    	case COFLEX_VAR_BlackDate:                
            Write("BlackDate");
			break;

    	case COFLEX_VAR_InstallGroup:                
            Write("InstallGroup");
			break;

    	case COFLEX_VAR_InstallLayout:                
            Write("InstallLayout");
			break;

    	case COFLEX_VAR_InstallCard:                
            Write("InstallCard");
			break;

    	case COFLEX_VAR_InstallCustomer:                
            Write("InstallCustomer");
			break;

    	case COFLEX_VAR_InstallGroupDone:                
            Write("InstallGroupDone");
			break;

    	case COFLEX_VAR_InstallLayoutDone:                
            Write("InstallLayoutDone");
			break;

    	case COFLEX_VAR_InstallCardDone:                
            Write("InstallCardDone");
			break;

    	case COFLEX_VAR_InstallCustomerDone:                
            Write("InstallCustomerDone");
			break;

    	case COFLEX_VAR_SenderID:                
            Write("SenderID");
			break;

    	case COFLEX_VAR_SenderType:                
            Write("SenderType");
			break;

    	case COFLEX_VAR_ApplicationType:                
            Write("ApplicationType");
			break;

    	case COFLEX_VAR_ApplicationId:                
            Write("ApplicationId");
			break;

    	case COFLEX_VAR_ApplicationName:                
            Write("ApplicationName");
			break;

    	case COFLEX_VAR_ApplicationVersion:                
            Write("ApplicationVersion");
			break;

    	case COFLEX_VAR_FirstAccess:
            Write("FirstAccess");
			break;

    	case COFLEX_VAR_ConnectedFlexWorkers:
            Write("ConnectedFlexWorkers");
			break;

    	case COFLEX_VAR_FlashTerminal:
            Write("FlashTerminal");
			break;

    	case COFLEX_VAR_InstallationStart:
            Write("InstallationStart");
			break;

		case COFLEX_VAR_InstallationDone:
			Write("InstallationDone");
			break;

		case COFLEX_VAR_AuxInputDefault:
			Write("AuxInputDefault");
			break;

		case COFLEX_VAR_UseAsWhiteList:
			Write("UseAsWhiteList");
			break;

		case COFLEX_VAR_AuxInputID:
			Write("AuxInputID");
			break;

		case COFLEX_VAR_MinChar:
			Write("MinChar");
			break;

		case COFLEX_VAR_MaxChar:
			Write("MaxChar");
			break;

		case COFLEX_VAR_AllowNulls:
			Write("AllowNulls");
			break;

		case COFLEX_VAR_Validate:
			Write("Validate");
			break;

		case COFLEX_VAR_CrcType:
			Write("CrcType");
			break;

		case COFLEX_VAR_PreviousMeterReading:
			Write("PreviousMeterReading");
			break;

		case COFLEX_VAR_Row:
			Write("Row");
			break;

		case COFLEX_VAR_Column:
			Write("Column");
			break;

		case COFLEX_VAR_SwitchConnection:
			Write("SwitchConnection");
			break;

		case COFLEX_VAR_UseAlternativeIP:
			Write("UseAlternativeIP");
			break;

		default:
			sprintf(str, "<Unknown Variable (%d)>", var->GetID());
			Write(str);
			break;
	}
}

/*##################  TCotexProtocolAnalyser::WriteResult ##########################
*   Purpose....: Write result	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::WriteResult(TCotexVar *var)
{
    switch (var->GetUnsigned32())
    {
        case COFLEX_RESULT_OK:
            Write("OK");
            break;

        case COFLEX_RESULT_UNKNOWN_ERROR:
            Write("Unknown error");
            break;

        case COFLEX_RESULT_UNKNOWN_TERMINAL:
            Write("Unknown terminal");
            break;

        case COFLEX_RESULT_VARIABLE_MISSING:
            Write("Variable missing");
            break;

        case COFLEX_RESULT_UNKNOWN_CARD:
            Write("Unknown card");
            break;

        case COFLEX_RESULT_CARD_EXPIRED:
            Write("Card expired");
            break;

        case COFLEX_RESULT_NO_CUSTOMER:
            Write("No customer");
            break;

        case COFLEX_RESULT_CARD_BLACKED:
            Write("Card blacked");
            break;

        case COFLEX_RESULT_CARD_STOLEN:
            Write("Card stolen");
            break;

        case COFLEX_RESULT_CUSTOMER_BLACKED:
            Write("Customer blacked");
            break;

        case COFLEX_RESULT_AMOUNT_EXCEEDED:
            Write("Amount exceeded");
			break;

        case COFLEX_RESULT_HOST_ERROR:
            Write("Host error");
            break;

        case COFLEX_RESULT_UNKNOWN_PRODUCT:
            Write("Unknown product");
            break;

        case COFLEX_RESULT_MULTIPLE_CARDS:
            Write("Multiple cards");
            break;

        case COFLEX_RESULT_PARAMETER_ERROR:
            Write("Parameter error");
            break;

        default:
            WriteVarData(var);
            break;
    }
}

/*##################  TCotexProtocolAnalyser::WriteTagName ##########################
*   Purpose....: Write tag name	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::WriteTagName(TCotexTag *tag)
{
    char str[80];
    
    switch (tag->GetID())
    {
        case COFLEX_TAG_HEADER:
            Write("<Header>");
            break;

        case COFLEX_TAG_INFO_REQ:
            Write("<Info Req>");
            break;

        case COFLEX_TAG_INFO_ACK:
			Write("<Info Ack>");
            break;
            
        case COFLEX_TAG_PARAMS_REQ:
            Write("<Params Req>");
            break;

        case COFLEX_TAG_PARAMS_ACK:
            Write("<Params Ack>");
            break;

        case COFLEX_TAG_TERMINAL:
            Write("<Terminal>");
            break;
            
        case COFLEX_TAG_LAYOUT:
            Write("<Layout>");
            break;
            
        case COFLEX_TAG_CARDTYPE:
            Write("<CardType>");
            break;
            
		case COFLEX_TAG_PRODUCTTYPE:
            Write("<ProductType>");
            break;
    
		case COFLEX_TAG_PRODUCT:
		    Write("<Product>");
            break;
    
		case COFLEX_TAG_PUMP:
	        Write("<Pump>");
            break;
    
		case COFLEX_TAG_SEQUENCENUMBERS:     
		    Write("<SequenceNumbers>");
            break;
    
		case COFLEX_TAG_CONFIGURATION:        
		    Write("<Configuration>");
            break;
    
		case COFLEX_TAG_TERMINALINFO:         
		    Write("<TerminalInfo>");
            break;

		case COFLEX_TAG_RECEIPT:               
		    Write("<Receipt>");
            break;
    
		case COFLEX_TAG_NOTEREADER:            
		    Write("<NoteReader>");
            break;
    
		case COFLEX_TAG_BARREADER:            
		    Write("<BarReader>");
            break;
    
		case COFLEX_TAG_CARDREADER:            
		    Write("<CardReader>");
            break;
    
		case COFLEX_TAG_KEYBOARD:              
		    Write("<Keyboard>");
            break;
    
		case COFLEX_TAG_PRICE:                 
		    Write("<Price>");
			break;
    
		case COFLEX_TAG_CARDVALIDATE_REQ:      
		    Write("<CardValidate Req>");
            break;
    
		case COFLEX_TAG_CARDVALIDATE_ACK:      
		    Write("<CardValidate Ack>");
            break;
    
		case COFLEX_TAG_PINENTERED_REQ:
		    Write("<PinEntered Req>");
            break;
    
		case COFLEX_TAG_PINENTERED_ACK:        
		    Write("<PinEntered Ack>");
            break;
    
		case COFLEX_TAG_FILL_REQ:              
		    Write("<Fill Req>");
            break;
    
		case COFLEX_TAG_FILL_ACK:              
			Write("<Fill Ack>");
            break;
    
		case COFLEX_TAG_CARD_1:                
		    Write("<Card 1>");
            break;
    
		case COFLEX_TAG_CARD_2:               
		    Write("<Card 2>");
            break;
    
		case COFLEX_TAG_REMOTECONTROL_REQ:     
		    Write("<RemoteControl Req>");
            break;
    
		case COFLEX_TAG_REMOTECONTROL_ACK:     
		    Write("<RemoteControl Ack>");
            break;
    
		case COFLEX_TAG_LINE:                 
		    Write("<Line>");
            break;
    
		case COFLEX_TAG_DISPLAY:
	        Write("<Display>");
            break;
    
		case COFLEX_TAG_TEXT:                 
		    Write("<Text>");
            break;
    
		case COFLEX_TAG_PICTURE:               
		    Write("<Picture>");
            break;
    
		case COFLEX_TAG_WORKMESSAGE:          
		    Write("<WorkMessage>");
            break;
    
		case COFLEX_TAG_WORK:                 
		    Write("<Work>");
            break;
    
		case COFLEX_TAG_CURRENCY:            
	        Write("<Currency>");
            break;

		case COFLEX_TAG_COMMAND_REQ:          
		    Write("<Command Req>");
            break;
    
		case COFLEX_TAG_COMMAND_ACK:          
		    Write("<Command Ack>");
            break;
    
		case COFLEX_TAG_NOTE:                  
		    Write("<Note>");
            break;
    
		case COFLEX_TAG_ADDGROUP_REQ:                  
		    Write("<AddGroup Req>");
            break;

		case COFLEX_TAG_ADDGROUP_ACK:                  
		    Write("<AddGroup Ack>");
            break;
    
		case COFLEX_TAG_DELETEGROUP_REQ:                  
		    Write("<DeleteGroup Req>");
			break;

		case COFLEX_TAG_DELETEGROUP_ACK:                  
		    Write("<DeleteGroup Ack>");
            break;
    
		case COFLEX_TAG_ADDLAYOUT_REQ:                  
		    Write("<AddLayout Req>");
            break;

		case COFLEX_TAG_ADDLAYOUT_ACK:                  
		    Write("<AddLayout Ack>");
            break;
    
		case COFLEX_TAG_DELETELAYOUT_REQ:                  
		    Write("<DeleteLayout Req>");
            break;

		case COFLEX_TAG_DELETELAYOUT_ACK:                  
		    Write("<DeleteLayout Ack>");
            break;
    
		case COFLEX_TAG_GROUP:                  
			Write("<Group>");
            break;
    
		case COFLEX_TAG_ADDCARD_REQ:                  
		    Write("<AddCard Req>");
            break;

		case COFLEX_TAG_ADDCARD_ACK:                  
		    Write("<AddCard Ack>");
            break;
    
		case COFLEX_TAG_DELETECARD_REQ:                  
		    Write("<DeleteCard Req>");
            break;

		case COFLEX_TAG_DELETECARD_ACK:                  
		    Write("<DeleteCard Ack>");
            break;
    
		case COFLEX_TAG_CARD:                  
		    Write("<Card>");
            break;
    
		case COFLEX_TAG_ADDCUSTOMER_REQ:
		    Write("<AddCustomer Req>");
            break;

		case COFLEX_TAG_ADDCUSTOMER_ACK:                  
		    Write("<AddCustomer Ack>");
            break;
    
		case COFLEX_TAG_DELETECUSTOMER_REQ:                  
		    Write("<DeleteCustomer Req>");
            break;

		case COFLEX_TAG_DELETECUSTOMER_ACK:                  
		    Write("<DeleteCustomer Ack>");
			break;

		case COFLEX_TAG_CUSTOMER:
			Write("<Customer>");
			break;

		case COFLEX_TAG_AUXVALIDATE_REQ:
			Write("<AuxValidate Req>");
			break;

		case COFLEX_TAG_AUXVALIDATE_ACK:
			Write("<AuxValidate Ack>");
			break;

		case COFLEX_TAG_AUXINPUT:
			Write("<AuxInput>");
			break;

		case COFLEX_TAG_INSTALLLAYOUT:
			Write("<InstallLayout>");
			break;

		case COFLEX_TAG_INSTALLCARD:
			Write("<InstallCard>");
			break;

		case COFLEX_TAG_INSTALLCUSTOMER:
			Write("<InstallCustomer>");
			break;

		case COFLEX_TAG_INSTALL_REQ:
			Write("<Install Req>");
			break;

		case COFLEX_TAG_INSTALL_ACK:
			Write("<Install Ack>");
			break;

		default:
			sprintf(str, "<Unknown Tag (%d)>", tag->GetID());
			Write(str);
			break;
	}
}

/*##################  TCotexProtocolAnalyser::ShowCotexVar ##########################
*   Purpose....: Show Cotex var	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::ShowCotexVar(TCotexVar *var, int level)
{
    int i;

    for (i = 0; i < level; i++)
		Write("  ");

	WriteVarName(var);
	Write("=");

	if (var->GetID() == COFLEX_VAR_Result)
		WriteResult(var);
	else
		WriteVarData(var);

//	Write(" (");
//	WriteVarType(var);
//  Write")");
	Write("\r\n");
}

/*##################  TCotexProtocolAnalyser::ShowCotexTag ##########################
*   Purpose....: Show Cotex tag	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::ShowCotexTag(TCotexTag *RootTag, int level)
{
	int i;
	TCotexTag *tag;
	TCotexVar *var;

	for (i = 0; i < level; i++)
		Write("  ");

	WriteTagName(RootTag);
	Write("\r\n");

	tag = RootTag->GotoFirstTag();
	while (tag)
	{
		ShowCotexTag(tag, level + 1);
		tag = RootTag->GotoNextTag();
	}

	var = RootTag->GotoFirstVar();
	while (var)
	{
		ShowCotexVar(var, level + 1);
		var = RootTag->GotoNextVar();
	}
}

/*##################  TCotexProtocolAnalyser::ShowCotex ##########################
*   Purpose....: Show Cotex msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::ShowCotex(TCotex *doc)
{
	TCotexTag *tag;

	if (FTime)
		ShowLongTime(FTime);
	Write("\r\n");

	tag = doc->GotoFirstTag();
	while (tag)
	{
		ShowCotexTag(tag, 0);
		tag = doc->GotoNextTag();
	}
}

/*##################  TCotexProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show Cotex msg	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TCotexProtocolAnalyser::ShowMsg()
{
	TCotex doc;

    if (doc.Parse(FMsg, FSize + 8))
        ShowCotex(&doc);
	else
	{
		if (FTime)
			ShowLongTime(FTime);
		ShowMneMsg();
	}
}

/*##################  TCotexProtocolAnalyser::TCotexProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCotexProtocolAnalyser::TCotexProtocolAnalyser(const char *MemMapName, int MaxSize)
  : TProtocolAnalyser(MemMapName, MaxSize)
{
}

/*##################  TCotexProtocolAnalyser::~TCotexProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TCotexProtocolAnalyser::~TCotexProtocolAnalyser()
{
}
