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
    TPathName(const char *PathName);
    TPathName(const TString &PathName);
    TPathName(int Drive, const TString &PathName);
    TPathName(int Drive, const TString &DirName, const TString &EntryName);
    TPathName(const TPathName &PathName);
    ~TPathName();

	const TPathName &operator=(const TPathName &src);
	const TPathName &operator=(const TString &src);
	const TPathName &operator+=(const TString &src);

	TString Get() const;
	TString GetFullPathName() const;

private:
    TString FPathName;
};

class TDirEntry
{
public:
    TDirEntry();
    TDirEntry(const TPathName &PathName, const TString &EntryName, const TDateTime &Time, long FileSize, int Attribute);
    ~TDirEntry();
    
    TPathName PathName;
    TString EntryName;
    long FileSize;
    int Attribute;
    TDateTime Time;
    int Valid;
};

class TDir
{
public:
    TDir();
	TDir(const char *PathName);
	TDir(const TString &PathName);
	TDir(const TPathName &PathName);
	~TDir();

    TDirEntry GotoFirst();
    TDirEntry GotoNext();
    
protected:

private:
    void Init();

	int FDirHandle;
	TString FPathName;
    int FIndex;
	
};

#endif

