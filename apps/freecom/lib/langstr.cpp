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
# langstr.cpp
# Language string class
#
########################################################################*/

#include <stdio.h>
#include <mem.h>
#include <string.h>
#include <stdarg.h>

#include "rdos.h"
#include "langstr.h"

#define FALSE 0
#define TRUE !FALSE

int TLangString::FHandle = 0;
int TLangString::FIsLocalHandle = TRUE;

/*##########################################################################
#
#   Name       : TLangString::TLangString
#
#   Purpose....: Constructor for language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLangString::TLangString()
{
}

/*##########################################################################
#
#   Name       : TLangString::TLangString
#
#   Purpose....: Constructor for language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLangString::TLangString(int ID)
{
	Load(ID);
}

/*##########################################################################
#
#   Name       : TLangString::SetLanguage
#
#   Purpose....: Set new language
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLangString::SetLanguage(const char *language)
{
	if (FHandle && !FIsLocalHandle)
	{
		RdosFreeDll(FHandle);
		FHandle = 0;
	}
	FHandle = RdosLoadDll(language);
	FIsLocalHandle = FALSE;
}

/*##########################################################################
#
#   Name       : TLangString::Load
#
#   Purpose....: Load language string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLangString::Load(int ID)
{
	char str[257];
	int start;
	int count;
	int i;
	int size;
	char *ptr;

	Release();

	start = 0;
	count = 0;

	if (FHandle == 0)
	{
		FIsLocalHandle = TRUE;
		FHandle = RdosGetModuleHandle();
	}

	if (FHandle)
	{
		size = RdosReadResource(FHandle, ID, str, 256);
		if (size)
		{
			str[size] = 0;
			if (sscanf(str, "%d,%d", &start, &count) != 2)
			{
				start = 0;
				count = 0;
			}
		}				
	}

	if (start && count)
	{
		size = 0;
		for (i = start; i < start + count; i++)
			size += RdosReadResource(FHandle, i, str, 256);

		AllocBuffer(size + 1);

		ptr = FBuf;
		for (i = start; i < start + count; i++)
		{
			size = RdosReadResource(FHandle, i, str, 256);
			if (size)
			{
				memcpy(ptr, str, size);
				ptr += size;
			}
		}
		*ptr = 0;
	}
	else
	{
		sprintf(str, "MESSAGE #%d", ID);
		size = strlen(str);
		AllocBuffer(size);
		memcpy(FBuf, str, size);
		*(FBuf+size) = 0;
	}

}

/*##########################################################################
#
#   Name       : TLangString::LoadMessage
#
#   Purpose....: Load language string without CR LF
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLangString::LoadMessage(int ID)
{
	Load(ID);
	RemoveCrLf();
}

/*##########################################################################
#
#   Name       : TLangString::printf
#
#   Purpose....: Load & printf on message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLangString::printf(int ID, ...)
{
	va_list ap;
	TLangString temp(ID);

	va_start(ap, ID);
	TString::printf(temp.GetData(), ap);
	va_end(ap);
}

/*##########################################################################
#
#   Name       : TLangString::GetPromptString
#
#   Purpose....: Get prompt string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TLangString::GetPromptString()
{
	if (FBuf)
		return FBuf;
	else
		return "";
}

/*##########################################################################
#
#   Name       : TLangString::GetFormatString
#
#   Purpose....: Get format string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TLangString::GetFormatString()
{
	if (FBuf)
		return FBuf + 2 * (*FBuf) + 1;
	else
		return "";
}

/*##########################################################################
#
#   Name       : TLangString::UserPrompt
#
#   Purpose....: Handle user prompt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TLangString::UserPrompt(int ID,...)
{
	va_list ap;
	TLangString temp(ID);
	const char *fmt, *str;
	const char *q;
	int ch;
	int row, col;

	fmt = temp.GetFormatString();
	str = temp.GetPromptString();

	va_start(ap, ID);
	TString::printf(fmt, ap);
	va_end(ap);

	RdosWriteString(GetData());
	RdosGetCursorPosition(&row, &col);

	for (;;)
	{
		ch = RdosReadKeyboard();
		RdosWriteChar(ch);

		q = (const char *)memchr(str + 1, ch, *str);

		if (q)
		{
			RdosWriteString("\r\n");
			return str[(q - str) + *str];
		}
		else
		{
			RdosSetCursorPosition(row, col);
			RdosWriteChar(' ');
			RdosSetCursorPosition(row, col);
		}
	}
}
