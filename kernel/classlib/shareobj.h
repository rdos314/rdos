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
# shareobj.h
# Shareable object class
#
########################################################################*/

#ifndef _SHAREOBJ_H
#define _SHAREOBJ_H

class TShareObjectData
{
friend class TShareObject;
friend class TString;
    int FRefs;
    int FDataSize;
    int FAllocSize;
};

class TShareObject
{
friend class TStorageListNode;
public:
	TShareObject();
	TShareObject(const void *x, int size);
	TShareObject(const TShareObject &source);
	virtual ~TShareObject();

	const TShareObject &operator=(const TShareObject &src);
	int operator==(const TShareObject &dest) const;
	int operator!=(const TShareObject &dest) const;
	int operator>(const TShareObject &dest) const;
	int operator>=(const TShareObject &dest) const;
	int operator<(const TShareObject &dest) const;
	int operator<=(const TShareObject &dest) const;

	int GetSize() const;
	const void *GetData() const;
	void SetData(const void *x, int size);

	virtual int Compare(const TShareObject &n2) const;

protected:
    virtual TShareObjectData *Create(int size);
    virtual void Destroy(TShareObjectData *obj);

	void Init();
    void Load(const TShareObject &src);
	void AllocBuffer(int size);
	void Release();
	void Empty();
	void Release(TShareObjectData *Data);
	void CopyBeforeWrite();
	void AllocBeforeWrite(int size);
	void AssignCopy(const void *x, int size);

	char *FBuf;
	TShareObjectData *FData;
};

#endif
