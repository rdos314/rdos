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
    int ReplaceCurrent(const void *data);
	virtual void Update(TListBaseNode *ln);

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
