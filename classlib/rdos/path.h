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
# path.h
# Directory class
#
########################################################################*/

#ifndef _PATH_H
#define _PATH_H

#include "datetime.h"
#include "str.h"

class TDirList;
class TFile;

class TPathName
{
public:
	TPathName();
	TPathName(int Drive);
	TPathName(const char *PathName);
	TPathName(const TString &PathName);
	TPathName(int Drive, const TString &PathName);
	TPathName(int Drive, const TString &DirName, const TString &EntryName);
	TPathName(const TPathName &PathName);
	~TPathName();

	const TPathName &operator=(const TPathName &src);
	const TPathName &operator=(const TString &src);
	const TPathName &operator+=(const TString &str);
	const TPathName &operator+=(const char *str);

	TString Get() const;
	int HasDrive() const;
	int HasFullPath() const;
	int GetDrive() const;
	TString GetBaseName() const;
	TString GetEntryName() const;
	TString GetFullPathName() const;

	int GetAttribute() const;
	int SetAttribute(int Attribute) const;

	int IsFile() const;
	TFile OpenFile() const;
	TFile CreateFile(int Attribute) const;
	int DeleteFile() const;
	int MoveFile(const TPathName &NewName) const;
	int CopyFile(const TPathName &NewName) const;
	int AppendFile(const TPathName &NewName) const;

	int IsDir() const;
    int MakeDir() const;
	int RemoveDir() const;
	int WipeDir() const;

	TDirList Find() const;
	TDirList Find(const char *SearchString) const;
	TDirList Find(const TString &SearchString) const;

private:
	void Init(const char *PathName);

    TString FPathName;
};

TPathName operator+(const TPathName& path, const TString &str);
TPathName operator+(const TPathName& path, const char *str);

#endif

