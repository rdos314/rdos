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
# dir.h
# Directory class
#
########################################################################*/

#ifndef _DIR_H
#define _DIR_H

#include "datetime.h"
#include "str.h"

class TPathName
{
public:
    TPathName(const TString &PathName);
    TPathName(int Drive, const TString &PathName);
    TPathName(int Drive, const TString &DirName, const TString &EntryName);
    TPathName(const TPathName &PathName);
    ~TPathName();

	const TPathName &operator=(const TPathName &src);
	const TPathName &operator=(const TString &src);
	const TPathName &operator+=(const TString &src);

	TString Get();
	TString GetFullPathName();

private:
    TString FPathName;
};

/*
class TDirEntry
{
public:
    TDirEntry();
    ~TDirEntry();

    TPathName PathName;
    long FileSize;
    int Attribute;
    TDateTime time;
};

class TDir
{
public:
	TDir(const TString &PathName);
	TDir(const TPathName &PathName);
	~TDir();

	const TString &GetFullPathName();
	int GetDrive();
	const TString &GetDirName();
	const TString &GetEntryName();

    int Exists();
	int MakeDir();
    int RemoveDir();
    int RenameFile(const char *ToEntry, const char *FromEntry);
    int DeleteFile(const char *FileName);
    int GetFileAttribute(const char *FileName, int *Attribute);
    int SetFileAttribute(const char *FileName, int Attribute);

    const TDirEntry &GotoFirst();
    const TDirEntry &GotoNext();
    
protected:

private:
	int FDirHandle;
	TPathName *FPathName;
	int FIsLocal;
};

*/

#endif

