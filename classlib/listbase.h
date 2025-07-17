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
	int ReplaceCurrent(const TListBaseNode *newln);

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
