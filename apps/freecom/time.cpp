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
# time.cpp
# Time command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "time.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTimeFactory::TTimeFactory
#
#   Purpose....: Constructor for TTimeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeFactory::TTimeFactory()
  : TCommandFactory("TIME")
{
}

/*##########################################################################
#
#   Name       : TTimeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TTimeFactory::Create(TSession *session, const char *param)
{
	return new TTimeCommand(session, param);
}

/*##########################################################################
#
#   Name       : TTimeCommand::TTimeCommand
#
#   Purpose....: Constructor for TTimeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeCommand::TTimeCommand(TSession *session, const char *param)
  : TTimeDateCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_TIME);
}

/*##########################################################################
#
#   Name       : TTimeCommand::ParseTime
#
#   Purpose....: Set time from ASCII
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTimeCommand::SetTime(const char *str)
{
	int year, month, day;
	int hour, min, sec, hsec;
	int pm;
	TDateTime time;
	int i;

	for (i = 0; i < 4; i++)
		FNumArr[i] = 0;

	str = ParseNum(str);

	if (!str)
		return FALSE;

	pm = 0;
	switch (toupper(*str))
	{
		case 'P':
			pm++;

		case 'A':
			pm++;

			if (toupper(str[1]) == 'M')
				str += 2;
			else
				if (memicmp(str + 1, ".M.", 3) == 0)
					str += 4;
	}

	str = LTrimsp(str);
	if (*str)
		return FALSE;

	switch (FNumCount)
	{
		case 0:
			return TRUE;

		case 1:
			return TRUE;

		default:
			break;
	}

	hour = FNumArr[0];
	min = FNumArr[1];
	sec = FNumArr[2];
	hsec = FNumArr[3];

	switch (pm)
	{
		case 2:
			if (hour != 12)
				hour += 12;
			break;

		case 1:
			if (hour == 12)
				hour = 0;
		break;
	}

	if (hour >= 24 || min >= 60 || sec >= 60 || hsec > 99)
		return FALSE;

	year = FTime.GetYear();
	month = FTime.GetMonth();
	day = FTime.GetDay();

	FTime = TDateTime(year, month, day, hour, min, sec, 10 * hsec, 0);
	FTime.Set();

	return TRUE;
}

/*##########################################################################
#
#   Name       : TTimeCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTimeCommand::Execute(char *param)
{
	char s[40];
	char time[40];

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (*param == 0)
	{
		sprintf(time, "%02d.%02d.%02d,%03d", 
				FTime.GetHour(), FTime.GetMin(),
				FTime.GetSec(), FTime.GetMilliSec());

		FMsg.printf(TEXT_MSG_CURRENT_TIME, time);
		Write(FMsg.GetData());
		param = 0;
	}

	for (;;)
	{
		if (param == 0)
		{
			if (FNoPrompt)
				return 0;

			FMsg.Load(TEXT_MSG_ENTER_TIME);
			Write(FMsg.GetData());

			if (!Read(s, sizeof(s)))
				return E_CBreak;

			param = s;
		}

		if (SetTime(param))
			break;

		FMsg.Load(TEXT_ERROR_INVALID_TIME);
		Write(FMsg.GetData());
		param = 0;
	}

	return 0;
}

