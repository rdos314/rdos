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
# date.cpp
# Date command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "date.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDateFactory::TDateFactory
#
#   Purpose....: Constructor for TDateFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateFactory::TDateFactory()
  : TCommandFactory("DATE")
{
}

/*##########################################################################
#
#   Name       : TDateFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDateFactory::Create(TSession *session, const char *param)
{
	return new TDateCommand(session, param);
}

/*##########################################################################
#
#   Name       : TDateCommand::TDateCommand
#
#   Purpose....: Constructor for TDateCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateCommand::TDateCommand(TSession *session, const char *param)
  : TTimeDateCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_DATE);
}

/*##########################################################################
#
#   Name       : TDateCommand::ParseDate
#
#   Purpose....: Set date from ASCII
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDateCommand::SetDate(const char *str)
{
	int year, month, day;
	int hour, min, sec, msec;
	TDateTime time;
	int i;

	for (i = 0; i < 4; i++)
		FNumArr[i] = 0;

	str = ParseNum(str);

	str = LTrimsp(str);
	if (*str)
		return FALSE;

	switch (FNumCount)
	{
		case 0:
			return TRUE;

		case 3:
			year = FNumArr[0];
			month = FNumArr[1];
			day = FNumArr[2];
			break;

		case 2:
			month = FNumArr[0];
			day = FNumArr[1];
			break;

		case 1:
			day = FNumArr[0];
			break;
	}

	if (year < 80)
		year += 2000;
	else
		if (year < 200)
			year += 1900;

	hour = FTime.GetHour();
	min = FTime.GetMin();
	sec = FTime.GetSec();
	msec = FTime.GetMilliSec();

	FTime = TDateTime(year, month, day, hour, min, sec, msec);
    FTime.Set();

	return TRUE;
}

/*##########################################################################
#
#   Name       : TDateCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDateCommand::Execute(char *param)
{
	char s[40];
	char date[40];

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (*param == 0)
	{
		sprintf(date, "%04d-%02d-%02d", 
				FTime.GetYear(), FTime.GetMonth(),
				FTime.GetDay());

		FMsg.printf(TEXT_MSG_CURRENT_DATE, date);
		Write(FMsg.GetData());
		param = 0;
	}

	for (;;)
	{
		if (param == 0)
		{
			if (FNoPrompt)
				return 0;

			FMsg.Load(TEXT_MSG_ENTER_DATE_JAPANESE);
			Write(FMsg.GetData());

			if (!Read(s, sizeof(s)))
				return E_CBreak;

			param = s;
		}

		if (SetDate(param))
			break;

		FMsg.Load(TEXT_ERROR_INVALID_DATE);
		Write(FMsg.GetData());
		param = 0;
	}

	return 0;
}

