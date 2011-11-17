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
# storlist.h
# Storage list base class
#
########################################################################*/

#ifndef _STORLIST_H
#define _STORLIST_H

#include "store.h"
#include "listbase.h"

class TStorageListNode : public TListBaseNode
{
friend class TStorageList;
public:
	TStorageListNode();
	TStorageListNode(const void *x, int size);
	TStorageListNode(const TStorageListNode &source);
	virtual ~TStorageListNode();

	const TStorageListNode &operator=(const TStorageListNode &src);
	int operator==(const TStorageListNode &dest) const;
	int operator!=(const TStorageListNode &dest) const;
	int operator>(const TStorageListNode &dest) const;
	int operator>=(const TStorageListNode &dest) const;
	int operator<(const TStorageListNode &dest) const;
	int operator<=(const TStorageListNode &dest) const;

protected:
	virtual int Compare(const TStorageListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TStorageListNode &src);
	virtual void Load(const TListBaseNode &src);
	
	int FID;
};

class TStorageList : public TListBase
{
public:
	TStorageList(int DataSize, unsigned short int ListID);
	TStorageList(TStorage *store, int DataSize, unsigned short int ListID);
	TStorageList(const TStorageList &source);
	~TStorageList();

	int operator==(const TStorageList &dest) const;
	int operator!=(const TStorageList &dest) const;
	int operator>(const TStorageList &dest) const;
	int operator>=(const TStorageList &dest) const;
	int operator<(const TStorageList &dest) const;
	int operator<=(const TStorageList &dest) const;
	TStorageList &operator=(const TStorageList &l);
	
	int Find(const void *data);
	void AddFirst(const void *data);
	void AddLast(const void *data);
	void AddAt(int n, const void *data);
    int Replace(int n, const void *data);

    const void *Get();
    int GetFree();
    int GetErrorCount();
    int GetMaxSize();

protected:
	void Init(int DataSize, unsigned short int ListID);
    void Recover();
    unsigned short int CalcCrc(const char *Data, int Size);

	virtual TStorageListNode *Clone(const TStorageListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;

	virtual void Add(TListBaseNode *ln);
	virtual void Remove(TListBaseNode *ln);
	virtual void Update(TListBaseNode *ln);

	virtual int Read(int entry, char *buf);
	virtual int Write(int entry, const char *buf);

    void FreeDeleted();
    void RefillCache();
    
	void Add(TStorageListNode *ln);
	void Remove(TStorageListNode *ln);
	void Update(TStorageListNode *ln);

    TStorage *FStore;
    int FEntrySize;
    int FDataSize;
	int FMaxEntries;
    unsigned short int FListID;

    int FAvailable;
    int FDeleted;
    int FErrors;

    int FCacheSize;
    int FCacheCount;
    int *FCache;
};

#endif
