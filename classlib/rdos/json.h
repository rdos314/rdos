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

class TJsonMem
{
public:
    TJsonMem(int MaxSize);
    ~TJsonMem();

    void *Allocate(int size);

protected:
    char *FArr;
    int FPos;
    int FSize;
};

class TJsonAlloc
{
public:
    TJsonAlloc();
    ~TJsonAlloc();

    void *Allocate(int size);
    void Reset();

protected:
    TJsonMem **FArr;
    int FMemCount;
    int FMemSize;
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

    const char *GetFieldName();
    const char *GetText();

    virtual bool IsCollection();
    virtual bool IsArrayObject();

    void *Allocate(int size);
    void Free(void *ptr);

    void *operator new(size_t size, TJsonAlloc *alloc);

    void Rename(const char *NewFieldName);
    TJsonObject *Clone(TJsonAlloc *Alloc);

    bool GetBoolean();
    long long GetInt();
    long double GetDouble();
    TDateTime GetDateTime();

    void SetBoolean(bool val);
    void SetInt(long long val);
    void SetDouble(long double val, int decimals);
    void SetDateTime(TDateTime &val);
    void SetDateTimeZone(TDateTime &val, int UtcDiff);
    void SetString(const char *Str);

    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc) = 0;

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual long double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(long double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    void CodeBoolean(bool v);
    void CodeInt(long long val);
    void CodeDouble(long double v, int decimals);
    void CodeDateTime(TDateTime &time);
    void CodeDateTimeZone(TDateTime &time, int UtcDiff);

    bool DecodeBoolean();
    long long DecodeInt();
    long double DecodeDouble();
    TDateTime DecodeDateTime();

    void NewLine(TJsonDocument *doc, TString &str);
    void AddIndent(TJsonDocument *doc, int indent, TString &str);

    char *FFieldName;

    int FSize;
    char *FText;
    TJsonAlloc *FAlloc;
};

class TJsonArrayObject : public TJsonObject
{
public:
    TJsonArrayObject(const char *FieldName, TJsonAlloc *Alloc);
    TJsonArrayObject(const TJsonArrayObject &src, TJsonAlloc *Alloc);
    virtual ~TJsonArrayObject();

    TJsonArrayObject *Clone(TJsonAlloc *Alloc);

    int Count();

    virtual bool IsArrayObject();

    virtual bool IsBooleanArray();
    virtual bool IsIntArray();
    virtual bool IsDoubleArray();
    virtual bool IsStringArray();

protected:
    int FArraySize;
    int FArrayCount;
};

class TJsonBooleanArray : public TJsonArrayObject
{
public:
    TJsonBooleanArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonBooleanArray(const TJsonBooleanArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonBooleanArray();

    virtual bool IsBooleanArray();
    bool Get(int Pos);
    void Add(bool val);
    TJsonBooleanArray *Clone(TJsonAlloc *Alloc);
    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    bool *AllocateArr(int count);
    void FreeArr(bool *arr);
    void Grow();

    bool *FArr;
};

class TJsonIntArray : public TJsonArrayObject
{
public:
    TJsonIntArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonIntArray(const TJsonIntArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonIntArray();

    virtual bool IsIntArray();
    long long Get(int Pos);
    void Add(long long val);
    TJsonIntArray *Clone(TJsonAlloc *Alloc);
    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    long long *AllocateArr(int count);
    void FreeArr(long long *arr);
    void Grow();

    long long *FArr;
};

class TJsonDoubleArray : public TJsonArrayObject
{
public:
    TJsonDoubleArray(const char *FieldName, TJsonAlloc *Alloc, int Decimals);
    TJsonDoubleArray(const TJsonDoubleArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonDoubleArray();

    virtual bool IsDoubleArray();
    long double Get(int Pos);
    void Add(long double val);
    void AddNone();
    TJsonDoubleArray *Clone(TJsonAlloc *Alloc);
    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    long double *AllocateArr(int count);
    void FreeArr(long double *arr);
    void Grow();

    int FDecimals;

    long double *FArr;
};

class TJsonStringArray : public TJsonArrayObject
{
public:
    TJsonStringArray(const char *FieldName, TJsonAlloc *Alloc);
    TJsonStringArray(const TJsonStringArray &src, TJsonAlloc *Alloc);
    virtual ~TJsonStringArray();

    virtual bool IsStringArray();
    const char *Get(int Pos);
    void Add(const char *str);
    TJsonStringArray *Clone(TJsonAlloc *Alloc);
    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    char **AllocateArr(int count);
    void FreeArr(char **arr);
    void Grow();

    char **FArr;
};

class TJsonCollectionData
{
public:
    TJsonCollectionData(TJsonAlloc *Alloc);
    TJsonCollectionData(const TJsonCollectionData &src, TJsonAlloc *Alloc);
    ~TJsonCollectionData();

    void *operator new(size_t size, TJsonAlloc *alloc);
    TJsonObject **AllocateArr(int count);
    void FreeArr(TJsonObject **arr);

    void Grow();
    void Insert(TJsonObject *obj);
    bool Remove(TJsonObject *obj);

    int FObjArraySize;
    int FObjArrayCount;

