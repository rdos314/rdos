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
# httppars.cpp
# HTTP Parser base class
#
########################################################################*/

#include <string.h>

#include "httppars.h"
#include "httpserv.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : THttpParser::THttpParser
#
#   Purpose....: Constructor for parser
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpParser::THttpParser()
{
}

/*##########################################################################
#
#   Name       : THttpParser::~THttpParser
#
#   Purpose....: Destructor for parser
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpParser::~THttpParser()
{
}

/*##########################################################################
#
#   Name       : THttpParser::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpParser::IsArgDelim(char ch)
{
	return THttpSocketServer::IsArgDelim(ch);
}

/*##########################################################################
#
#   Name       : THttpParser::SkipWord
#
#   Purpose....: Skip to next word
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpParser::SkipWord(char *p)
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
#   Name       : THttpParser::SkipDelim
#
#   Purpose....: Skip to next delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpParser::SkipDelim(char *p)
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

