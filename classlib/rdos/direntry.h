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
# direntry.h
# Directory entry class
#
########################################################################*/

#ifndef _DIRENTRY_H
#define _DIRENTRY_H

#include "datetime.h"
#include "path.h"
#include "shareobj.h"
#include "listbase.h"

class TDirEntryData : public TShareObjectData
{
public:
    TDirEntryData();
    ~TDirEntryData();

    TPathName PathName;
    TString EntryName;
    long long FileSize;
    int Attribute;
    TDateTime CreateTime;
    TDateTime ModifyTime;
    TDateTime AccessTime;
};

class TDirEntry : public TShareObject
{
friend class TDirListNode;
public:
    TDirEntry();
    TDirEntry(const TPathName &PathName, const TString &EntryName, const TDateTime &CreateTime, const TDateTime &ModifyTime, const TDateTime &AccessTime, long long FileSize, int Attribute);
    TDirEntry(const TPathName &PathName, const TString &EntryName, const TDateTime &Time, long FileSize, int Attribute);
    TDirEntry(const TDirEntry &src);
    virtual ~TDirEntry();

    const TDirEntry &operator=(const TDirEntry &src);

    const TDirEntryData &Get() const;

    const TPathName &GetPathName() const;
    const TString &GetEntryName() const;
    long long GetFileSize() const;
    int GetAttribute() const;
    const TDateTime &GetCreateTime() const;
    const TDateTime &GetModifyTime() const;
    const TDateTime &GetAccessTime() const;

protected:
    virtual int Compare(const TDirEntry &str) const;

    virtual void Destroy(TShareObjectData *obj);

    TDirEntryData *FEntry;
};

class TDirListNode : public TListBaseNode
{
public:
    TDirListNode();
    TDirListNode(const TDirEntry &src);
    TDirListNode(const TDirListNode &source);
    virtual ~TDirListNode();

    const TDirListNode &operator=(const TDirListNode &src);
    int operator==(const TDirListNode &dest) const;
    int operator!=(const TDirListNode &dest) const;
    int operator>(const TDirListNode &dest) const;
    int operator>=(const TDirListNode &dest) const;
    int operator<(const TDirListNode &dest) const;
    int operator<=(const TDirListNode &dest) const;

    TDirEntry &Get() const;
    void Set(TDirEntry &entry);

protected:
    virtual int Compare(const TDirListNode &n2) const;
    virtual int Compare(const TListBaseNode &n2) const;
    virtual void Load(const TDirListNode &src);
    virtual void Load(const TListBaseNode &src);

    TDirEntry *FEntry;
};

class TDirList : public TListBase
{
public:
    TDirList();
    TDirList(const char *PathName);
    TDirList(const TString &PathName);
    TDirList(const TPathName &PathName);
    TDirList(const TDirList &source);
    ~TDirList();

    void SetDefaultAttributes();
    void SetRequiredAttributes(int attrib);
    void SetIgnoredAttributes(int attrib);

    void ClearSort();
    void AddSortBySize();
    void AddSortByTime();
    void AddSortByName();
    void AddSortByExt();
    void AddReverseSortBySize();
    void AddReverseSortByTime();
    void AddReverseSortByName();
    void AddReverseSortByExt();
    void Sort();

    int operator==(const TDirList &dest) const;
    int operator!=(const TDirList &dest) const;
    int operator>(const TDirList &dest) const;
    int operator>=(const TDirList &dest) const;
    int operator<(const TDirList &dest) const;
    int operator<=(const TDirList &dest) const;
    TDirList &operator=(const TDirList &l);
    TDirList &operator+=(const TDirList &l);
    TDirList &operator&=(const TDirList &l);
    TDirList &operator|=(const TDirList &l);
    TDirList &operator^=(const TDirList &l);
    TDirEntry &operator[] (int pos);

    TDirEntry &Get() const;

    void Add(const char *PathName);
    void Add(const TString &PathName);
    void Add(const TPathName &PathName);

    TPathName FPathName;
    TString FBaseString;
    TString FSearchString;

protected:
    virtual TDirListNode *Clone(const TDirListNode *ln) const;
    virtual TListBaseNode *Clone(const TListBaseNode *ln) const;

    int CheckAttrib(int attrib);
    int IsMatch(const char *FileName);
    void Add(const char *Name, unsigned long msb, unsigned long lsb, long FileSize, int Attrib);
    void Add(const char *Name, unsigned long long CreateTime, unsigned long long ModifyTime, unsigned long long AccessTime, long long FileSize, int Attrib);
    void DoSearch();

    int FAttribIgnored;
    int FAttribRequired;
    char FSortArr[5];
    int FSortCount;

private:
    void Init();

};

TDirList operator+(const TDirList& list1, const TDirList& list2);
TDirList operator&(const TDirList& list1, const TDirList& list2);
TDirList operator|(const TDirList& list1, const TDirList& list2);
TDirList operator^(const TDirList& list1, const TDirList& list2);

#endif

