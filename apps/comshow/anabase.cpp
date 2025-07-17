/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

/*##################  TProtocolAnalyser::ShowDiffTime ##########################
*   Purpose....: Show diff time string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowDiffTime(TDateTime *timelow, TDateTime *timehigh)
{
    char str[80];
    int sec;
    TDateTime time(0, timehigh->GetLsb() - timelow->GetLsb()); 

    sec = time.GetSec();
    sec += 60 * time.GetMin();

	sprintf(str, "%04d,%03d  ", sec, time.GetMilliSec());
	Write(str);
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
        unsigned long long LastTime;
        unsigned long long Elapsed;
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
                        FTime = new TDateTime((unsigned long long)Debug.Time);
			FChannel = Debug.Channel;
			LastTime = Debug.Time;
		}

		ch = Debug.ch;

		if (FChannel != Debug.Channel)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		Elapsed = Debug.Time - LastTime;
		if (Elapsed > 1193 * 100)
		{
			FRawFile->SetPos(Pos);
			return TRUE;
		}

		LastTime = Debug.Time;
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

/*##################  TProtocolAnalyser::ShowChannel ##########################
*   Purpose....: Show message channel  	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TProtocolAnalyser::ShowChannel(int Channel)
{
	char tempstr[15];

	sprintf(tempstr, "%2d ", Channel);
	Write(tempstr);
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
    ShowChannel(FChannel);
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
