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
# tdcmd.cpp
# Time & date base command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "tdcmd.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTimeDateCommand::TTimeDateCommand
#
#   Purpose....: Constructor for TTimeDateCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTimeDateCommand::TTimeDateCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
}

/*##########################################################################
#
#   Name       : TTimeDateCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTimeDateCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch (ch)
	{
		case 'D':
		case 'T':
			return OptScanBool(optstr, bool, strarg, &FNoPrompt);

	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TTimeDateCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTimeDateCommand::InitOptions()
{
	FNoPrompt = 0;
	return TRUE;
}

/*##########################################################################
#
#   Name       : TTimeDateCommand::ParseNum
#
#   Purpose....: Parse numbers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TTimeDateCommand::ParseNum(const char *s)
{
	int n;

	FNumCount = 0;

	s = LTrimsp(s);

	while (isdigit(*s))
	{
		n = 0;
		do
		{
			if (n >= 10000)
				return 0;
			n = n * 10 + *s - '0';
			s++;
 		}
		while (isdigit(*s));

		FNumArr[FNumCount] = n;
		FNumCount++;

		if (!isascii(*s) || !ispunct(*s) || FNumCount == 4)
			break;
		s++;
	}
	return LTrimsp(s);
}