    TJsonObject **FObjArr;
    TJsonAlloc *FAlloc;
};

class TJsonSingleCollection;
class TJsonArrayCollection;

class TJsonCollection : public TJsonObject
{
public:
    TJsonCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonCollection(const TJsonCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonCollection();

    TJsonCollection *Clone(TJsonAlloc *Alloc);

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
    long double GetDouble(const char *FieldName, long double Default);
    TDateTime GetDateTime(const char *FieldName, TDateTime &Default);
    const char *GetText(const char *FieldName, const char *Default);

    TJsonSingleCollection *AddCollection(const char *FieldName);
    TJsonArrayCollection *AddArrayCollection(const char *FieldName);
    TJsonBooleanArray *AddBooleanArray(const char *FieldName);
    TJsonIntArray *AddIntArray(const char *FieldName);
    TJsonDoubleArray *AddDoubleArray(const char *FieldName, int Decimals);
    TJsonStringArray *AddStringArray(const char *FieldName);

    TJsonObject *AddBoolean(const char *FieldName, bool Val);
    TJsonObject *AddInt(const char *FieldName, long long Val);
    TJsonObject *AddDouble(const char *FieldName, long double Val, int Decimals);
    TJsonObject *AddDateTime(const char *FieldName, TDateTime &time, int UseText);
    TJsonObject *AddDateTimeZone(const char *FieldName, TDateTime &time, int UtcOffset);
    TJsonObject *AddString(const char *FieldName, const char *Str);

    void SetBoolean(const char *FieldName, bool Val);
    void SetInt(const char *FieldName, long long Val);
    void SetDouble(const char *FieldName, long double Val, int Decimals);
    void SetDateTime(const char *FieldName, TDateTime &Val, int UseText);
    void SetDateTimeZone(const char *FieldName, TDateTime &Val, int UtcOffset);
    void SetString(const char *FieldName, const char *Str);

    TJsonCollection *FParent;
};

class TJsonSingleCollection : public TJsonCollection
{
public:
    TJsonSingleCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonSingleCollection(const TJsonSingleCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonSingleCollection();

    TJsonSingleCollection *Clone(TJsonAlloc *Alloc);

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
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    TJsonCollectionData FData;
};

class TJsonArrayCollection : public TJsonCollection
{
public:
    TJsonArrayCollection(const char *FieldName, TJsonAlloc *Alloc);
    TJsonArrayCollection(const TJsonArrayCollection &src, TJsonAlloc *Alloc);
    virtual ~TJsonArrayCollection();

    TJsonArrayCollection *Clone(TJsonAlloc *Alloc);

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
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    TJsonCollectionData **AllocateArr(int count);
    void FreeArr(TJsonCollectionData **arr);

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
    TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, long double val, int decimals);
    TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, long double val, const char *data);
    TJsonDouble(const TJsonDouble &src, TJsonAlloc *Alloc);
    virtual ~TJsonDouble();

    TJsonDouble *Clone(TJsonAlloc *Alloc);

protected:
    void SetValue(long double v, int decimals);
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual long double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(long double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    long double Val;
};

class TJsonBoolean : public TJsonObject
{
public:
    TJsonBoolean(const char *FieldName, TJsonAlloc *Alloc, bool val);
    TJsonBoolean(const TJsonBoolean &src, TJsonAlloc *Alloc);
    virtual ~TJsonBoolean();

    TJsonBoolean *Clone(TJsonAlloc *Alloc);

protected:
    void SetValue(bool val);
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual long double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(long double val, int decimals);
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

    TJsonInt *Clone(TJsonAlloc *Alloc);

protected:
    void SetValue(long long val);
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual long double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(long double val, int decimals);
    virtual void SetBaseDateTime(TDateTime &val);
    virtual void SetBaseDateTimeZone(TDateTime &val, int UtcDiff);
    virtual void SetBaseString(const char *Str);

    long long Val;
};

class TJsonString : public TJsonObject
{
public:
    TJsonString(const char *FieldName, TJsonAlloc *Alloc, const char *data);
    TJsonString(const TJsonString &src, TJsonAlloc *Alloc);
    virtual ~TJsonString();

    TJsonString *Clone(TJsonAlloc *Alloc);
    virtual void Write(TJsonDocument *doc, int indent, TString &str);

protected:
    virtual TJsonObject *CloneObj(TJsonAlloc *Alloc);

    virtual bool GetBaseBoolean();
    virtual long long GetBaseInt();
    virtual long double GetBaseDouble();
    virtual TDateTime GetBaseDateTime();

    virtual void SetBaseBoolean(bool val);
    virtual void SetBaseInt(long long val);
    virtual void SetBaseDouble(long double val, int decimals);
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
    TJsonDocument(const char *doc);
    ~TJsonDocument();

    void Reset();
    bool Parse(const char *doc);
    void Write(TString &str);
    void WriteCompact(TString &str);

    TJsonCollection *GetRoot();
    TJsonCollection *CreateRoot();
    TJsonAlloc *GetAlloc();

protected:
    void AddIndent(int indent, TString &str);
    void NewLine(TString &str);

    bool AddLevel();
    bool DeleteLevel();

    bool IsArrayData();
    void SetFieldName(const char *name);
    void StartNesting();
    void EndNesting();
    void StartArray();
    void AddArray();
    void AddString(const char *str);
    void AddInt(long long val);
    void AddDouble(long double val, const char *text);
    void AddDouble(long double val, int decimals);
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

    TJsonAlloc FAlloc;
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
