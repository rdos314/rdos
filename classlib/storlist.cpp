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
# storlist.cpp
# Storage list class
#
########################################################################*/

#include <string.h>

#include "storlist.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TStorageListNode::TStorageListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageListNode::TStorageListNode()
{
    FID = -1;
}

/*##########################################################################
#
#   Name       : TStorageListNode::TStorageListNode
#
#   Purpose....: Constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageListNode::TStorageListNode(const void *x, int size)
  : TListBaseNode(x, size)
{
        FID = -1;
}

/*##########################################################################
#
#   Name       : TStorageListNode::TStorageListNode
#
#   Purpose....: Copy constructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageListNode::TStorageListNode(const TStorageListNode &src)
  : TListBaseNode(src)
{
    FID = src.FID;
}

/*##########################################################################
#
#   Name       : TStorageListNode::~TStorageListNode
#
#   Purpose....: Destructor for list-node
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageListNode::~TStorageListNode()
{
}

/*##########################################################################
#
#   Name       : TStorageListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::Compare(const TStorageListNode &n2) const
{
        return FData->Compare(*n2.FData);
}

/*##########################################################################
#
#   Name       : TStorageListNode::Compare
#
#   Purpose....: Compare nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::Compare(const TListBaseNode &n2) const
{
    TStorageListNode *p = (TStorageListNode *)&n2;
    return Compare(*p);    
}

/*##########################################################################
#
#   Name       : TStorageListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageListNode::Load(const TStorageListNode &src)
{
    FData->Load(*src.FData);
    FID = src.FID;
}

/*##########################################################################
#
#   Name       : TStorageListNode::Load
#
#   Purpose....: Load new node
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageListNode::Load(const TListBaseNode &src)
{
        TStorageListNode *p = (TStorageListNode *)&src;
        Load(*p);
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TStorageListNode &TStorageListNode::operator=(const TStorageListNode &src)
{
        Load(src);
        return *this;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator==
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator==(const TStorageListNode &ln) const
{
        if (Compare(ln) == 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator!=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator!=(const TStorageListNode &ln) const
{
        if (Compare(ln) == 0)
                return FALSE;
        else
                return TRUE;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator>
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator>(const TStorageListNode &dest) const
{
        if (Compare(dest) > 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator<
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator<(const TStorageListNode &dest) const
{
        if (Compare(dest) < 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator>=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator>=(const TStorageListNode &dest) const
{
        if (Compare(dest) >= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageListNode::operator<=
#
#   Purpose....: Compare list nodes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageListNode::operator<=(const TStorageListNode &dest) const
{
        if (Compare(dest) <= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::TStorageList
#
#   Purpose....: Constructor for list (no recover)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageList::TStorageList(int DataSize, unsigned short int ListID)
{
    Init(DataSize, ListID);
}

/*##########################################################################
#
#   Name       : TStorageList::TStorageList
#
#   Purpose....: Constructor for list (recover with a simple store)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageList::TStorageList(TStorage *store, int DataSize, unsigned short int ListID)
{
    Init(DataSize, ListID);
    
    FStore = store;
    FMaxEntries = (int)(FStore->Size() / (long)FEntrySize);
    Recover();
}

/*##########################################################################
#
#   Name       : TStorageList::TStorageList
#
#   Purpose....: Copy constructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageList::TStorageList(const TStorageList &src)
  : TListBase(src)
{
    FStore = src.FStore;
    FListID = src.FListID;
    FEntrySize = src.FEntrySize;
    FDataSize = src.FDataSize;
    FMaxEntries = src.FMaxEntries;
}

/*##########################################################################
#
#   Name       : TStorageList::~TStorageList
#
#   Purpose....: Destructor for list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageList::~TStorageList()
{
    delete FCache;
}

/*##########################################################################
#
#   Name       : TStorageList::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Init(int DataSize, unsigned short int ListID)
{
    FStore = 0;
    FListID = ListID;
    FDataSize = DataSize;
    FEntrySize = DataSize + 2;
    FAvailable = 0;
    FDeleted = 0;
    FCacheCount = 0;
        FErrors = 0;
}

/*##########################################################################
#
#   Name       : TStorageList::operator==
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator==(const TStorageList &l) const
{
    if (Compare(l) == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::operator!=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator!= (const TStorageList &l) const
{
    if (Compare(l) != 0)
        return TRUE;
    else
        return FALSE;
}    

/*##########################################################################
#
#   Name       : TStorageList::operator>
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator>(const TStorageList &dest) const
{
        if (Compare(dest) > 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::operator<
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator<(const TStorageList &dest) const
{
        if (Compare(dest) < 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::operator>=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator>=(const TStorageList &dest) const
{
        if (Compare(dest) >= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::operator<=
#
#   Purpose....: Compare lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::operator<=(const TStorageList &dest) const
{
        if (Compare(dest) <= 0)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TStorageList::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageList &TStorageList::operator=(const TStorageList &src)
{
        Load(src);
        return *this;
}

/*##########################################################################
#
#   Name       : TStorageList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStorageListNode *TStorageList::Clone(const TStorageListNode *ln) const
{
        return new TStorageListNode(*ln);
}

/*##########################################################################
#
#   Name       : TStorageList::Clone
#
#   Purpose....: Clone entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TListBaseNode *TStorageList::Clone(const TListBaseNode *ln) const
{
    TStorageListNode *p = (TStorageListNode *)ln;
        return new TStorageListNode(*p);
}

/*##########################################################################
#
#   Name       : TStorageList::Add
#
#   Purpose....: Add notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Add(TListBaseNode *ln)
{
        TStorageListNode *p = (TStorageListNode *)ln;
        Add(p);
}

/*##########################################################################
#
#   Name       : TStorageList::Remove
#
#   Purpose....: Remove notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Remove(TListBaseNode *ln)
{
        TStorageListNode *p = (TStorageListNode *)ln;
        Remove(p);
}

/*##########################################################################
#
#   Name       : TStorageList::Update
#
#   Purpose....: Update notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Update(TListBaseNode *ln)
{
    TStorageListNode *p = (TStorageListNode *)ln;
        Update(p);
}

/*##########################################################################
#
#   Name       : TStorageList::Find
#
#   Purpose....: Find specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::Find(const void *data)
{
        TStorageListNode n = TStorageListNode(data, FDataSize);
        return TListBase::Find(&n);
}

/*##########################################################################
#
#   Name       : TStorageList::AddFirst
#
#   Purpose....: Add entry as first entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::AddFirst(const void *data)
{
        TStorageListNode *p = new TStorageListNode(data, FDataSize);
        TListBase::AddFirst(p);
}

/*##########################################################################
#
#   Name       : TStorageList::AddLast
#
#   Purpose....: Add entry as last entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::AddLast(const void *data)
{
        TStorageListNode *p = new TStorageListNode(data, FDataSize);
        TListBase::AddLast(p);
}

/*##########################################################################
#
#   Name       : TStorageList::AddAt
#
#   Purpose....: Add entry at specified position, if possible.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::AddAt(int n, const void *data)
{
        TStorageListNode *p = new TStorageListNode(data, FDataSize);
        TListBase::AddAt(n, p);
}

/*##########################################################################
#
#   Name       : TStorageList::Replace
#
#   Purpose....: Replace specified entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::Replace(int pos, const void *data)
{
        TStorageListNode n = TStorageListNode(data, FDataSize);
        return TListBase::Replace(pos, &n);
}

/*##########################################################################
#
#   Name       : TStorageList::ReplaceCurrent
#
#   Purpose....: Replace current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::ReplaceCurrent(const void *data)
{
    TStorageListNode n = TStorageListNode(data, FDataSize);
    TStorageListNode *curr = (TStorageListNode *)FCurrPos;
    n.FID = curr->FID;
    return TListBase::ReplaceCurrent(&n);
}

/*##################  TStorageList::CalcCrc ############
*   Purpose....: Calculate CRC                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
unsigned short int TStorageList::CalcCrc(const char *Data, int Size)
{
        unsigned short int Crc = 0;
        int i;
        unsigned short int Temp1, Temp2;
        char ch;

        while (Size)
        {
                ch = *Data;
                for (i = 0; i != 8; i++)
                {
                        Temp1 = (ch & 0x80) << 8;
                        Temp2 = Crc & 0x8000;
                        Crc = Crc << 1;
                        if ((Temp1 ^ Temp2) != 0)
                                Crc = Crc ^ 0x8005;
                        ch = ch << 1;
                }
                Size--;
                Data++;
        }
        Crc += FListID;
        return Crc ^ 0x5C4A;
}

/*##########################################################################
#
#   Name       : TStorageList::Read
#
#   Purpose....: Read an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::Read(int entry, char *buf)
{
    return FStore->Read((long)entry * (long)FEntrySize, buf, FEntrySize);
}

/*##########################################################################
#
#   Name       : TStorageList::Write
#
#   Purpose....: Write an entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::Write(int entry, const char *buf)
{
    return FStore->Write((long)entry * (long)FEntrySize, buf, FEntrySize);
}

/*##########################################################################
#
#   Name       : TStorageList::Recover
#
#   Purpose....: Recover list from backup store
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Recover()
{
    int Entry;
    int i;
    unsigned char andsum;
    unsigned char orsum;
    unsigned short int crc;
    char *buf;
    char *ptr;
        TStorageListNode *listnode;

    buf = new char[FEntrySize];

        FCacheSize = FMaxEntries / 16;
        if (FCacheSize < 16)
        FCacheSize = 16;

    FCache = new int[FCacheSize];

    for (Entry = 0; Entry < FMaxEntries; Entry++)
    {
                if (Read(Entry, buf))
                {
                        crc = CalcCrc(buf, FDataSize);
                        if (crc == *(unsigned short int *)(buf + FDataSize))
                        {
                                listnode = new TStorageListNode(buf, FDataSize);
                                listnode->FID = Entry;
                                if (FMaxEntries > 1000)
                                TListBase::AddFirst(listnode);
                        else
                                TListBase::AddLast(listnode);
                        }
                        else
                        {
                            orsum = 0;
                                andsum = -1;
                                ptr = buf;

                                for (i = 0; i < FEntrySize; i++)
                                {
                                    orsum |= *ptr;
                                        andsum &= *ptr;
                                        ptr++;
                                }

                                if (orsum == 0)
                                    FDeleted++;

                                if (andsum == 0xFF)
                                {
                                        if (FCacheCount < FCacheSize)
                                        {
                                                FCache[FCacheCount] = Entry;
                                                FCacheCount++;
                                    }
                                        FAvailable++;
                                }

                                if (andsum != 0xFF && orsum != 0)
                                {
                                        FErrors++;
                                        FDeleted++;
                                        memset(buf, 0, FEntrySize);
                                        Write(Entry, buf);
                                }
            }                 
        }
    }

    delete buf;
}

/*##########################################################################
#
#   Name       : TStorageList::FreeDeleted
#
#   Purpose....: Free all deleted entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::FreeDeleted()
{
    int Entry;
        char *buf;
    unsigned short int crc;

        FAvailable = 0;
        FDeleted = 0;
        FCacheCount = 0;

        buf = new char[FEntrySize];

        for (Entry = 0; Entry < FMaxEntries; Entry++)
        {
                if (Read(Entry, buf))
                {
                        crc = CalcCrc(buf, FDataSize);
                        if (crc != *(unsigned short int *)(buf + FDataSize))
                        {
                                memset(buf, 0xFF, FEntrySize);
                                Write(Entry, buf);

                                if (FCacheCount < FCacheSize)
                                {
                                        FCache[FCacheCount] = Entry;
                                        FCacheCount++;
                                }
                                FAvailable++;
            }                 
        }
    }
    delete buf;
}

/*##########################################################################
#
#   Name       : TStorageList::RefillCache
#
#   Purpose....: Refill cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::RefillCache()
{
    int Entry;
    int i;
        char *buf;
        char *ptr;
    unsigned char sum;

        FCacheCount = 0;

        buf = new char[FEntrySize];

        for (Entry = 0; Entry < FMaxEntries; Entry++)
        {
                if (Read(Entry, buf))
                {
                    sum = 0xFF;
                        ptr = buf;

                        for (i = 0; i < FEntrySize; i++)
                        {
                                sum &= *ptr;
                                ptr++;
                        }

            if (sum == 0xFF)
            {
                                FCache[FCacheCount] = Entry;
                                FCacheCount++;
                                if (FCacheCount == FCacheSize || FAvailable == FCacheCount)
                                break;
            }                 
        }
    }
    
    delete buf;
}

/*##########################################################################
#
#   Name       : TStorageList::Add
#
#   Purpose....: Add notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Add(TStorageListNode *ln)
{
        char *buf;
        unsigned short int crc;

        if (ln && ln->FID == -1)
        {
                if (!FAvailable && FDeleted)
                        FreeDeleted();

                if (!FAvailable)
                {
                        RemoveOldest();
                        FreeDeleted();
            }

            if (!FCacheCount && FAvailable)
                RefillCache();

                if (FCacheCount)
                {
                    FAvailable--;
                        FCacheCount--;
                        ln->FID = FCache[FCacheCount];

                        buf = new char[FEntrySize];
                        memcpy(buf, ln->GetData(), FDataSize);
                        crc = CalcCrc(buf, FDataSize);
                        *(unsigned short int *)(buf + FDataSize) = crc;
                        Write(ln->FID, buf);
                        delete buf;
                }
        }
}

/*##########################################################################
#
#   Name       : TStorageList::Remove
#
#   Purpose....: Remove notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Remove(TStorageListNode *ln)
{
        char *buf;
        
    if (ln && ln->FID >= 0 && ln->FID < FMaxEntries)
    {
        FDeleted++;
                buf = new char[FEntrySize];
                memset(buf, 0, FEntrySize);
                Write(ln->FID, buf);
                delete buf;
        }
}

/*##########################################################################
#
#   Name       : TStorageList::Update
#
#   Purpose....: Update notify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStorageList::Update(TStorageListNode *ln)
{
        char *buf;
        unsigned short int crc;

        if (ln && ln->FID >= 0 && ln->FID < FMaxEntries)
        {
                buf = new char[FEntrySize];
                
        FDeleted++;
                memset(buf, 0, FEntrySize);
                Write(ln->FID, buf);

                if (!FAvailable && FDeleted)
                        FreeDeleted();

            if (!FCacheCount && FAvailable)
                RefillCache();

                if (FCacheCount)
                {
                    FAvailable--;
                        FCacheCount--;
                        ln->FID = FCache[FCacheCount];

                memcpy(buf, ln->GetData(), FDataSize);
                crc = CalcCrc(buf, FDataSize);
                *(unsigned short int *)(buf + FDataSize) = crc;
                    Write(ln->FID, buf);
                }

                delete buf;
        }
}

/*##########################################################################
#
#   Name       : TStorageList::GetFree
#
#   Purpose....: Get free entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::GetFree()
{
        return FAvailable + FDeleted;
}

/*##########################################################################
#
#   Name       : TStorageList::Get
#
#   Purpose....: Get current entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const void *TStorageList::Get()
{
    if (FCurrPos)
                return FCurrPos->GetData();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TStorageList::GetErrorCount
#
#   Purpose....: Get # of recovery errors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::GetErrorCount()
{
        return FErrors;
}

/*##########################################################################
#
#   Name       : TStorageList::GetMaxSize
#
#   Purpose....: Get max entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStorageList::GetMaxSize()
{
        return FMaxEntries;
}
