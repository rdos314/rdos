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

#define DEFAULT_ID  502

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
    FID = DEFAULT_ID;
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

	FID = ID;

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
		AllocBuffer(size + 1);

		size = RdosReadResource(FHandle, ID, FBuf, 256);
		*(FBuf+size) = 0;
	}
	else
	{
		sprintf(str, "Unknown msg ID %d", ID);
		size = strlen(str);
		AllocBuffer(size + 1);
		memcpy(FBuf, str, size);
		*(FBuf+size) = 0;

		FID = DEFAULT_ID;
	}
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
	FID = temp.FID;
}

/*##########################################################################
#
#   Name       : TLangString::Write
#
#   Purpose....: Write message to socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLangString::Write(TSocket *Socket)
{
	char str[5];

	sprintf(str, "%03d ", FID);

	Socket->Write(str);
	Socket->Write(GetData());
	Socket->Push();
}

