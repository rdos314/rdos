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
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "dir.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

#define ATTR_DEFAULT FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_DIRECTORY
#define ATTR_ALL	0x37;

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

    FOptDirFirst = TRUE;
    FOptDirLast = FALSE;
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
    int attr;
	int Required = 0;
	int Ignored = 0;

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
				    Ignored |= attr;
					break;

				default:
				    Required |= attr;
					break;

			}
		}
	}

    FDirList.SetRequiredAttributes(Required);
    FFileList.SetRequiredAttributes(Required);
    FDirList.SetIgnoredAttributes(Ignored);
    FFileList.SetIgnoredAttributes(Ignored);
	
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

    FFileList.ClearSort();
    FDirList.ClearSort();

    FOptDirFirst = FALSE;
    FOptDirLast = FALSE;

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
				    if (inverse)
				    {
    				    FFileList.AddReverseSortBySize();
    				    FDirList.AddReverseSortBySize();
    				}
    				else
				    {
    				    FFileList.AddSortBySize();
    				    FDirList.AddSortBySize();
    				}
					break;

				case 'D':
				    if (inverse)
				    {
    				    FFileList.AddReverseSortByTime();
    				    FDirList.AddReverseSortByTime();
    				}
    				else
				    {
    				    FFileList.AddSortByTime();
    				    FDirList.AddSortByTime();
    				}
					break;

				case 'N':
				    if (inverse)
				    {
    				    FFileList.AddReverseSortByName();
    				    FDirList.AddReverseSortByName();
    				}
    				else
				    {
    				    FFileList.AddSortByName();
    				    FDirList.AddSortByName();
    				}
					break;

				case 'E':
				    if (inverse)
				    {
    				    FFileList.AddReverseSortByExt();
    				    FDirList.AddReverseSortByExt();
    				}
    				else
				    {
    				    FFileList.AddSortByExt();
    				    FDirList.AddSortByExt();
    				}
					break;

				case 'G':
				    if (inverse)
				    {
				        FOptDirLast = TRUE;
				        FOptDirFirst = FALSE;
				    }
				    else
				    {
				        FOptDirFirst = TRUE;
				        FOptDirLast = FALSE;
				    }
					break;

				case 'U':
                    FFileList.ClearSort();
                    FDirList.ClearSort();
                    FOptDirFirst = FALSE;
                    FOptDirLast = FALSE;
					break;

				default:
					OptError(p);
					return E_Useage;
			}
			p++;
		}
	}

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
#   Name       : TDirCommand::WriteDetailed
#
#   Purpose....: Write detailed listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteDetailed(TDirEntryData *entry)
{
	char str[31];
	int size;
	int i;

	size = entry->EntryName.GetSize();
	strncpy(str, entry->EntryName.GetData(), 30);

	if (size < 30)
	{
		str[size] = ' ';
		for (i = size + 1; i < 30; i++)
			str[i] = 'ú';
	}
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

	FCurrentRow++;

	if (FOptP && (FCurrentRow == 23))
	{
	    FCurrentRow = 0;
		FMsg.Load(TEXT_MSG_PAUSE);
		Write(FMsg.GetData());
		RdosReadKeyboard();
		Write("\r\n");
	}

}

/*##########################################################################
#
#   Name       : TDirCommand::WriteWide
#
#   Purpose....: Write wide listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteWide(TDirEntryData *entry)
{
	int size;
	int i;

	if (FCurrentCol + FWidth >= 80)
	{
		FCurrentRow++;
		FCurrentCol = 0;
		Write("\r\n");
	}

	if (entry->Attribute & FILE_ATTRIBUTE_DIRECTORY)
	{
		size = entry->EntryName.GetSize() + 3;
		Write("[");
		Write(entry->EntryName.GetData());
		Write("] ");
	}
	else
	{
		size = entry->EntryName.GetSize() + 1;
		Write(entry->EntryName.GetData());
		Write(" ");
	}

	for (i = size; i < FWidth; i++)
		Write(" ");

	FCurrentCol += FWidth;

	if (FOptP && FCurrentCol == 0 && FCurrentRow == 23)
	{
	    FCurrentRow = 0;
		FMsg.Load(TEXT_MSG_PAUSE);
		Write(FMsg.GetData());
		RdosReadKeyboard();
		Write("\r\n");
	}
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
	int ok;

	FCurrentRow = 0;

    if (FOptDirFirst)
    {
        ok = FDirList.GotoFirst();
        while (ok)        
        {
            WriteDetailed(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }

    ok = FFileList.GotoFirst();
    while (ok)       
    {
        WriteDetailed(FFileList.Get().Get());
        ok = FFileList.GotoNext();
    }

    if (FOptDirLast)
    {
        ok = FDirList.GotoFirst();
        while (ok)        
        {
            WriteDetailed(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteWide
#
#   Purpose....: Write wide listing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteWide()
{
	int i;
	int size;
	int ok;

	FCurrentRow = 0;
	FCurrentCol = 0;
	FWidth = 1;

    ok = FDirList.GotoFirst();
    while (ok)        
    {
        size = FDirList.Get().GetEntryName.GetSize();
	    size += 2;

		if (size > FWidth)
			FWidth = size;
			
        ok = FDirList.GotoNext();
	}

    ok = FFileList.GotoFirst();
    while (ok)        
    {
        size = FFileList.Get().GetEntryName.GetSize();
        if (FFileList.Get().GetAttrib() & FILE_ATTRIBUTE_DIRECTORY)
			size += 2;

		if (size > FWidth)
			FWidth = size;
			
        ok = FFileList.GotoNext();
	}

	FWidth += 2;

    if (FOptDirFirst)
    {
        ok = FDirList.GotoFirst();
        while (ok)        
        {
            WriteWide(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }

    ok = FFileList.GotoFirst();
    while (ok)       
    {
        WriteWide(FFileList.Get().Get());
        ok = FFileList.GotoNext();
    }

    if (FOptDirLast)
    {
        ok = FDirList.GotoFirst();
        while (ok)        
        {
            WriteWide(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }	
}

/*##########################################################################
#
#   Name       : TDirCommand::Add
#
#   Purpose....: Add files for argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::Add(TString &path)
{
    if (FOptDirLast || FOptDirFirst)
    {
    	FDirList.Add(path);
    	FFileList.Add(path);
    }
    else
    	FFileList.Add(path);
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

    if (FOptDirFirst || FOptDirLast)
    {
    }
    
	if (arg)
	{
		while (arg)
		{
			Add(arg->FName);
			arg = arg->FList;
		}
	}
	else
		Add("*");

    
	Sort();

	if (FOptW)
		WriteWide();
	else
		WriteDetailed();

	return 0;
}
