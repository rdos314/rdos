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
# direntry.cpp
# Directory entry class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#include "direntry.h"
#include "rdos.h"
#include "section.h"

#define FALSE 0
#define TRUE !FALSE

#define ORDER_BY_SIZE   1
#define ORDER_BY_DATE   2
#define ORDER_BY_NAME   4
#define ORDER_BY_EXT    8
#define ORDER_BY_MASK   0xf
#define ORDER_BY_INV    0x10

TDirEntry EmptyDir;
char FOrderby[5];
TSection FDirSortSection("DirSort");

#ifdef __WATCOMC__
#define QSORTAPI
#else
#define QSORTAPI __cdecl
#endif

/*##########################################################################
#
#   Name       : SortCompare
#
#   Purpose....: Compare function for qsort
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int QSORTAPI SortCompare(const void *e1, const void *e2)
{
        TDirListNode **tmp;
        TDirEntryData dir1;
        TDirEntryData dir2;
        int opt;
        const char *x1;
        const char *x2;
        int rv;
        int i;

        tmp = (TDirListNode **)e1;
        dir1 = (*tmp)->Get().Get();

        tmp = (TDirListNode **)e2;
        dir2 = (*tmp)->Get().Get();

        rv = 0;

        for (i = 0; rv == 0; i++)
        {
                opt = FOrderby[i];

                switch (opt & ORDER_BY_MASK)
                {
                        case 0:
                                return 0;

                        case ORDER_BY_SIZE:
                                if (dir1.FileSize > dir2.FileSize)
                                        rv = 1;

                                if (dir1.FileSize < dir2.FileSize)
                                        rv = -1;
                                break;

                        case ORDER_BY_DATE:
                                if (dir1.ModifyTime > dir2.ModifyTime)
                                        rv = 1;

                                if (dir1.ModifyTime < dir2.ModifyTime)
                                        rv = -1;
                                break;

                        case ORDER_BY_EXT:
                                x1 = strchr(dir1.EntryName.GetData(), '.');
                                x2 = strchr(dir2.EntryName.GetData(), '.');

                                if (x1 && x2)
                                        rv = strcmp(x1, x2);

                                if (!x1 && x2)
                                        rv = -1;

                                if (x1 && !x2)
                                        rv = 1;

                                break;

                        case ORDER_BY_NAME:
                                rv = strcmp(dir1.EntryName.GetData(),dir2.EntryName.GetData());
                                break;
                }

                if (opt & ORDER_BY_INV)
                        rv = -rv;

        }
        return rv;
}

/*##########################################################################
#
#   Name       : CreateDirEntry
#
#   Purpose....: Create direntry data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShareObjectData *CreateDirEntry(TShareObject *obj, int size)
{
        return new TDirEntryData();
}

/*##########################################################################
#
#   Name       : TDirEntryData::TDirEntryData
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntryData::TDirEntryData()
{
    FileSize = 0;
    Attribute = 0;
}

/*##########################################################################
#
#   Name       : TDirEntryData::~TDirEntryData
#
#   Purpose....: destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntryData::~TDirEntryData()
{
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry(const TPathName &PathName, const TString &EntryName, const TDateTime &CreateTime, const TDateTime &ModifyTime, const TDateTime &AccessTime, long long FileSize, int Attribute)
{
    OnCreate = CreateDirEntry;
    AllocBuffer(sizeof(TDirEntryData));
    FEntry = (TDirEntryData *)FData;

    FEntry->PathName = PathName;
    FEntry->EntryName = EntryName;
    FEntry->FileSize = FileSize;
    FEntry->Attribute = Attribute;
    FEntry->CreateTime = CreateTime;
    FEntry->ModifyTime = ModifyTime;
    FEntry->AccessTime = AccessTime;
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry()
{
    OnCreate = CreateDirEntry;
    FEntry = 0;
}

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry(const TDirEntry &src)
 : TShareObject(src)
{
    OnCreate = CreateDirEntry;
    FEntry = src.FEntry;
}

/*##########################################################################
#
#   Name       : TDirEntry::~TDirEntry
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::~TDirEntry()
{
    if (FEntry && FData)
    {
        if (FData->FRefs == 1)
        {
            delete FEntry;
            FData = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TDirEntry::Destroy
#
#   Purpose....: Destroy data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirEntry::Destroy(TShareObjectData *obj)
{
        TDirEntryData *dirent = (TDirEntryData *)obj;
        delete dirent;
}

/*##########################################################################
#
#   Name       : TDirEntry::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirEntry &TDirEntry::operator=(const TDirEntry &src)
{
    Load(src);
    FEntry = src.FEntry;
        return *this;
}

/*##########################################################################
#
#   Name       : TDirEntry::Get
#
#   Purpose....: Get data object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirEntryData &TDirEntry::Get() const
{
    return *FEntry;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetPathName
#
#   Purpose....: Get pathname
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TDirEntry::GetPathName() const
{
    return FEntry->PathName;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetEntryName
#
#   Purpose....: Get entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TString &TDirEntry::GetEntryName() const
{
    return FEntry->EntryName;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetFileSize
#
#   Purpose....: Get file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDirEntry::GetFileSize() const
{
    return FEntry->FileSize;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetAttribute
#
#   Purpose....: Get file attribute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirEntry::GetAttribute() const
{
    return FEntry->Attribute;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetCreateTime
#
#   Purpose....: Get create time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDateTime &TDirEntry::GetCreateTime() const
{
    return FEntry->CreateTime;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetModifyTime
#
#   Purpose....: Get modify time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDateTime &TDirEntry::GetModifyTime() const
{
    return FEntry->ModifyTime;
}

/*##########################################################################
#
#   Name       : TDirEntry::GetAccessTime
#
#   Purpose....: Get access time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDateTime &TDirEntry::GetAccessTime() const
{
    return FEntry->AccessTime;
}

/*##########################################################################
#
#   Name       : TDirEntry::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirEntry::Compare(const TDirEntry &n2) const
{
    return FEntry->EntryName.Compare(n2.FEntry->EntryName);
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode()
{
    FEntry = 0;
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode(const TDirEntry &entry)
{
        FEntry = new TDirEntry(entry);
        FData = FEntry;
        FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::TDirListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::TDirListNode(const TDirListNode &src)
{
        FEntry = new TDirEntry(*src.FEntry);
        FData = FEntry;
        FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::~TDirListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode::~TDirListNode()
{
}

/*##########################################################################
#
#   Name       : TDirListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::Compare(const TDirListNode &n2) const
{
        if (FEntry && n2.FEntry)
                return FEntry->Compare(*n2.FEntry);
        else
        {
                if (FEntry || n2.FEntry)
                {
                        if (FEntry)
                                return 1;
                        else
                                return -1;
                }
                else
                        return 0;
        }
}

/*##########################################################################
#
#   Name       : TDirListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::Compare(const TListBaseNode &n2) const
{
    TDirListNode *p = (TDirListNode *)&n2;
    return Compare(*p);
}

/*##########################################################################
#
#   Name       : TDirListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Load(const TDirListNode &src)
{
        if (FEntry)
                *FEntry = *src.FEntry;
        else
        {
                if (src.FEntry)
                        FEntry = new TDirEntry(*src.FEntry);
        }
        FData = FEntry;
        FValid = src.FValid;
}

/*##########################################################################
#
#   Name       : TDirListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Load(const TListBaseNode &src)
{
        TDirListNode *p = (TDirListNode *)&src;
        Load(*p);
}

/*##########################################################################
#
#   Name       : TDirListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDirListNode &TDirListNode::operator=(const TDirListNode &src)
{
        Load(src);
        return *this;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator==(const TDirListNode &ln) const
{
        if (Compare(ln) == 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator!=(const TDirListNode &ln) const
{
        if (Compare(ln) == 0)
                return FALSE;
        else
                return TRUE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator>(const TDirListNode &dest) const
{
        if (Compare(dest) > 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator<(const TDirListNode &dest) const
{
        if (Compare(dest) < 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator>=(const TDirListNode &dest) const
{
        if (Compare(dest) >= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirListNode::operator<=(const TDirListNode &dest) const
{
        if (Compare(dest) <= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirListNode::Get
#
#   Purpose....: Get data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry &TDirListNode::Get() const
{
        return *FEntry;
}

/*##########################################################################
#
#   Name       : TDirListNode::Set
#
#   Purpose....: Set data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirListNode::Set(TDirEntry &entry)
{
        if (FEntry)
                *FEntry = entry;
        else
        {
                FEntry = new TDirEntry(entry);
                FData = FEntry;
        }
        FValid = TRUE;
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList()
  : FPathName("")
{
    ClearSort();
        SetDefaultAttributes();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const char *PathName)
  : FPathName(PathName)
{
    ClearSort();
        SetDefaultAttributes();
        DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TString &PathName)
  : FPathName(PathName)
{
    ClearSort();
        SetDefaultAttributes();
        DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TPathName &PathName)
  : FPathName(PathName.Get())
{
    ClearSort();
        SetDefaultAttributes();
        DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::TDirList
#
#   Purpose....: Copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::TDirList(const TDirList &source)
  : TListBase(source),
    FPathName(source.FPathName)
{
    ClearSort();
    FAttribIgnored = source.FAttribIgnored;
    FAttribRequired = source.FAttribRequired;
}

/*##########################################################################
#
#   Name       : TDirList::~TDirList
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList::~TDirList()
{
}

/*##########################################################################
#
#   Name       : TDirList::Get
#
#   Purpose....: Get dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry &TDirList::Get() const
{
        TDirListNode *p = (TDirListNode *)FCurrPos;

        if (p && p->IsValid())
            return p->Get();
        else
        return EmptyDir;
}

/*##########################################################################
#
#   Name       : TDirList::SetDefaultAttributes
#
#   Purpose....: Set default attribute to match against
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetDefaultAttributes()
{
    FAttribIgnored = FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM;
    FAttribRequired = 0;
}

/*##########################################################################
#
#   Name       : TDirList::SetRequiredAttributes
#
#   Purpose....: Set required match attributes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetRequiredAttributes(int attrib)
{
    FAttribRequired = attrib;
}

/*##########################################################################
#
#   Name       : TDirList::SetIgnoredAttributes
#
#   Purpose....: Set ignored match attributes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::SetIgnoredAttributes(int attrib)
{
    FAttribIgnored = attrib;
}

/*##########################################################################
#
#   Name       : TDirList::ClearSort
#
#   Purpose....: Clear all sort orders
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::ClearSort()
{
    int i;

    FSortCount = 0;

    for (i = 0; i < 5; i++)
        FSortArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TDirList::AddSortBySize
#
#   Purpose....: Add a new sort by size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddSortBySize()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_SIZE;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddSortByTime
#
#   Purpose....: Add a new sort by time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddSortByTime()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_DATE;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddSortByName
#
#   Purpose....: Add a new sort by name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddSortByName()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_NAME;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddSortByExt
#
#   Purpose....: Add a new sort by extention
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddSortByExt()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_EXT;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddReverseSortBySize
#
#   Purpose....: Add a new sort by size, reversed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddReverseSortBySize()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_SIZE | ORDER_BY_INV;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddReverseSortByTime
#
#   Purpose....: Add a new sort by time, reversed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddReverseSortByTime()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_DATE | ORDER_BY_INV;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddReverseSortByName
#
#   Purpose....: Add a new sort by name, reversed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddReverseSortByName()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_NAME | ORDER_BY_INV;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::AddReverseSortByExt
#
#   Purpose....: Add a new sort by extention, reversed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::AddReverseSortByExt()
{
    if (FSortCount < 4)
    {
        FSortArr[FSortCount] = ORDER_BY_EXT | ORDER_BY_INV;
        FSortCount++;
    }
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const char *PathName)
{
        FPathName = TString(PathName);
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const TString &PathName)
{
    FPathName = PathName;
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const TPathName &PathName)
{
    FPathName = PathName.Get();
    DoSearch();
}

/*##########################################################################
#
#   Name       : TDirList::CheckAttrib
#
#   Purpose....: Check if attribute matches
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::CheckAttrib(int attrib)
{
    if (attrib & FAttribIgnored)
        return FALSE;

    if ((attrib & FAttribRequired) == FAttribRequired)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::IsMatch
#
#   Purpose....: Check if file matches search criteria
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::IsMatch(const char *FileName)
{
        TString FileStr(FileName);
        TString SearchStr(FSearchString);
        const char *FilePtr;
        const char *SearchPtr;
        char ch;
        const char *LastFilePtr = 0;
        const char *LastSearchPtr = 0;

        FileStr.Upper();
        SearchStr.Upper();

        if (SearchStr.GetSize() == 0)
                return TRUE;

        FilePtr = FileStr.GetData();
        SearchPtr = SearchStr.GetData();

        if (!strcmp(SearchPtr, "*.*"))
                return TRUE;

        if (!strcmp(SearchPtr, "*."))
        {
                if (strchr(FilePtr, '.'))
                        return FALSE;
                else
                        return TRUE;
        }

        for (;;)
        {
                while (*SearchPtr && *FilePtr)
                {
                        switch (*SearchPtr)
                        {
                                case '*':
                                        ch = *(SearchPtr + 1);
                                        if (ch)
                                        {
                                                if (ch == *FilePtr)
                                                {
                                                        LastSearchPtr = SearchPtr;
                                                        SearchPtr += 2;
                                                        FilePtr++;
                                                        LastFilePtr = FilePtr;
                                                }
                                                else
                                                        FilePtr++;
                                        }
                                        else
                                                FilePtr++;
                                        break;

                                case '?':
                                        SearchPtr++;
                                        FilePtr++;
                                        break;

                                default:
                                        if (*SearchPtr == *FilePtr)
                                        {
                                                SearchPtr++;
                                                FilePtr++;
                                        }
                                        else
                                        {
                                                if (LastFilePtr)
                                                {
                                                        FilePtr = LastFilePtr;
                                                        SearchPtr = LastSearchPtr;
                                                        LastFilePtr = 0;
                                                        LastSearchPtr = 0;
                                                }
                                                else
                                                        return FALSE;
                                        }
                                        break;
                        }
                }

                if (*SearchPtr == 0 && *FilePtr == 0)
                        return TRUE;
                else
                {
                        if (*SearchPtr == '*' && *(SearchPtr+1) == 0)
                                return TRUE;

                        if (LastFilePtr)
                        {
                                FilePtr = LastFilePtr;
                                SearchPtr = LastSearchPtr;
                                LastFilePtr = 0;
                                LastSearchPtr = 0;
                        }
                        else
                                return FALSE;
                }
        }
}

/*##########################################################################
#
#   Name       : TDirList::Add
#
#   Purpose....: Add entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Add(const char *Name, unsigned long long CreateTime, unsigned long long ModifyTime, unsigned long long AccessTime, long long FileSize, int Attrib)
{
    TString Entry(Name);
    TPathName Path(FBaseString);
    Path += Entry;
    TDateTime Created(CreateTime);
    TDateTime Modified(ModifyTime);
    TDateTime Accessed(AccessTime);
    TDirEntry entry(Path, Entry, Created, Modified, Accessed, FileSize, Attrib);
    TDirListNode *p = new TDirListNode(entry);
    TListBase::AddFirst(p);
}

/*##########################################################################
#
#   Name       : TDirList::DoSearch
#
#   Purpose....: Do a new search
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::DoSearch()
{
    unsigned long msb;
    unsigned long lsb;
    int DirHandle;
    struct RdosDirInfo info;
    struct RdosDirEntry *entry;
    char *ptr;
    int i;
    long long time;

    if (FPathName.IsDir())
    {
        FBaseString = FPathName.Get();
        FSearchString = "*";
    }
    else
    {
        FBaseString = FPathName.GetBaseName();
        FSearchString = FPathName.GetEntryName();

        if (FBaseString.GetSize() == 0)
            FBaseString = ".";

        if (FSearchString.GetSize() == 0)
            FSearchString = "*";
    }

    DirHandle = RdosOpenDir(FBaseString.GetData(), &info);

    ptr = (char *)info.Entry;

    for (i = 0; i < info.Count; i++)
    {
        entry = (struct RdosDirEntry *)ptr;

        if (CheckAttrib(entry->Attrib) && IsMatch(entry->PathName))
        {
            time = entry->ModifyTime;
            memcpy(&lsb, &time, 4);
            time = time >> 32;
            memcpy(&msb, &time, 4);
            Add(entry->PathName, (unsigned long long)entry->CreateTime, (unsigned long long)entry->ModifyTime, (unsigned long long)entry->AccessTime, entry->Size, entry->Attrib);
        }

        ptr += info.HeaderSize;
        ptr += entry->PathNameSize;
    }

    RdosCloseDir(DirHandle);
}

/*##########################################################################
#
#   Name       : TDirList::Sort
#
#   Purpose....: Sort list array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirList::Sort()
{
        int count;
        TDirListNode **EntryArr;
        int ok;
        int i;

        count = GetSize();

        if (count && FSortCount)
        {
                FDirSortSection.Enter();

                EntryArr = new TDirListNode*[count];

                i = 0;
                ok = GotoFirst();
                while (ok)
                {
                        EntryArr[i] = Clone((TDirListNode *)FCurrPos);
                        i++;
                        ok = GotoNext();
                }

                Clear();

                for (i = 0; i < 5; i++)
                        FOrderby[i] = FSortArr[i];

                qsort(EntryArr, count, sizeof(TDirListNode *), SortCompare);

                for (i = count - 1; i >= 0; i--)
                        AddFirst(EntryArr[i]);

                delete EntryArr;

                FDirSortSection.Leave();
        }
}

/*##########################################################################
#
#   Name       : TDirList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator==(const TDirList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator!= (const TDirList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator>(const TDirList &dest) const
{
        if (Compare(dest) > 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator<(const TDirList &dest) const
{
        if (Compare(dest) < 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator>=(const TDirList &dest) const
{
        if (Compare(dest) >= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirList::operator<=(const TDirList &dest) const
{
        if (Compare(dest) <= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TDirList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator=(const TDirList &src)
{
        Load(src);
        FPathName = src.FPathName;
        FAttribIgnored = src.FAttribIgnored;
    FAttribRequired = src.FAttribRequired;

    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator+=
#
#   Purpose....: Concat operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator+=(const TDirList &l)
{
        TDirList list;
        list.Concat(*this, l);
        *this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator&=
#
#   Purpose....: Intersec operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator&=(const TDirList &l)
{
        TDirList list;
        list.Intersect(*this, l);
        *this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator|=
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator|=(const TDirList &l)
{
        TDirList list;
        list.Union(*this, l);
        *this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator^=
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList &TDirList::operator^=(const TDirList &l)
{
        TDirList list;
        list.Difference(*this, l);
        *this = list;
    return *this;
}

/*##########################################################################
#
#   Name       : TDirList::operator[]
#
#   Purpose....: Vector operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry &TDirList::operator[](int pos)
{
        TDirListNode *p = (TDirListNode *)TListBase::Get(pos);

        if (p->IsValid())
                return p->Get();
        else
                return EmptyDir;
}

/*##########################################################################
#
#   Name       : TDirList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirListNode *TDirList::Clone(const TDirListNode *ln) const
{
        return new TDirListNode(*ln);
}

/*##########################################################################
#
#   Name       : TDirList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TDirList::Clone(const TListBaseNode *ln) const
{
    TDirListNode *p = (TDirListNode *)ln;
        return new TDirListNode(*p);
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator+(const TDirList &list1, const TDirList& list2)
{
        TDirList list;
    list.Concat(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator&
#
#   Purpose....: Intersection operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator&(const TDirList &list1, const TDirList& list2)
{
        TDirList list;
    list.Intersect(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator|
#
#   Purpose....: Union operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator|(const TDirList &list1, const TDirList& list2)
{
        TDirList list;
    list.Union(list1, list2);
    return list;
}

/*##########################################################################
#
#   Name       : operator^
#
#   Purpose....: Difference operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList operator^(const TDirList &list1, const TDirList& list2)
{
        TDirList list;
    list.Difference(list1, list2);
    return list;
}
