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

class TJsonAlloc
{
public:
    TJsonAlloc(int MaxSize);
    ~TJsonAlloc();

    void *Allocate(int size);
    void Reset();

protected:
    char *FArr;
    int FPos;
    int FSize;
};

class TJsonFormString : public TString
{
public:
    TJsonFormString();
    TJsonFormString(const char *str);
    TJsonFormString(const TString &source);
    virtual ~TJsonFormString();

    const TJsonFormString &operator=(const TString &src);
    const TJsonFormString &operator=(const char *str);

protected:
    void Reformat(const char *str);
};

class TJsonObject
{
public:
    TJsonObject(const char *FieldName, TJsonAlloc *Alloc);
    TJsonObject(const TJsonObject &src, TJsonAlloc *Alloc);
    virtual ~TJsonObject();

    TString &GetFieldName();
    TString &GetText();

    virtual bool IsCollection();
    virtual bool IsArrayObject();

    void Rename(const char *NewFieldName);
    TJsonObject *Clone();

    bool GetBoolean();
    long long GetInt();
    double GetDouble();
    TDateTime GetDateTime();

    void SetBoolean(bool val);
    void SetInt(long long val);
    void SetDouble(double val, int decimals);
    void SetDateTime(TDateTime &val);
    void SetDateTimeZone(TDateTime &val, int UtcDiff);
    void SetString(const char *Str);

    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj() = 0;

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    void CodeBoolean(bool v);
    void CodeInt(long long val);
    void CodeDouble(double v, int decimals);
    void CodeDateTime(TDateTime &time);
    void CodeDateTimeZone(TDateTime &time, int UtcDiff);

    bool DecodeBoolean();
    long long DecodeInt();
    double DecodeDouble();
    TDateTime DecodeDateTime();

    void NewLine(TJsonDocument *doc, TString &str);
    void AddIndent(TJsonDocument *doc, int indent, TString &str);

    TString FFieldName;
    TString FText;
    TJsonAlloc *FAlloc;
};

class TJsonArrayObject : public TJsonObject
{
public:
    TJsonArrayObject(const char *FieldName, TJsonAlloc *Alloc);
    TJsonArrayObject(const TJsonArrayObject &src, TJsonAlloc *Alloc);
    virtual ~TJsonArrayObject();

    TJsonArrayObject *Clone();

    virtual bool IsArrayObject();

    virtual bool IsBooleanArray();
    virtual bool IsIntArray();
    virtual bool IsDoubleArray();
    virtual bool IsStringArray();
};

class TJsonBooleanArray : public TJsonArrayObject
{
public:
    TJsonBooleanArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonBooleanArray(const TJsonBooleanArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonBooleanArray();

    virtual bool IsBooleanArray();
    void Add(bool val);
    TJsonBooleanArray *Clone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj();
    void Grow();

    int FArraySize;
    int FArrayCount;

    bool *FArr;
};

class TJsonIntArray : public TJsonArrayObject
{
public:
    TJsonIntArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonIntArray(const TJsonIntArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonIntArray();

    virtual bool IsIntArray();
    void Add(long long val);
    TJsonIntArray *Clone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj();
    void Grow();

    int FArraySize;
    int FArrayCount;

    long long *FArr;
};

class TJsonDoubleArray : public TJsonArrayObject
{
public:
    TJsonDoubleArray(const char *FieldName, TJsonAlloc *Alloc, int Decimals);
    TJsonDoubleArray(const TJsonDoubleArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonDoubleArray();

    virtual bool IsDoubleArray();
    void Add(double val);
    void AddNone();
    TJsonDoubleArray *Clone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj();
    void Grow();

    int FDecimals;

    int FArraySize;
    int FArrayCount;

    double *FArr;
};

class TJsonStringArray : public TJsonArrayObject
{
public:
    TJsonStringArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonStringArray(const TJsonStringArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonStringArray();

    virtual bool IsStringArray();
    void Add(TString &str);
    void Add(const char *str);
    TJsonStringArray *Clone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj();
    void Grow();

    int FArraySize;
    int FArrayCount;

    char **FArr;
};

class TJsonCollectionData
{
public:
    TJsonCollectionData();
    TJsonCollectionData(const TJsonCollectionData &src);
    ~TJsonCollectionData();

    void Grow();
    void Insert(TJsonObject *obj);
    bool Remove(TJsonObject *obj);

    int FObjArraySize;
    int FObjArrayCount;

