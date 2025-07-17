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
# arrbase.h
# Array base class
#
########################################################################*/

#ifndef _ARRBASE_H
#define _ARRBASE_H

#include "shareobj.h"
#include "section.h"

class TArrayBaseNode
{
friend class TArrayBase;
public:
	TArrayBaseNode();
	TArrayBaseNode(const void *x, int size);
	TArrayBaseNode(const TArrayBaseNode &source);
	virtual ~TArrayBaseNode();

	int IsValid() const;
	int GetSize() const;
	const void *GetData() const;
	void SetData(const void *x, int size);

protected:
	virtual int Compare(const TArrayBaseNode &n2) const = 0;
	virtual void Load(const TArrayBaseNode &src) = 0;

	int FValid;
	TShareObject *FData;
};

class TArrayBase
{
public:
	TArrayBase();
	TArrayBase(const TArrayBase &source);
	virtual ~TArrayBase();

	TArrayBase &operator=(const TArrayBase &l);

	void Clear();
	int IsEmpty();
	int GetSize();

	void Remove();
	void Remove(int pos);

    void Concat(const TArrayBase &src1, const TArrayBase &src2); 

protected:
    void Init();
    void Grow();
    
	void Load(const TArrayBase &src);

	void Add(TArrayBaseNode *newln);
	void Add(int pos, TArrayBaseNode *newln);
	
	void Replace(int pos, const TArrayBaseNode *newln);

	virtual TArrayBaseNode *Clone(const TArrayBaseNode *ln) const = 0;

	TArrayBaseNode *Get(int pos);

	TArrayBaseNode **FArr;
	int FCount;
	int FAllocSize;

    TSection FSection;

};

#endif
