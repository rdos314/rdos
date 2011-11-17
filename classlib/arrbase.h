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
