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
# list.h
# List base class
#
########################################################################*/

#ifndef _LIST_H
#define _LIST_H

class TListData
{
friend class TListNode;
friend class TList;
    int FRefs;
    int FDataSize;
    int FAllocSize;
};

class TListNode
{
friend class TList;
public:
	TListNode(const void *x, int size);
	virtual ~TListNode();

	const TListNode &operator=(const TListNode &src);
	int operator== (const TListNode &l) const;
	int operator!= (const TListNode &l) const;

protected:
	void Init();
	void AllocBuffer(int size);
	void Release();
	void Empty();
	static void Release(TListData *Data);
	void CopyBeforeWrite();
	void AllocBeforeWrite(int size);
	void AssignCopy(const void *x, int size);

	virtual int Compare(const TListNode &n2) const;

    int FRefCount;
	char *FBuf;
	TListData *FData;
    TListNode *FNext;
};

class TList
{
public:
    TList();
    ~TList();

    TListNode *GotoFirst();
    TListNode *GotoNext();
    TListNode *GotoPrev();
    TListNode *GotoLast();
    TListNode *Goto(int pos);

	int operator== (const TList &l) const;
    int operator!= (const TList &l) const;
    TList *operator= (const TList &l);
    TListNode *operator[] (int pos);

    void Clear();
    int IsEmpty();
    int GetSize();
    int GetPosition();
    void Duplicate(const TList &l);

    TList &Copy();
    TList &Reverse();
    static TList &Concat(const TList &l1, const TList &l2);
    static TList &Intersection(const TList &l1, const TList &l2);
    static TList &Union(const TList &l1, const TList &l2);
    static TList &Difference(const TList &l1, const TList &l2);
    static TList &Xor(const TList &l1, const TList &l2);

    void RemoveDuplicates();

protected:
    void Reference(TListNode *n);
    void Dereference(TListNode *n);
    void FreeNodes(TListNode *n);

    virtual TList *Create(TListNode *n);
    virtual TList *InsertBefore(const void *v, TListNode *n);
    virtual TList *InsertAfter(const void *v, TListNode *n);

    int Find(const void *x);

    int AddFirst(const void *x);
    int AddLast(const void *x);

    TListNode *RemoveFirst();
    TListNode *RemoveCurrent();
    TListNode *RemoveOne(const void *x);

    int ReplaceOne(const void *x, const void *newx);
    int ReplaceAll(const void *x, const void *newx);

    int InsertBefore(const void *x);
    int InsertAfter(const void *);
    
    TListNode *FList;
    TListNode *FCurrPos;
    TListNode *FPrevPos;
};

#endif
