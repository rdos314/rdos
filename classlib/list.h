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
# list.h
# List class
#
########################################################################*/

#ifndef _LIST_H
#define _LIST_H

#include "listbase.h"

class TListNode : public TListBaseNode
{
public:
	TListNode();
	TListNode(const void *x, int size);
	TListNode(const TListNode &source);
	virtual ~TListNode();

	const TListNode &operator=(const TListNode &src);
	int operator==(const TListNode &dest) const;
	int operator!=(const TListNode &dest) const;
	int operator>(const TListNode &dest) const;
	int operator>=(const TListNode &dest) const;
	int operator<(const TListNode &dest) const;
	int operator<=(const TListNode &dest) const;

protected:
	virtual int Compare(const TListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TListNode &src);
	virtual void Load(const TListBaseNode &src);
};

class TList : public TListBase
{
public:
	TList();
	TList(const TList &source);
	~TList();

	int operator==(const TList &dest) const;
	int operator!=(const TList &dest) const;
	int operator>(const TList &dest) const;
	int operator>=(const TList &dest) const;
	int operator<(const TList &dest) const;
	int operator<=(const TList &dest) const;
	TList &operator=(const TList &l);
	TList &operator+=(const TList &l);
	TList &operator&=(const TList &l);
	TList &operator|=(const TList &l);
	TList &operator^=(const TList &l);
	TListNode &operator[] (int pos);

	TListNode &Get();

	int Find(const TListNode &ln);
	void AddFirst(const TListNode &newln);
	void AddLast(const TListNode &newln);
	void AddAt(int n, const TListNode &newln);
    int Replace(int n, const TListNode &newln);

protected:
	virtual TListNode *Clone(const TListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;
};

TList operator+(const TList& list1, const TList& list2);
TList operator&(const TList& list1, const TList& list2);
TList operator|(const TList& list1, const TList& list2);
TList operator^(const TList& list1, const TList& list2);

#endif
