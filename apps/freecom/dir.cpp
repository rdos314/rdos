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
# dir.cpp
# Dir command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "dir.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/* Definitions for optO */
#define ORDER_BY_SIZE 2
#define ORDER_BY_DATE 4
#define ORDER_BY_NAME 8
#define ORDER_INVERSE 0x01
#define ORDER_BY_EXT 0x10
#define ORDER_DIRS_FIRST 0x20
#define ORDER_DIRS_LAST 0x40
#define ORDER_BY_MASK 0x1e
#define DEFAULT_SORT_ORDER "NG"

#define ATTR_DEFAULT FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_DIRECTORY
#define ATTR_ALL	0x37;

unsigned char FOptOdir;
char FOptOorderby[5];

/*##########################################################################
#
#   Name       : TDirFactory::TDirFactory
#
#   Purpose....: Constructor for TDirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirFactory::TDirFactory()
  : TCommandFactory("DIR")
{
}

/*##########################################################################
#
#   Name       : TDirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDirFactory::Create(const char *param)
{
	return new TDirCommand(param);
}

/*##########################################################################
#
#   Name       : TDirCommand::TDirCommand
#
#   Purpose....: Constructor for TDirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirCommand::TDirCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_DIR);
	FEntryArr = 0;
}

/*##########################################################################
#
#   Name       : TDirCommand::~TDirCommand
#
#   Purpose....: Destructor for TDirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirCommand::~TDirCommand()
{
	FreeEntryArr();
}

/*##########################################################################
#
#   Name       : TDirCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::InitOptions()
{
	FAttrMask = 0;
	FAttrMatch = 0;
	FAttrMay = ATTR_DEFAULT;

	FOptOdir = 0;
	FOptO = FALSE;
	FOptS = FALSE;
	FOptP = FALSE;
	FOptW = FALSE;
	FOptB = FALSE;
	FOptL = FALSE;
}

/*##########################################################################
#
#   Name       : TDirCommand::ScanAttr
#
#   Purpose....: Scan attribute option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::ScanAttr(const char *p)
{
	unsigned attr;

	FAttrMask = 0;
	FAttrMatch = 0;
	FAttrMay = ATTR_ALL;

	if (p && *p)
	{
		for (--p;;)
		{
			switch (toupper(*++p))
			{
				case 'R': 
					attr = FILE_ATTRIBUTE_READONLY;
					break;

				case 'A':
					attr = FILE_ATTRIBUTE_ARCHIVE;
					break;

				case 'D':
					attr = FILE_ATTRIBUTE_DIRECTORY;
					break;

				case 'H':
					attr = FILE_ATTRIBUTE_HIDDEN;
					break;

				case 'S':
					attr = FILE_ATTRIBUTE_SYSTEM;
					break;

				case 0:
					FAttrMay &= ~FAttrMask | FAttrMatch;
					return E_None;

				default:
					OptError(p);
					return E_Useage;
			}

			switch (p[-1])
			{
				case '-':
					FAttrMatch &= ~attr;
					break;

				default:
					FAttrMatch |= attr;
					break;

			}

			FAttrMask |= attr;
		}
	}
	return E_None;
}

/*##########################################################################
#
#   Name       : TDirCommand::ScanOrder
#
#   Purpose....: Scan order option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::ScanOrder(const char *p)
{
	int option;
	int i;
	int inverse;
	int changed;

	if (!p || !*p)
		p = DEFAULT_SORT_ORDER;

	memset(FOptOorderby, 0, sizeof(FOptOorderby));
	FOptOdir = 0;

	if (p && *p)
	{
		while (*p)
		{
			inverse = p[-1] == '-';
			changed = FALSE;

			switch (toupper(*p))
			{
				case '-':
					break;

				case 'S':
					changed = TRUE;
					option = ORDER_BY_SIZE;
					break;

				case 'D':
					changed = TRUE;
					option = ORDER_BY_DATE;
					break;

				case 'N':
					changed = TRUE;
					option = ORDER_BY_NAME;
					break;

				case 'E':
					changed = TRUE;
					option = ORDER_BY_EXT;
					break;

				case 'G':
					FOptOdir = inverse? ORDER_DIRS_LAST: ORDER_DIRS_FIRST;
					break;

				case 'U':
					memset(FOptOorderby, 0, sizeof(FOptOorderby));
					FOptOdir = 0;
					break;

				default:
					OptError(p);
					return E_Useage;
			}

			if (changed)
			{
				for (i = 0; i < sizeof(FOptOorderby); ++i)
				{
					if (FOptOorderby[i] == 0)
						break;

					if ((FOptOorderby[i] & ORDER_BY_MASK) == option)
						memcpy(FOptOorderby+i, FOptOorderby+i+1
							 , (sizeof(FOptOorderby)-1-i)*sizeof(FOptOorderby[0]));
				}
				FOptOorderby[i] = option | inverse;
			}
			p++;
		}
	}

	FOptO = FOptOorderby[0] | FOptOdir;
	return E_None;
}

/*##########################################################################
#
#   Name       : TDirCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch (ch)
	{
		case 'S': 
			return OptScanBool(optstr, bool, strarg, &FOptS);

		case 'P':
			return OptScanBool(optstr, bool, strarg, &FOptP);

		case 'W':
			return OptScanBool(optstr, bool, strarg, &FOptW);

		case 'B':
			return OptScanBool(optstr, bool, strarg, &FOptB);

		case 'O':
			if (!bool)
				return ScanOrder(strarg);
  			break;

		case 'A':
			if (!bool)
				return ScanAttr(strarg);
  			break;

		case 'L':
			return OptScanBool(optstr, bool, strarg, &FOptL);

		case 0:
			switch (*optstr)
			{
				case 'A':
				case 'a':
					if (!bool && strarg == 0)
						return ScanAttr(optstr + 1);
					break;

				case 'O':
				case 'o':
					if (!bool && strarg == 0)
						return ScanOrder(optstr + 1);
					break;
			}
	}  
	OptError(optstr);
  	return E_Useage;
}

/*##########################################################################
#
#   Name       : TDirCommand::CreateEntryArr
#
#   Purpose....: Create entry array from list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::CreateEntryArr()
{
	int count;
	TDirEntry *entry;
	TDirEntry *ptr;

	count = 0;
	entry = FFileList.GotoFirst();

	while (entry)
	{
		count++;
		entry = FFileList.GotoNext();
	}

	FreeEntryArr();

	if (count)
	{
		FEntryCount = count;
		FEntryArr = new TDirEntry*[count];

		count = 0;
		entry = FFileList.GotoFirst();

		while (entry)
		{
			FEntryArr[count] = entry;
			count++;
			entry = FFileList.GotoNext();
		}
	}
}

/*##########################################################################
#
#   Name       : TDirCommand::FreeEntryArr
#
#   Purpose....: Free entry array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::FreeEntryArr()
{
	if (FEntryArr)
		delete FEntryArr;

	FEntryArr = 0;
	FEntryCount = 0;
}

/*##########################################################################
#
#   Name       : Compare
#
#   Purpose....: Compare function for qsort
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int cdecl Compare(const void *e1, const void *e2)
{
	TDirEntry **tmp;
	TDirEntry *dir1;
	TDirEntry *dir2;
  	int opt;
	const char *x1;
	const char *x2;
	int rv;
    int i;
	int isdir1;
	int isdir2;

	tmp = (TDirEntry **)e1;
	dir1 = *tmp;

	tmp = (TDirEntry **)e2;
	dir2 = *tmp;

	isdir1 = dir1->Attribute & FILE_ATTRIBUTE_DIRECTORY;
	isdir2 = dir2->Attribute & FILE_ATTRIBUTE_DIRECTORY;

	if (FOptOdir && (isdir1 != isdir2))
	{
		if (FOptOdir & ORDER_DIRS_FIRST)
		{
			if (isdir1)
				return -1;

			if (isdir2)
				return 1;
		}
		else
		{
			if (isdir1)
				return 1;

			if (isdir2)
				return -1;
		}
	}

	rv = 0;  	         

	for (i = 0; rv == 0; i++)
	{
		opt = FOptOorderby[i];

		switch (opt & ORDER_BY_MASK)
		{
			case 0:
				return 0;

			case ORDER_BY_SIZE:
				if (dir1->FileSize > dir2->FileSize)
					rv = 1;

				if (dir1->FileSize < dir2->FileSize)
					rv = -1;
				break;

			case ORDER_BY_DATE:
				if (dir1->Time > dir2->Time)
					rv = 1;

				if (dir1->Time < dir2->Time)
					rv = -1;
				break;

			case ORDER_BY_EXT:
				x1 = strchr(dir1->EntryName.GetData(), '.');
				x2 = strchr(dir2->EntryName.GetData(), '.');

				if (x1 && x2)
					rv = strcmp(x1, x2);

				if (!x1 && x2)
					rv = -1;

				if (x1 && !x2)
					rv = 1;

				break;

			case ORDER_BY_NAME:
				rv = strcmp(dir1->EntryName.GetData(),dir2->EntryName.GetData());
				break;
		}
		if (opt & ORDER_INVERSE)
			rv = -rv;
	}
	return rv;
}

/*##########################################################################
#
#   Name       : TDirCommand::Sort
#
#   Purpose....: Sort entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::Sort()
{
	qsort(FEntryArr, FEntryCount, sizeof(TDirEntry *), Compare);
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteDetailed
#
#   Purpose....: Write detailed listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteDetailed(TDirEntry *entry)
{
	char str[31];
	int size;
	int i;

	size = entry->EntryName.GetSize();
	strncpy(str, entry->EntryName.GetData(), 30);

	for (i = size; i < 30; i++)
		str[i] = ' ';
	str[30] = 0;

	Write(str);

	if (entry->Attribute & FILE_ATTRIBUTE_DIRECTORY)
		Write("<DIR>         ");
	else
		WriteLong(entry->FileSize);

	Write("  ");
	
	sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d,%03d", 
					entry->Time.GetYear(), 
					entry->Time.GetMonth(), 
					entry->Time.GetDay(), 
					entry->Time.GetHour(), 
					entry->Time.GetMin(), 
					entry->Time.GetSec(), 
					entry->Time.GetMilliSec());
	Write(str);
	Write("\r\n");
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteDetailed
#
#   Purpose....: Write detailed listing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteDetailed()
{
	int i;

	for (i = 0; i < FEntryCount; i++)
	{
		WriteDetailed(FEntryArr[i]);
		if (FOptP && (i % 24 == 23))
		{
			FMsg.Load(TEXT_MSG_PAUSE);
			Write(FMsg.GetData());
			RdosReadKeyboard();
			Write("\r\n");
		}
	}
}

/*##########################################################################
#
#   Name       : TDirCommand::AddFiles
#
#   Purpose....: Add files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::AddFiles(TString &path)
{
	TDir *dir;
	TDirEntry entry;

	dir = new TDir(path);
	entry = dir->GotoFirst();
	while (entry.Valid)
	{
		if ((entry.Attribute & FAttrMask) == FAttrMatch)
			FFileList.Add(entry);
		entry = dir->GotoNext();
	}
	delete dir;
}

/*##########################################################################
#
#   Name       : TDirCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::Execute(char *param)
{
	TArg *arg;

	InitOptions();

	if (!ScanCmdLine(param, 0))
		return 1;

    arg = FArgList;

	if (arg)
	{
		while (arg)
		{
			AddFiles(arg->FName);
			arg = arg->FList;
		}
	}
	else
		AddFiles("*");

	CreateEntryArr();
	Sort();
	WriteDetailed();

	return 0;
}
