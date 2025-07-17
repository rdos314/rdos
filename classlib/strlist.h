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
# strlist.h
# Strlist base class
#
########################################################################*/

#ifndef _STRLIST_H
#define _STRLIST_H

#include "listbase.h"
#include "str.h"

class TStringListNode : public TListBaseNode
{
public:
	TStringListNode();
	TStringListNode(const TString &str);
	TStringListNode(const TStringListNode &source);
	virtual ~TStringListNode();

	const TStringListNode &operator=(const TStringListNode &src);
	int operator==(const TStringListNode &dest) const;
	int operator!=(const TStringListNode &dest) const;
	int operator>(const TStringListNode &dest) const;
	int operator>=(const TStringListNode &dest) const;
	int operator<(const TStringListNode &dest) const;
	int operator<=(const TStringListNode &dest) const;

	TString &Get() const;
	void Set(TString &str);

protected:
	virtual int Compare(const TStringListNode &n2) const;
	virtual int Compare(const TListBaseNode &n2) const;
	virtual void Load(const TStringListNode &src);
	virtual void Load(const TListBaseNode &src);
	
	TString *FStr;
};

class TStringList : public TListBase
{
public:
	TStringList();
	TStringList(const TStringList &source);
	~TStringList();

	int operator==(const TStringList &dest) const;
	int operator!=(const TStringList &dest) const;
	int operator>(const TStringList &dest) const;
	int operator>=(const TStringList &dest) const;
	int operator<(const TStringList &dest) const;
	int operator<=(const TStringList &dest) const;
	TStringList &operator=(const TStringList &l);
	TStringList &operator+=(const TStringList &l);
	TStringList &operator&=(const TStringList &l);
	TStringList &operator|=(const TStringList &l);
	TStringList &operator^=(const TStringList &l);
	TString &operator[] (int pos);

	TString &Get();
	
	int Find(const TString &str);
	void AddFirst(const TString &str);
	void AddLast(const TString &str);
	void AddAt(int n, const TString &str);
    int Replace(int n, const TString &str);

protected:
	virtual TStringListNode *Clone(const TStringListNode *ln) const;
	virtual TListBaseNode *Clone(const TListBaseNode *ln) const;

};

TStringList operator+(const TStringList& list1, const TStringList& list2);
TStringList operator&(const TStringList& list1, const TStringList& list2);
TStringList operator|(const TStringList& list1, const TStringList& list2);
TStringList operator^(const TStringList& list1, const TStringList& list2);

#endif
