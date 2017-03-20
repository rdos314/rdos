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
# iso8583.h
# ISO 8583 base class
#
########################################################################*/

#ifndef _ISO8583_H
#define _ISO8583_H

#include "datetime.h"

class TIso8583Element
{
public:
    TIso8583Element(int Id, int *DigitTable);
    virtual ~TIso8583Element();

    char *Decode(char *Buf, int *RemSize);
    char *Encode(char *Buf, int *RemSize);

    int GetId();

    int GetInt();
    void SetInt(int val);

    long long GetLong();
    void SetLong(long long val);

    const char *GetString();
    void SetString(const char *str);

    TDateTime GetTime();
    void SetTime(TDateTime &time);

    int GetBinarySize();
    const char *GetBinaryData();
    void SetBinary(const char *data, int size);

protected:
    int FId;
    char *FBuf;
    int FSize;
    int FFixedDigits;
    int FSizeDigits;
};


class TIso8583
{
public:
    TIso8583();
    virtual ~TIso8583();

    void Create(int MsgType);
    
    void AddInt(int Id, int val);
    void AddLong(int Id, long long val);
    void AddString(int Id, const char *str);
    void AddTime(int Id, TDateTime &time);
    void AddBinary(int Id, const char *data, int size);

    int IsValid(int Id);
    int GetInt(int Id);
    long long GetLong(int Id);
    const char *GetString(int Id);
    TDateTime GetTime(int Id);
    int GetBinarySize(int Id);
    const char *GetBinaryData(int Id);

    void Reset();
    int Encode(char *buf, int size);
    int Decode(char *buf, int size);

protected:
    void Init();
    TIso8583Element *GetElem(int Id);
    TIso8583Element *AddElem(int Id);
    TIso8583Element *AddElem();
    char *EncodeBitmap1(char *buf, int *RemSize);

    char *DecodeBitmap1(char *buf, int *RemSize);

    int *FDigitTable;
    int FMsgType;
    TIso8583Element *FIsoArr[193];

private:
    int FUsedArr[193];
};


#endif
