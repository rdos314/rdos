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

