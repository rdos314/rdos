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
#include "datetime.h"
#include "sockobj.h"

#define MAX_JSON_DEPTH  100

class TJsonDocument;

class TJsonObject
{
public:
    TJsonObject(TString &FieldName);
    virtual ~TJsonObject();

    TString &GetFieldName();
    TString &GetText();

    virtual bool IsCollection();
    virtual bool IsArrayObject();

    virtual bool GetBoolean();
    virtual long long GetInt();
    virtual double GetDouble();
    virtual TDateTime GetDateTime();

    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    void AddIndent(TJsonDocument *doc, int indent, TString &str);

    TString FFieldName;
    TString FText;
};

class TJsonArrayObject : public TJsonObject
{
public:
    TJsonArrayObject(TString &FieldName);
    virtual ~TJsonArrayObject();

    virtual bool IsArrayObject();

    virtual bool IsBooleanArray();
    virtual bool IsIntArray();
    virtual bool IsDoubleArray();
    virtual bool IsStringArray();
};

class TJsonBooleanArray : public TJsonArrayObject
{
public:
    TJsonBooleanArray(TString &FieldName);
    virtual ~TJsonBooleanArray();

    virtual bool IsBooleanArray();
    void Add(bool val);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    void Grow();

    int FArraySize;
    int FArrayCount;

    bool *FArr;
};

class TJsonIntArray : public TJsonArrayObject
{
public:
    TJsonIntArray(TString &FieldName);
    virtual ~TJsonIntArray();

    virtual bool IsIntArray();
    void Add(long long val);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    void Grow();

    int FArraySize;
    int FArrayCount;

    long long *FArr;
};

class TJsonDoubleArray : public TJsonArrayObject
{
public:
    TJsonDoubleArray(TString &FieldName, int Decimals);
    virtual ~TJsonDoubleArray();

    virtual bool IsDoubleArray();
    void Add(double val);
    void AddNone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    void Grow();

    int FDecimals;

    int FArraySize;
    int FArrayCount;

    double *FArr;
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

class TJsonSingleCollection;
class TJsonArrayCollection;

class TJsonCollection : public TJsonObject
{
public:
    TJsonCollection(TString &FieldName);
    virtual ~TJsonCollection();

    virtual bool IsCollection();
    virtual bool IsArray() = 0;
    virtual void Insert(TJsonObject *obj) = 0;
    virtual int GetArrayCount() = 0;
    virtual int GetObjCount() = 0;
    virtual TJsonObject *GetObj(int n) = 0;

    virtual TJsonObject *GetObj(const char *FieldName) = 0;
    virtual TJsonCollection *GetCollection(const char *FieldName) = 0;

    bool GetBoolean(const char *FieldName, bool Default);
    long long GetInt(const char *FieldName, long long Default);
    double GetDouble(const char *FieldName, double Default);
    TDateTime GetDateTime(const char *FieldName, TDateTime &Default);
    TString &GetText(const char *FieldName, TString &Default);

    TJsonSingleCollection *AddCollection(const char *FieldName);
    TJsonArrayCollection *AddArrayCollection(const char *FieldName);
    TJsonBooleanArray *AddBooleanArray(const char *FieldName);
    TJsonIntArray *AddIntArray(const char *FieldName);
    TJsonDoubleArray *AddDoubleArray(const char *FieldName, int Decimals);

    TJsonObject *AddBoolean(const char *FieldName, bool Val);
    TJsonObject *AddInt(const char *FieldName, long long Val);
    TJsonObject *AddDouble(const char *FieldName, double Val, int Decimals);
    TJsonObject *AddDateTime(const char *FieldName, TDateTime &time, int UseText);
    TJsonObject *AddString(const char *FieldName, const char *Str);

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
    virtual int GetArrayCount();
    virtual int GetObjCount();
    virtual TJsonObject *GetObj(int n);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

    virtual TJsonObject *GetObj(const char *FieldName);
    virtual TJsonCollection *GetCollection(const char *FieldName);

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
    virtual int GetArrayCount();
    virtual int GetObjCount();
    virtual TJsonObject *GetObj(int n);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

    virtual TJsonObject *GetObj(const char *FieldName);
    virtual TJsonCollection *GetCollection(const char *FieldName);

    void SelectArray(int n);

protected:
    void Grow();
    void DoAdd();

    bool FReqAdd;
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
    virtual TDateTime GetDateTime();

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
    virtual TDateTime GetDateTime();

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
    virtual TDateTime GetDateTime();

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
    virtual TDateTime GetDateTime();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

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
friend class TJsonObject;

public:
    TJsonDocument();
    TJsonDocument(const char *doc);
    ~TJsonDocument();

    void Reset();
    bool Parse(const char *doc);
    void Write(TString &str);

    TJsonCollection *GetRoot();
    TJsonCollection *CreateRoot();

protected:
    void AddIndent(int indent, TString &str);

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

class TJsonHttpClient
{
public:
    TJsonHttpClient(const char *host);
    ~TJsonHttpClient();

    TJsonDocument *Get();

protected:
    TString FHost;
    long FIp;
    TSocket *FSocket;
};

#endif
