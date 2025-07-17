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
	TString::prtf(temp.GetData(), ap);
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
	TString::prtf(fmt, ap);
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
