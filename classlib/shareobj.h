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
# shareobj.h
# Shareable object class
#
########################################################################*/

#ifndef _SHAREOBJ_H
#define _SHAREOBJ_H

#include "section.h"

class TShareObjectData
{
friend class TShareObject;
friend class TString;
public:
    int FRefs;
    int FDataSize;
    int FAllocSize;
};

class TShareObject
{
friend class TStorageListNode;
friend class TString;
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

    void Load(const TShareObject &src);

protected:
    TShareObjectData *Create(int size);
    virtual void Destroy(TShareObjectData *obj);

	void Init();
	void AllocBuffer(int size);
	void Release();
	void Empty();
	void Release(TShareObjectData *Data);
	void CopyBeforeWrite();
	void AllocBeforeWrite(int size);
	void AssignCopy(const void *x, int size);

    TShareObjectData* (*OnCreate)(TShareObject *obj, int size);

	char *FBuf;
	TShareObjectData *FData;
    TSection FSection;
};

#endif
