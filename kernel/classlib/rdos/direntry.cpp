/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# direntry.cpp
# Directory entry class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include "direntry.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry(const TPathName &LPathName, const TString &LEntryName, const TDateTime &LTime, long LFileSize, int LAttribute)
  : PathName(LPathName),
    EntryName(LEntryName),
	Time(LTime)
{
    FileSize = LFileSize;
    Attribute = LAttribute;
    Valid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry()
  : PathName("")
{
    FileSize = 0;
    Attribute = -1;
	Valid = FALSE;
}

/*##########################################################################
#
#   Name       : TDirEntry::~TDirEntry
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::~TDirEntry()
{
}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir()
  : FPathName("")
{
    Init();
}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir(const char *PathName)
  : FPathName(PathName)
{
    Init();
}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir(const TString &PathName)
  : FPathName(PathName)
{
    Init();
}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir(const TPathName &PathName)
  : FPathName(PathName.Get())
{
    Init();
}

/*##########################################################################
#
#   Name       : TDir::Init
#
#   Purpose....: Init class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDir::Init()
{
	if (FPathName.IsDir())
	{
		FBaseString = FPathName.Get();
		FSearchString = "*";
	}
	else
	{
		FBaseString = FPathName.GetBaseName();
		FSearchString = FPathName.GetEntryName();

		if (FBaseString.GetSize() == 0)
			FBaseString = ".";

		if (FSearchString.GetSize() == 0)
			FSearchString = "*";
	}

	FDirHandle = RdosOpenDir(FBaseString.GetData());
    FIndex = 0;
}

/*##########################################################################
#
#   Name       : TDir::~TDir
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::~TDir()
{
    if (FDirHandle)
        RdosCloseDir(FDirHandle);
}

/*##########################################################################
#
#   Name       : TDir::IsMatch
#
#   Purpose....: Check if file matches search criteria
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDir::IsMatch(const char *FileName)
{
	TString FileStr(FileName);
	TString SearchStr(FSearchString);
	const char *FilePtr;
	const char *SearchPtr;
	char ch;
	const char *LastFilePtr = 0;
	const char *LastSearchPtr = 0;

	FileStr.Upper();
	SearchStr.Upper();

	if (SearchStr.GetSize() == 0)
		return TRUE;

	FilePtr = FileStr.GetData();
	SearchPtr = SearchStr.GetData();

	if (!strcmp(SearchPtr, "*.*"))
		return TRUE;

	if (!strcmp(SearchPtr, "*."))
	{
		if (strchr(FilePtr, '.'))
			return FALSE;
		else
			return TRUE;
	}

	for (;;)
	{
		while (*SearchPtr && *FilePtr)
		{
			switch (*SearchPtr)
			{
				case '*':
					ch = *(SearchPtr + 1);
					if (ch)
					{
						if (ch == *FilePtr)
						{
							LastSearchPtr = SearchPtr;
							SearchPtr += 2;
							FilePtr++;
							LastFilePtr = FilePtr;
						}
						else
							FilePtr++;
					}
					else
						FilePtr++;
					break;
	
				case '?':
					SearchPtr++;
					FilePtr++;
					break;

				default:
					if (*SearchPtr == *FilePtr)
					{
						SearchPtr++;
						FilePtr++;
					}
					else
					{
						if (LastFilePtr)
						{
							FilePtr = LastFilePtr;
							SearchPtr = LastSearchPtr;
							LastFilePtr = 0;
							LastSearchPtr = 0;
						}
						else
							return FALSE;
					}
					break;
			}
		}

		if (*SearchPtr == 0 && *FilePtr == 0)
			return TRUE;
		else
		{
			if (*SearchPtr == '*' && *(SearchPtr+1) == 0)
				return TRUE;

			if (LastFilePtr)
			{
				FilePtr = LastFilePtr;
				SearchPtr = LastSearchPtr;
				LastFilePtr = 0;
				LastSearchPtr = 0;
			}
			else
				return FALSE;
		}
	}
}

/*##########################################################################
#
#   Name       : TDir::GotoFirst
#
#   Purpose....: Goto first entry & return entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry TDir::GotoFirst()
{
    if (FDirHandle)
    {
        FIndex = 0;
        return GotoNext();
    }
    else
        return TDirEntry();
}

/*##########################################################################
#
#   Name       : TDir::GotoNext
#
#   Purpose....: Goto next entry & return entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry TDir::GotoNext()
{
    char *Name;
    long FileSize;
    int Attrib;
	unsigned long msb;
	unsigned long lsb;
	int ok;
        
    if (FDirHandle)
    {
        Name = new char[512];

		ok = TRUE;
		while (ok)
		{
	        ok = RdosReadDir(FDirHandle, FIndex, 512, Name, &FileSize, &Attrib, &msb, &lsb);
			if (ok)
			{
        		FIndex++;
				if (IsMatch(Name))
				{
		            TString Entry(Name);
					TPathName Path(FBaseString);
					Path += Entry;
		            TDateTime Time(msb, lsb);
		            TDirEntry entry(Path, Entry, Time, FileSize, Attrib);
		            return entry;
				}
			}
        }
        delete Name;
       
        return TDirEntry();
    }
    else
        return TDirEntry();
}
