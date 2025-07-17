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
