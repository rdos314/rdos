/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
TCommand *TTimeFactory::Create(const char *param)
{
	return new TTimeCommand(param);
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
TTimeCommand::TTimeCommand(const char *param)
  : TTimeDateCommand(param)
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

	FTime = TDateTime(year, month, day, hour, min, sec, 10 * hsec);

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

