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
