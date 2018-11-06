/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2018, Leif Ekblad
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
# json.h
# json class
#
########################################################################*/

#ifndef _JSON_H
#define _JSON_H

#include "str.h"

#define MAX_JSON_DEPTH	100

class TJsonObject
{
public:
    TJsonObject(TString &FieldName);
    virtual ~TJsonObject();

    TString &GetFieldName();
    TString &GetText();

    virtual bool IsCollection();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();

protected:
    TString FFieldName;
    TString FText;
};

class TJsonCollectionData
{
public:
    TJsonCollectionData();
    ~TJsonCollectionData();

    void Grow();
    void Insert(TJsonObject *obj);

    int FObjArraySize;
    int FObjArrayCount;

    TJsonObject **FObjArr;
};

class TJsonCollection : public TJsonObject
{
public:
    TJsonCollection(TString &FieldName);
    virtual ~TJsonCollection();

    virtual bool IsCollection();
    virtual bool IsArray() = 0;
    virtual void Insert(TJsonObject *obj) = 0;

    TJsonCollection *FParent;

protected:
};

class TJsonSingleCollection : public TJsonCollection
{
public:
    TJsonSingleCollection(TString &FieldName);
    virtual ~TJsonSingleCollection();

    virtual bool IsArray();
    virtual void Insert(TJsonObject *obj);
    TJsonCollectionData *Get();

protected:
    TJsonCollectionData FData;
};

class TJsonArrayCollection : public TJsonCollection
{
public:
    TJsonArrayCollection(TString &FieldName);
    virtual ~TJsonArrayCollection();

    virtual bool IsArray();
    virtual void AddArray();
    virtual void Insert(TJsonObject *obj);

    int GetSize();
    TJsonCollectionData *operator[](int n) const;

protected:
    void Grow();

    int FCurrInd;
    int FArrayCount;
    int FArraySize;

    TJsonCollectionData **FArray;
};

class TJsonDouble : public TJsonObject
{
public:
    TJsonDouble(TString &FieldName, double val, int decimals);
    TJsonDouble(TString &FieldName, double val, TString &data);
    virtual ~TJsonDouble();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();

protected:
    double Val;
};

class TJsonBoolean : public TJsonObject
{
public:
    TJsonBoolean(TString &FieldName, bool val);
    virtual ~TJsonBoolean();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();

protected:
    bool Val;
};

class TJsonInt : public TJsonObject
{
public:
    TJsonInt(TString &FieldName, long long val);
    virtual ~TJsonInt();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();

protected:
    long long Val;
};

class TJsonString : public TJsonObject
{
public:
    TJsonString(TString &FieldName, TString &data);
    virtual ~TJsonString();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();

protected:
};

class TJsonDocument;

class TJsonStackEntry
{
friend class TJsonDocument;

public:
    TJsonStackEntry();
    ~TJsonStackEntry();

    int Parse(TJsonDocument *doc, const char *ptr, int start_state);

protected:
    int DecodeInt(TJsonDocument *doc);
    int DecodeDouble(TJsonDocument *doc);

    int HandleEatWs(TJsonDocument *doc);
    int HandleStart(TJsonDocument *doc);
    int HandleFinish(TJsonDocument *doc);
    int HandleInfinite(TJsonDocument *doc);
    int HandleNullNan(TJsonDocument *doc);
    int HandleCommentStart(TJsonDocument *doc);
    int HandleComment(TJsonDocument *doc);
    int HandleCommentEol(TJsonDocument *doc);
    int HandleCommentEnd(TJsonDocument *doc);
    int HandleString(TJsonDocument *doc);
    int HandleStringEscape(TJsonDocument *doc);
    int HandleTrue(TJsonDocument *doc);
    int HandleFalse(TJsonDocument *doc);
    int HandleNumber(TJsonDocument *doc);
    int HandleArray(TJsonDocument *doc);
    int HandleArrayAdd(TJsonDocument *doc);
    int HandleArraySep(TJsonDocument *doc);
    int HandleObjectFieldStart(TJsonDocument *doc);
    int HandleObjectField(TJsonDocument *doc);
    int HandleObjectFieldEnd(TJsonDocument *doc);
    int HandleObjectValue(TJsonDocument *doc);
    int HandleObjectValueAdd(TJsonDocument *doc);
    int HandleObjectSep(TJsonDocument *doc);

    bool PeekChar();
    bool AdvanceChar();

    const char *FDataPtr;

    bool FIsArray;
    bool FIsDouble;
    char FQuoteChar;

    int FState;
    int FSavedState;

    TString FData;
};

class TJsonDocument
{
friend class TJsonStackEntry;

public:
    TJsonDocument();
    TJsonDocument(const char *doc);
    ~TJsonDocument();

    bool Parse(const char *doc);

    TJsonCollection *GetRoot();

protected:
    bool AddLevel();
    bool DeleteLevel();

    bool IsArrayData();
    void SetFieldName(TString &name);
    void StartNesting();
    void EndNesting();
    void StartArray();
    void AddArray();
    void AddString(TString &str);
    void AddInt(long long val);
    void AddDouble(double val, TString &text);
    void AddDouble(double val, int decimals);
    void AddBoolean(bool val);

    int FStartState;
    const char *FDocPtr;
    TString FObjFieldName;

    TJsonCollection *FRootCollection;
    TJsonCollection *FCurrCollection;

private:
    void Init();

    int FDepth;
    int FErr;

    TJsonStackEntry *StackArr[MAX_JSON_DEPTH];
};

#endif
