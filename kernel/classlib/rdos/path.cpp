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
# path.cpp
# Directory class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include "path.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const char *PathName)
  : FPathName(PathName)
{
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const TString &PathName)
  : FPathName(PathName)
{
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(int Drive, const TString &PathName)
  : FPathName(((char)Drive + 'a') + ":" + PathName)
{
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(int Drive, const TString &DirName, const TString &EntryName)
  : FPathName(((char)Drive + 'a') + ":" + DirName + "\\" + EntryName)
{
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: Copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const TPathName &PathName)
  : FPathName(PathName.FPathName)
{
}

/*##########################################################################
#
#   Name       : TPathName::~TPathName
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::~TPathName()
{
}

/*##########################################################################
#
#   Name       : TPathName::operator=
#
#   Purpose....: Assignment 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator=(const TPathName &src)
{
	FPathName = src.FPathName;
	return *this;
}

/*##########################################################################
#
#   Name       : TPathName::operator=
#
#   Purpose....: Assignment 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator=(const TString &src)
{
	FPathName = src;
	return *this;
}

/*##########################################################################
#
#   Name       : TPathName::operator+=
#
#   Purpose....: Assignment addition 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator+=(const TString &src)
{
	FPathName += src;
    return *this;
}

/*##########################################################################
#
#   Name       : TPathName::Get
#
#   Purpose....: Get path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::Get() const
{
	return FPathName;
}

/*##########################################################################
#
#   Name       : TPathName::GetFullPathName
#
#   Purpose....: Get full path name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::GetFullPathName() const
{
	TString s;
	const char *str;
	char *path;
	int drive;
	char drive_str[3];
	int size;
	int add;
	
	size = FPathName.GetSize();

	if (size <= 2)
		add = TRUE;
	else
	{
		str = FPathName.GetData();
		if (*(str+1) == ':')
			add = FALSE;
		else
			add = TRUE;
	}		

	if (add)
	{
		drive_str[0] = (char)RdosGetCurDrive() + 'a';
		drive_str[1] = ':';
		drive_str[2] = 0;
		s = drive_str + FPathName;
	}
	else
		s = FPathName;

	size = s.GetSize();

	if (size <= 2)
		add = TRUE;
	else
	{
		str = s.GetData();
		if (*(str+2) == '\\')
			add = FALSE;
		else
			add = TRUE;
	}

	if (add)
	{
		str = s.GetData();
		memcpy(drive_str, str, 2);
		drive_str[2] = 0;
		drive_str[0] = tolower(drive_str[0]);
		str += 2;

		path = new char[0x200];
		drive = drive_str[0] - 'a';
		RdosGetCurDir(drive, path);
		s = TString(drive_str) + "\\" + path + "\\" + str;
		delete path;
	}
	return s;
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
	FDirHandle = RdosOpenDir(FPathName.GetData());
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
    long msb;
    long lsb;
        
    if (FDirHandle)
    {
        Name = new char[512];
        if (RdosReadDir(FDirHandle, FIndex, 512, Name, &FileSize, &Attrib, &msb, &lsb))
        {
            TString Entry(Name);
            TPathName Path(FPathName + "\\" + Entry);
            TDateTime Time(msb, lsb);
            TDirEntry entry(Path, Entry, Time, FileSize, Attrib);
            FIndex++;
            return entry;
        }
        delete Name;
       
        return TDirEntry();
    }
    else
        return TDirEntry();
}
