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
# parse.cpp
# Parser base class
#
########################################################################*/

#include <string.h>

#include "ftpparse.h"
#include "ftpserv.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TParser::TParser
#
#   Purpose....: Constructor for parser
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TParser::TParser()
{
}

/*##########################################################################
#
#   Name       : TParser::~TParser
#
#   Purpose....: Destructor for parser
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TParser::~TParser()
{
}

/*##########################################################################
#
#   Name       : TParser::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TParser::IsArgDelim(char ch)
{
	return TFtpSocketServer::IsArgDelim(ch);
}

/*##########################################################################
#
#   Name       : TParser::SkipWord
#
#   Purpose....: Skip to next word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TParser::SkipWord(char *p)
{
	int ch, quote;
	int more;

	quote = 0;
	for (;;)
	{
		ch = *p;
		if (!ch)
			break;

		more = !IsArgDelim(ch);

		if (!quote && !more)
			break;

		if (quote == ch)
			quote = 0;
		else
			if (strchr("\"", ch))
				quote = ch;

		p++;
	}
	return p;
}

/*##########################################################################
#
#   Name       : TParser::SkipDelim
#
#   Purpose....: Skip to next delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TParser::SkipDelim(char *p)
{
	int ch, quote;
	int more;

	quote = 0;
	for (;;)
	{
		ch = *p;

		if (!ch)
			break;

		more = IsArgDelim(ch);

		if (!quote && !more)
			break;

		if (quote == ch)
			quote = 0;
		else
			if (strchr("\"", ch))
				quote = ch;
		p++;
	}
	return p;
}

