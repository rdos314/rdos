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
# anabase.cpp
# Protocol analysis base class 
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
//#include "rdos.h"
#include "anabase.h"
#include "datetime.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TProtocolAnalyser::Write ##########################
*   Purpose....: Write a string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::Write(const char *str)
{
	printf(str);
	if (FLogFile)
		FLogFile->Write(str, strlen(str));
}

/*##################  TProtocolAnalyser::ShowShortTime ##########################
*   Purpose....: Show short time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowShortTime(TDateTime *time)
{
    char str[80];
    
	sprintf(str, "%02d.%02d.%02d,%03d  ", 
	                    time->GetHour(), 
	                    time->GetMin(),
	                    time->GetSec(), 
	                    time->GetMilliSec());
	Write(str);
}

/*##################  TProtocolAnalyser::ShowLongTime ##########################
*   Purpose....: Show long time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowLongTime(TDateTime *time)
{
    char str[80];

	sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d,%03d  ", 
	                    time->GetYear(), 
	                    time->GetMonth(),
	                    time->GetDay(),
	                    time->GetHour(),
	                    time->GetMin(),
	                    time->GetSec(),
	                    time->GetMilliSec());
	Write(str);
}

/*##################  TProtocolAnalyser::GetMsg ##########################
*   Purpose....: Get next message	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TProtocolAnalyser::GetMsg()
{
	int Channel;
	int LastTime;
	int Elapsed;
	char ch;
	int count;
	char *str;
	TSerialDebug Debug;
	int Pos;

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

		if (!FTime)
		{
			FTime = new TDateTime(Debug.TimeMSB, Debug.TimeLSB);
			Channel = Debug.Channel;
			LastTime = Debug.TimeLSB;
		}

		ch = Debug.ch;

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
		*str = ch;
		str++;
		*str = 0;

	}

	return TRUE;
}

/*##################  TProtocolAnalyser::GetMsgTime ##########################
*   Purpose....: Get time of pending message	 		    	      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TDateTime TProtocolAnalyser::GetMsgTime()
{
    if (FTime)
        return *FTime;
    else
        return TDateTime();
}

/*##################  TProtocolAnalyser::ShowHexMsg ##########################
*   Purpose....: Show msg in hex  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowHexMsg()
{
	char tempstr[15];
	int i;
	char ch;
	char *str;

	str = FMsg;

	for (i = 0; i < FSize; i++)
	{
		ch = *str;
		sprintf(tempstr, "%04hX", ch);
		tempstr[0] = tempstr[2];
		tempstr[1] = tempstr[3];
		tempstr[2] = ' ';
		tempstr[3] = 0;
		Write(tempstr);
		str++;
	}
	Write("\r\n");
}

/*##################  TProtocolAnalyser::ShowMneMsg ##########################
*   Purpose....: Show msg in hex & ascii 	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowMneMsg()
{
	char tempstr[15];
	int i;
	char ch;
	char *str;

	str = FMsg;

	for (i = 0; i < FSize; i++)
	{
		ch = *str;
		if (ch >= 0x20)
		{
			sprintf(tempstr, "%c", ch);
			Write(tempstr);
		}
		else
		{
			sprintf(tempstr, "%04hX", ch);
			tempstr[0] = tempstr[2];
			tempstr[1] = tempstr[3];
			tempstr[2] = ' ';
			tempstr[3] = 0;
			Write(" <");
			Write(tempstr);
			Write("> ");
		}
		str++;
	}
	Write("\r\n");
}

/*##################  TProtocolAnalyser::ShowAsciiMsg ##########################
*   Purpose....: Show msg in ascii 	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowAsciiMsg()
{
    Write(FMsg);
	Write("\r\n");
}

/*##################  TProtocolAnalyser::ShowMsg ##########################
*   Purpose....: Show msg in ascii 	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowMsg()
{
    if (FTime)
        ShowLongTime(FTime);
    ShowHexMsg();
}

/*##################  TProtocolAnalyser::TProtocolAnalyser ##########################
*   Purpose....: Constructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TProtocolAnalyser::TProtocolAnalyser(TFile *RawFile, int MaxSize)
{
	FRawFile = RawFile;
	
	FLogFile = 0;
	FTime = 0;

	FMaxSize = MaxSize;
	FMsg = new char[MaxSize + 1];
}

/*##################  TProtocolAnalyser::~TProtocolAnalyser ##########################
*   Purpose....: Destructor         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TProtocolAnalyser::~TProtocolAnalyser()
{
    if (FLogFile)
        delete FLogFile;

	delete FMsg;

    if (FTime)
        delete FTime;

}

/*##################  TProtocolAnalyser::DefineLogFile ##########################
*   Purpose....: Define log file         	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::DefineLogFile(const char *LogFileName)
{
    FLogFile = new TFile(LogFileName, 0);
}
