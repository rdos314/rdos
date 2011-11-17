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
# listbase.h
# List base class
#
########################################################################*/

#ifndef _LISTBASE_H
#define _LISTBASE_H

#include "store.h"
#include "shareobj.h"
#include "section.h"

class TListBaseNode
{
friend class TListBase;
public:
	TListBaseNode();
	TListBaseNode(const void *x, int size);
	TListBaseNode(const TListBaseNode &source);
	virtual ~TListBaseNode();

	int IsValid() const;
	int GetSize() const;
	const void *GetData() const;
	void SetData(const void *x, int size);

protected:
	virtual int Compare(const TListBaseNode &n2) const = 0;
	virtual void Load(const TListBaseNode &src) = 0;

	int FValid;
	TShareObject *FData;
	TListBaseNode *FNext;
};

class TListBase
{
public:
	TListBase();
	TListBase(const TListBase &source);
	virtual ~TListBase();

	int GotoFirst();
	int GotoNext();
	int GotoPrev();
	int GotoLast();
	int Goto(int pos);

	TListBase &operator=(const TListBase &l);

	void Clear();
	int IsEmpty();
	int GetSize();
	int GetPosition();

	int RemoveFirst();
	int RemoveLast();
	int RemoveCurrent();
	int Remove(int n);

    void Concat(const TListBase &src1, const TListBase &src2); 
    void Intersect(const TListBase &src1, const TListBase &src2); 
    void Union(const TListBase &src1, const TListBase &src2); 
    void Difference(const TListBase &src1, const TListBase &src2); 

    void Reverse();
    void RemoveDuplicates();

protected:
    void Init();
    
	void Invalidate(TListBaseNode *ln);
	void Load(const TListBase &src);
	int Find(const TListBaseNode *ln);
	void AddFirst(TListBaseNode *newln);
	void AddLast(TListBaseNode *newln);
	void AddAt(int n, TListBaseNode *newln);
	int Replace(int n, const TListBaseNode *newln);
	TListBaseNode *Get(int n);
	int Compare(const TListBase &l) const;

	virtual TListBaseNode *Clone(const TListBaseNode *ln) const = 0;

	virtual void RemoveOldest();
	virtual void Add(TListBaseNode *ln);
	virtual void Remove(TListBaseNode *ln);
	virtual void Update(TListBaseNode *ln);

	TListBaseNode *FInvNext;
    
	TListBaseNode *FList;
	TListBaseNode *FCurrPos;
	TListBaseNode *FPrevPos;


    TSection FSection;

};

#endif
