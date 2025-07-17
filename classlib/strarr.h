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
# strarr.h
# Strarr base class
#
########################################################################*/

#ifndef _STRARR_H
#define _STRARR_H

#include "arrbase.h"
#include "str.h"

class TStringArrayNode : public TArrayBaseNode
{
public:
	TStringArrayNode();
	TStringArrayNode(const TString &str);
	TStringArrayNode(const TStringArrayNode &source);
	virtual ~TStringArrayNode();

	const TStringArrayNode &operator=(const TStringArrayNode &src);
	int operator==(const TStringArrayNode &dest) const;
	int operator!=(const TStringArrayNode &dest) const;
	int operator>(const TStringArrayNode &dest) const;
	int operator>=(const TStringArrayNode &dest) const;
	int operator<(const TStringArrayNode &dest) const;
	int operator<=(const TStringArrayNode &dest) const;

	TString &Get() const;
	void Set(TString &str);

protected:
	virtual int Compare(const TStringArrayNode &n2) const;
	virtual int Compare(const TArrayBaseNode &n2) const;
	virtual void Load(const TStringArrayNode &src);
	virtual void Load(const TArrayBaseNode &src);
	
	TString *FStr;
};

class TStringArray : public TArrayBase
{
public:
	TStringArray();
	TStringArray(const TStringArray &source);
	~TStringArray();

	TStringArray &operator=(const TStringArray &l);
	TStringArray &operator+=(const TStringArray &l);
	TString &operator[] (int pos);

	TString &Get(int pos);
	
	void Add(const TString &str);
	void Add(int pos, const TString &str);
    void Replace(int pos, const TString &str);

protected:
	virtual TStringArrayNode *Clone(const TStringArrayNode *ln) const;
	virtual TArrayBaseNode *Clone(const TArrayBaseNode *ln) const;

};

TStringArray operator+(const TStringArray& arr1, const TStringArray& arr2);

#endif
