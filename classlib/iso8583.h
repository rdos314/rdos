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

class TIso8583Bitmap
{
public:
    TIso8583Bitmap(int *DigitTable);
    virtual ~TIso8583Bitmap();

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
    char *EncodeBitmap(char *buf, int *RemSize);

    char *DecodeBitmap(char *buf, int *RemSize);

    int *FDigitTable;
    TIso8583Element *FIsoArr[64];

private:
    int FUsedArr[64];
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