    TJsonObject **FObjArr;
};

class TJsonSingleCollection;
class TJsonArrayCollection;

class TJsonCollection : public TJsonObject
{
public:
    TJsonCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonCollection(const TJsonCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonCollection();

    TJsonCollection *Clone();

    virtual bool IsCollection();
    virtual bool IsArray() = 0;
    virtual void Insert(TJsonObject *obj) = 0;
    virtual bool Remove(TJsonObject *obj) = 0;
    virtual int GetArrayCount() = 0;
    virtual int GetObjCount() = 0;
    virtual TJsonObject *GetObj(int n) = 0;

    virtual TJsonObject *GetObj(const char *FieldName) = 0;
    virtual TJsonCollection *GetCollection(const char *FieldName) = 0;

    bool RemoveObj(const char *FieldName);
    bool RemoveCollection(const char *FieldName);
    TJsonObject *DetachObj(const char *FieldName);
    TJsonCollection *DetachCollection(const char *FieldName);

    bool GetBoolean(const char *FieldName, bool Default);
    long long GetInt(const char *FieldName, long long Default);
    double GetDouble(const char *FieldName, double Default);
    TDateTime GetDateTime(const char *FieldName, TDateTime &Default);
    TString &GetText(const char *FieldName, const char *Default);
    TString &GetText(const char *FieldName, TString &Default);

    TJsonSingleCollection *AddCollection(const char *FieldName);
    TJsonArrayCollection *AddArrayCollection(const char *FieldName);
    TJsonBooleanArray *AddBooleanArray(const char *FieldName);
    TJsonIntArray *AddIntArray(const char *FieldName);
    TJsonDoubleArray *AddDoubleArray(const char *FieldName, int Decimals);
    TJsonStringArray *AddStringArray(const char *FieldName);

    TJsonObject *AddBoolean(const char *FieldName, bool Val);
    TJsonObject *AddInt(const char *FieldName, long long Val);
    TJsonObject *AddDouble(const char *FieldName, double Val, int Decimals);
    TJsonObject *AddDateTime(const char *FieldName, TDateTime &time, int UseText);
    TJsonObject *AddDateTimeZone(const char *FieldName, TDateTime &time, int UtcOffset);
    TJsonObject *AddString(const char *FieldName, const char *Str);

    void SetBoolean(const char *FieldName, bool Val);
    void SetInt(const char *FieldName, long long Val);
    void SetDouble(const char *FieldName, double Val, int Decimals);
    void SetDateTime(const char *FieldName, TDateTime &Val, int UseText);
    void SetDateTimeZone(const char *FieldName, TDateTime &Val, int UtcOffset);
    void SetString(const char *FieldName, const char *Str);

    TJsonCollection *FParent;

protected:
    TString FTempStr;
};

class TJsonSingleCollection : public TJsonCollection
{
public:
    TJsonSingleCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonSingleCollection(const TJsonSingleCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonSingleCollection();

    TJsonSingleCollection *Clone();

    virtual bool IsArray();
    virtual void Insert(TJsonObject *obj);
    virtual bool Remove(TJsonObject *obj);
    virtual int GetArrayCount();
    virtual int GetObjCount();
    virtual TJsonObject *GetObj(int n);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

    virtual TJsonObject *GetObj(const char *FieldName);
    virtual TJsonCollection *GetCollection(const char *FieldName);

protected:
    virtual TJsonObject *CloneObj();

    TJsonCollectionData FData;
};

class TJsonArrayCollection : public TJsonCollection
{
public:
    TJsonArrayCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonArrayCollection(const TJsonArrayCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonArrayCollection();

    TJsonArrayCollection *Clone();

    virtual bool IsArray();
    virtual void AddArray();
    virtual void Insert(TJsonObject *obj);
    virtual bool Remove(TJsonObject *obj);
    virtual int GetArrayCount();
    virtual int GetObjCount();
    virtual TJsonObject *GetObj(int n);
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

    virtual TJsonObject *GetObj(const char *FieldName);
    virtual TJsonCollection *GetCollection(const char *FieldName);

    void SelectArray(int n);

protected:
    virtual TJsonObject *CloneObj();
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
    TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, double val, int decimals);
    TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, double val, TString &data);
    TJsonDouble(const TJsonDouble &src, TJsonAlloc *Alloc);
    virtual ~TJsonDouble();

    TJsonDouble *Clone();

protected:
    void SetValue(double v, int decimals);
    virtual TJsonObject *CloneObj();

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    double Val;
};

class TJsonBoolean : public TJsonObject
{
public:
    TJsonBoolean(const char *FieldName, TJsonAlloc *Alloc, bool val);
    TJsonBoolean(const TJsonBoolean &src, TJsonAlloc *Alloc);
    virtual ~TJsonBoolean();

    TJsonBoolean *Clone();

protected:
    void SetValue(bool val);
    virtual TJsonObject *CloneObj();

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    bool Val;
};

class TJsonInt : public TJsonObject
{
public:
    TJsonInt(const char *FieldName, TJsonAlloc *Alloc, long long val);
    TJsonInt(const TJsonInt &src, TJsonAlloc *Alloc);
    virtual ~TJsonInt();

    TJsonInt *Clone();

protected:
    void SetValue(long long val);
    virtual TJsonObject *CloneObj();

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    long long Val;
};

class TJsonString : public TJsonObject
{
public:
    TJsonString(const char *FieldName, TJsonAlloc *Alloc, TString &data);
    TJsonString(const TJsonString &src, TJsonAlloc *Alloc);
    virtual ~TJsonString();

    TJsonString *Clone();
    virtual void Write(TJsonDocument *doc, int indent, TString &str); 

protected:
    virtual TJsonObject *CloneObj();

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
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
    TJsonDocument(int MaxSize);
    TJsonDocument(const char *doc);
    TJsonDocument(int MaxSize, const char *doc);
    ~TJsonDocument();

    void Reset();
    bool Parse(const char *doc);
    void Write(TString &str);
    void WriteCompact(TString &str);

    TJsonCollection *GetRoot();
    TJsonCollection *CreateRoot();

protected:
    void AddIndent(int indent, TString &str);
    void NewLine(TString &str);

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

    bool FCompact;
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

    TJsonAlloc *FAlloc;
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
