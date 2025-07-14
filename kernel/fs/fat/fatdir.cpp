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
# fatdir.cpp
# FAT directory class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include "fatdir.h"
#include "fatfs.h"

/*##########################################################################
#
#   Name       : TFatDir::TFatDir
#
#   Purpose....: Fat dir constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatDir::TFatDir(TFat *Fat, long long RootSector, int Sectors)
  : TDir(0, 0)
{
    Init();

    FFat = Fat;
    FSectorsPerCluster = Fat->SectorsPerCluster;
    FStartSector = RootSector;
    FSectorCount = Sectors;

    ProcessFixed();
}

/*##########################################################################
#
#   Name       : TFatDir::TFatDir
#
#   Purpose....: Fat dir constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatDir::TFatDir(TFat *Fat, TDir *ParentDir, int ParentIndex, unsigned int Cluster)
  : TDir(ParentDir, ParentIndex)
{
    Init();

    FFat = Fat;
    FClusterChain = Fat->GetClusterChain(Cluster);

    FClusterCount = FClusterChain->GetSize();
    FClusterArr = FClusterChain->GetChain();

    FSectorsPerCluster = Fat->SectorsPerCluster;
    FStartSector = Fat->StartSector;
    FSectorCount = 0;

    ProcessClusters();
}

/*##########################################################################
#
#   Name       : TFatDir::~TFatDir
#
#   Purpose....: Fat dir destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatDir::~TFatDir()
{
    delete LfnArr;

    if (FreeArr)
        delete FreeArr;

    if (FClusterChain)
        delete FClusterChain;
}

/*##########################################################################
#
#   Name       : TFatDir::Init
#
#   Purpose....: Init object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::Init()
{
    FCurrLfn = 0;
    LfnCount = 0;
    LfnMax = 4;
    LfnArr = new TLfnEntry[MaxCount];

    FreeCount = 0;
    FreeEntries = 0;
    FreeArr = 0;

    FClusterChain = 0;
    FSectorsPerCluster = 0;
    FStartSector = 0;
    FSectorCount = 0;
}

/*##########################################################################
#
#   Name       : TFatDir::IsFixedDir
#
#   Purpose....: Check for fixed dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::IsFixedDir()
{
    if (FClusterChain)
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TFatDir::Add
#
#   Purpose....: Add and fixup entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::Add(int pos, const char *name, struct TFatDirEntry *fat)
{
    unsigned int cluster = ::GetCluster(fat);
    RdosDirEntry *entry;

    Section.Enter();

    entry = TDir::Add(name, cluster);

    if (fat->CrDate)
        entry->CreateTime = DecodeTime(fat->CrDate, fat->CrTime, fat->CrMs) + 1193 / 2;

    if (fat->WrDate)
        entry->ModifyTime = DecodeTime(fat->WrDate, fat->WrTime, 0) + 1193 / 2;

    if (fat->AcDate)
        entry->AccessTime = DecodeTime(fat->AcDate, 0, 0) + 1193 / 2;

    entry->Attrib = DecodeAttrib(fat->Attr);
    entry->Size = fat->FileSize;
    entry->Pos = pos;

    Section.Leave();
}

/*##########################################################################
#
#   Name       : TFatDir::GrowLfn
#
#   Purpose....: Grow LFN array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::GrowLfn()
{
    int i;
    int Size = 2 * LfnMax;
    struct TLfnEntry *NewArr;

    NewArr = new TLfnEntry[Size];

    for (i = 0; i < LfnMax; i++)
    {
        strcpy(NewArr[i].Name, LfnArr[i].Name);
        NewArr[i].Pos = LfnArr[i].Pos;
        NewArr[i].Count = LfnArr[i].Count;
    }

    for (i = LfnMax; i < Size; i++)
    {
        NewArr[i].Name[0] = 0;
        NewArr[i].Pos = 0;
        NewArr[i].Count = 0;
    }

    delete LfnArr;
    LfnArr = NewArr;
    LfnMax = Size;
}

/*##########################################################################
#
#   Name       : TFatDir::FindLfn
#
#   Purpose....: Find LFN name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::FindLfn(const char *path)
{
    int i;

    Section.Enter();

    for (i = 0; i < LfnCount; i++)
    {
        if (!strcmp(path, LfnArr[i].Name))
        {
            Section.Leave();
            return true;
        }
    }

    Section.Leave();

    return false;
}

/*##########################################################################
#
#   Name       : TFatDir::DeleteLfn
#
#   Purpose....: Delete entry in LFN array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatDir::DeleteLfn(int pos)
{
    int i;
    bool found = false;
    int index;
    int count = 1;

    for (i = 0; i < LfnCount && !found; i++)
    {
        if (LfnArr[i].Pos == pos)
        {
            index = i;
            found = true;
        }
    }

    if (found)
    {
        count = LfnArr[index].Count;
        LfnCount--;

        for (i = index; i < LfnCount; i++)
        {
            strcpy(LfnArr[i].Name, LfnArr[i+1].Name);
            LfnArr[i].Pos = LfnArr[i+1].Pos;
            LfnArr[i].Count = LfnArr[i+1].Count;
        }
    }

    return count;
}

/*##########################################################################
#
#   Name       : TFatDir::AddStd
#
#   Purpose....: Add std entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddStd(int pos, struct TFatDirEntry *entry)
{
    char Name[16];

    GetEntryName(entry, Name);
    Add(pos, Name, entry);
}

/*##########################################################################
#
#   Name       : TFatDir::AddLfn
#
#   Purpose....: Add LFN entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddLfn(int pos, struct TFatDirEntry *entry)
{
    int size = FCurrLfn->GetNameSize();
    int count = FCurrLfn->GetEntryCount();
    char *buf = new char[size];

    if (LfnMax == LfnCount)
       GrowLfn();

    GetEntryName(entry, LfnArr[LfnCount].Name);
    LfnArr[LfnCount].Pos = pos;
    LfnArr[LfnCount].Count = count;

    LfnCount++;

    FCurrLfn->GetName(buf);
    Add(pos, buf, entry);

    delete buf;
}

/*##########################################################################
#
#   Name       : TFatDir::AddLfn
#
#   Purpose....: Add LFN entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddLfn(int pos, const char *name, struct TFatDirEntry *entry, int count)
{
    if (LfnMax == LfnCount)
       GrowLfn();

    GetEntryName(entry, LfnArr[LfnCount].Name);
    LfnArr[LfnCount].Pos = pos;
    LfnArr[LfnCount].Count = count;

    LfnCount++;

    Add(pos, name, entry);
}

/*##########################################################################
#
#   Name       : TFatDir::Add
#
#   Purpose....: Add entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::Add(int pos, struct TFatDirEntry *entry)
{
    struct TFatLfnEntry *lfn;

    switch (entry->Base[0])
    {
        case ' ':
        case '.':
        case 0xE5:
        case 0:
            break;

        default:
            if (entry->Attr == 0xF)
            {
                lfn = (struct TFatLfnEntry *)entry;

                if (lfn->Ord & 0x40)
                {
                    if (FCurrLfn)
                        delete FCurrLfn;

                    FCurrLfn = new struct TFatLfn(lfn);
                }
                else
                {
                    if (FCurrLfn)
                    {
                        if (!FCurrLfn->Add(lfn))
                        {
                            delete FCurrLfn;
                            FCurrLfn = 0;
                        }
                    }
                }
            }
            else
            {
                if (FCurrLfn)
                {
                    if (FCurrLfn->Verify(entry))
                        AddLfn(pos, entry);
                    else
                        AddStd(pos, entry);

                    delete FCurrLfn;
                    FCurrLfn = 0;
                }
                else
                    AddStd(pos, entry);
            }
            break;
    }
}

/*##########################################################################
#
#   Name       : TFatDir::GrowFree
#
#   Purpose....: Grow free array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::GrowFree(int count)
{
    int i;
    int Size = 2 * count + 4;
    unsigned short int *NewArr;

    NewArr = new unsigned short int[Size];

    for (i = 0; i < FreeCount; i++)
        NewArr[i] = FreeArr[i];

    for (i = FreeCount; i < Size; i++)
        NewArr[i] = 0;

    if (FreeArr)
        delete FreeArr;

    FreeArr = NewArr;
    FreeCount = Size;
}

/*##########################################################################
#
#   Name       : TFatDir::ProcessFixed
#
#   Purpose....: Process fixed dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::ProcessFixed()
{
    TPartReq Req(FFat->GetServer());
    TPartReqEntry ReqEntry(&Req, FStartSector, FSectorCount);
    int Pos = 1;
    int i, j;
    struct TFatDirEntry *FatDirEntry;

    Req.WaitForever();

    if (Req.IsDone())
    {
        FatDirEntry = (struct TFatDirEntry *)ReqEntry.Map();

        for (i = 0; i < FSectorCount; i++)
        {
            for (j = 0; j < 16; j++)
            {
                if (FatDirEntry->Base[0])
                    Add(Pos, FatDirEntry);
                else
                    AddFree(Pos);

                FatDirEntry++;
                Pos++;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFatDir::ProcessCluster
#
#   Purpose....: Process cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::ProcessCluster(unsigned int Cluster, int *Pos)
{
    long long Sector = FFat->StartSector + (Cluster - 2) * FSectorsPerCluster;
    TPartReq Req(FFat->GetServer());
    TPartReqEntry ReqEntry(&Req, Sector, FSectorsPerCluster);
    struct TFatDirEntry *FatDirEntry;
    int j;
    int k;

    Req.WaitForever();

    if (Req.IsDone())
    {
        FatDirEntry = (struct TFatDirEntry *)ReqEntry.Map();

        for (j = 0; j < FSectorsPerCluster; j++)
        {
            for (k = 0; k < 16; k++)
            {
                if (FatDirEntry->Base[0])
                    Add(*Pos, FatDirEntry);
                else
                    AddFree(*Pos);

                FatDirEntry++;
                (*Pos)++;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFatDir::ProcessClusters
#
#   Purpose....: Process clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::ProcessClusters()
{
    int i;
    int pos = 1;

    for (i = 0; i < FClusterCount; i++)
        ProcessCluster(FClusterArr[i], &pos);
}

/*##########################################################################
#
#   Name       : TFatDir::GetClusterCount
#
#   Purpose....: Get cluster count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatDir::GetClusterCount()
{
    return FClusterCount;
}

/*##########################################################################
#
#   Name       : TFatDir::AddCluster
#
#   Purpose....: Add cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddCluster(unsigned int cluster)
{
    if (FClusterChain)
    {
        FClusterChain->Add(cluster);
        FClusterCount++;
    }
}

/*##########################################################################
#
#   Name       : TFatDir::GetCluster
#
#   Purpose....: Get cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatDir::GetCluster(int index)
{
    if (FClusterChain)
        if (index < FClusterCount)
            return FClusterArr[index];

    return 0;
}

/*##########################################################################
#
#   Name       : TFatDir::GetSector
#
#   Purpose....: Get sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFatDir::GetSector(int pos)
{
    int entry;
    int cluster;

    if (pos)
    {
        pos--;
        entry = pos / 16;

        if (FClusterChain)
        {
            cluster = entry / FSectorsPerCluster;
            entry = entry % FSectorsPerCluster;
            if (cluster < FClusterCount)
                return FStartSector + (FClusterArr[cluster] - 2) * FSectorsPerCluster + entry;
        }
        else
        {
            if (entry < FSectorCount)
                return FStartSector + entry;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFatDir::GetIndex
#
#   Purpose....: Convert pos to index
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatDir::GetIndex(int pos)
{
    if (pos)
    {
        pos--;
        return pos % 16;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFatDir::AddFree
#
#   Purpose....: Add free entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddFree(int pos)
{
    int entry;
    int offset;
    unsigned short int mask;

    if (pos)
    {
        pos--;
        entry = pos / 16;
        offset = pos % 16;
        mask = 1 << offset;

        if (entry >= FreeCount)
            GrowFree(entry);

        FreeArr[entry] |= mask;
        FreeEntries++;
    }
}

/*##########################################################################
#
#   Name       : TFatDir::RemoveFree
#
#   Purpose....: Remove free entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::RemoveFree(int pos)
{
    int entry;
    int offset;
    unsigned short int mask;

    if (pos)
    {
        pos--;
        entry = pos / 16;
        offset = pos % 16;
        mask = 1 << offset;

        if (entry < FreeCount)
        {
            FreeArr[entry] &= ~mask;
            FreeEntries--;
        }
    }
}

/*##########################################################################
#
#   Name       : TFatDir::AllocateEntry
#
#   Purpose....: Allocate entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatDir::AllocateEntry(int count)
{
    int i;
    int j;
    unsigned int val;
    int offset;
    int bits;
    int pos;
    int ao;
    int ai;
    int ab;

    for (i = 0; i < FreeCount; i++)
    {
        val = FreeArr[i];
        offset = 0;

        while (val)
        {
            while ((val & 1) == 0)
            {
                offset++;
                val = val >> 1;
            }

            ao = offset;
            ai = i;
            ab = 0;
            bits = 0;

            while ((val & 1) == 1)
            {
                bits++;
                ab++;
                val = val >> 1;

                if (ab == count)
                {
                    pos = 16 * ai + ao + 1;

                    for (j = 0; j < count; j++)
                        RemoveFree(pos + j);

                    return pos;
                }

                if (offset + bits == 16)
                {
                    offset = 0;
                    bits = 0;
                    i++;
                    if (i < FreeCount)
                        val = FreeArr[i];
                    else
                        return 0;
                }
            }
            offset += bits;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TFatDir::SetupStdEntry
#
#   Purpose....: Setup std entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::SetupStdEntry(struct TFatDirEntry *entry, int pos)
{
    long long Sector = GetSector(pos);
    TPartReq Req(FFat->GetServer());
    TPartReqEntry ReqEntry(&Req, Sector, 1, false);
    struct TFatDirEntry *e;

    Req.WaitForever();

    e = (struct TFatDirEntry *)ReqEntry.Map();
    e += GetIndex(pos);

    memcpy(e, entry, sizeof(struct TFatDirEntry));
    ReqEntry.Write();

    AddStd(pos, entry);
}

/*##########################################################################
#
#   Name       : TFatDir::SetupLfnEntry
#
#   Purpose....: Setup LFN entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::SetupLfnEntry(struct TFatDirEntry *entry, TFatLfn *lfn, const char *name)
{
    TPartReq *Req;
    TPartReqEntry *ReqEntry;
    long long Sector;
    long long Next;
    struct TFatDirEntry *e;
    char chksum;
    int i;
    int pos;
    int count = lfn->GetEntryCount();

    pos = AllocateEntry(count);

    if (pos)
    {
        Sector = GetSector(pos);

        Req = new TPartReq(FFat->GetServer());
        ReqEntry = new TPartReqEntry(Req, Sector, 1, false);

        Req->WaitForever();

        e = (struct TFatDirEntry *)ReqEntry->Map();
        e += GetIndex(pos);

        chksum = ::GetChkSum(entry);
        lfn->SetChkSum(chksum);

        for (i = 0; i < count; i++)
        {
            if (i == count - 1)
            {
                memcpy(e, entry, sizeof(struct TFatDirEntry));
                break;
            }
            else
                lfn->GetEntry(e);

            pos++;
            e++;

            Next = GetSector(pos);
            if (Next != Sector)
            {
                ReqEntry->Write();
                delete ReqEntry;
                delete Req;

                Sector = Next;

                Req = new TPartReq(FFat->GetServer());
                ReqEntry = new TPartReqEntry(Req, Sector, 1, false);

                Req->WaitForever();
                e = (struct TFatDirEntry *)ReqEntry->Map();
            }
        }

        ReqEntry->Write();

        delete ReqEntry;
        delete Req;

        AddLfn(pos, name, entry, count);

        return true;
    }
    else
        return false;

}

/*##########################################################################
#
#   Name       : TFatDir::CreateEntry
#
#   Purpose....: Create entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::CreateEntry(const char *name, unsigned int cluster, char attr)
{
    struct TFatDirEntry entry;
    TFatLfn lfn;
    long long RdosTime = RdosGetLongTime();
    int i;
    char str[14];
    int pos;

    entry.Attr = attr;
    entry.Resv1 = 0;
    entry.FileSize = 0;
    entry.ClusterLow = (unsigned short int)(cluster & 0xFFFF);
    entry.ClusterHi = (unsigned short int)(cluster >> 16);
    SetCreateTime(&entry, RdosTime);
    SetAccessTime(&entry, RdosTime);
    SetWriteTime(&entry, RdosTime);

    if (IsValidShortName(name))
    {
        SetEntryName(&entry, name);
        pos = AllocateEntry(1);
        if (pos)
        {
            SetupStdEntry(&entry, pos);
            return true;
        }
        else
            return false;
    }
    else
    {
        lfn.SetName(name);

        for (i = 1; i < 99999; i++)
        {
            GenerateShortName(name, i, str);
            if (!FindLfn(str) && Find(str) == DIR_NOT_FOUND)
                break;
        }
        SetEntryName(&entry, str);
        return SetupLfnEntry(&entry, &lfn, name);
    }
}

/*##########################################################################
#
#   Name       : TFatDir::UpdateEntry
#
#   Purpose....: Update entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::UpdateEntry(struct RdosDirEntry *direntry, struct RdosFileInfo *fileinfo)
{
    int pos = direntry->Pos;
    long long Sector = GetSector(pos);
    TPartReq Req(FFat->GetServer());
    TPartReqEntry ReqEntry(&Req, Sector, 1, false);
    struct TFatDirEntry *e;
    bool change = false;
    unsigned int cluster;

    Req.WaitForever();

    e = (struct TFatDirEntry *)ReqEntry.Map();
    e += GetIndex(pos);

    if (e->FileSize != fileinfo->CurrSize)
    {
        change = true;
        e->FileSize = (unsigned int)fileinfo->CurrSize;
        direntry->Size = fileinfo->CurrSize;
    }

    cluster = (e->ClusterHi << 16) | e->ClusterLow;
    if (cluster != direntry->Inode)
    {
        change = true;
        cluster = (unsigned int)direntry->Inode;
        e->ClusterLow = (unsigned short int)(cluster & 0xFFFF);
        e->ClusterHi = (unsigned short int)(cluster >> 16);
    }

    if (SetCreateTime(e, direntry->CreateTime))
        change = true;

    direntry->AccessTime = fileinfo->AccessTime;
    if (SetAccessTime(e, direntry->AccessTime))
        change = true;

    direntry->ModifyTime = fileinfo->ModifyTime;
    if (SetWriteTime(e, direntry->ModifyTime))
        change = true;

    if (change)
        ReqEntry.Write();

    return true;
}

/*##########################################################################
#
#   Name       : TFatDir::DeleteEntry
#
#   Purpose....: Delete entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::DeleteEntry(struct RdosDirEntry *direntry)
{
    int pos = direntry->Pos;
    int count;
    int i;
    TPartReq *Req;
    TPartReqEntry *ReqEntry;
    long long Sector;
    long long Next;
    char *e;

    count = DeleteLfn(pos);
    pos = pos - count + 1;

    Sector = GetSector(pos);

    Req = new TPartReq(FFat->GetServer());
    ReqEntry = new TPartReqEntry(Req, Sector, 1, false);

    Req->WaitForever();

    e = ReqEntry->Map();
    e += sizeof(struct TFatDirEntry) * GetIndex(pos);

    for (i = 0; i < count; i++)
    {
        *e = 0xE5;
        e += sizeof(struct TFatDirEntry);

        pos++;

        Next = GetSector(pos);
        if (Next != Sector)
        {
            ReqEntry->Write();
            delete ReqEntry;
            delete Req;

            Sector = Next;

            Req = new TPartReq(FFat->GetServer());
            ReqEntry = new TPartReqEntry(Req, Sector, 1, false);

            Req->WaitForever();
            e = ReqEntry->Map();
        }
    }

    ReqEntry->Write();

    delete ReqEntry;
    delete Req;

    return true;
}

/*##########################################################################
#
#   Name       : TFatDir::InitDir
#
#   Purpose....: Init directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::InitDir(TFat *Fat, unsigned int Cluster)
{
    long long RdosTime = RdosGetLongTime();
    TPartReq req(Fat->GetServer());
    TPartReqEntry e1(&req,Fat->StartSector + (Cluster - 2) * Fat->SectorsPerCluster, Fat->SectorsPerCluster, true);
    char *Data;

    req.WaitForever();

    Data = (char *)e1.Map();
    memset(Data, 0, 512 * Fat->SectorsPerCluster);

    e1.Write();
}

/*##########################################################################
#
#   Name       : TFatDir::InitDir
#
#   Purpose....: Init directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::InitDir(unsigned int Cluster)
{
    long long RdosTime = RdosGetLongTime();
    TPartReq req(FFat->GetServer());
    TPartReqEntry e1(&req,FFat->StartSector + (Cluster - 2) * FSectorsPerCluster, FSectorsPerCluster, true);
    char *Data;
    struct TFatDirEntry *entry;

    req.WaitForever();

    Data = (char *)e1.Map();
    memset(Data, 0, 512 * FSectorsPerCluster);

    entry = (struct TFatDirEntry *)Data;
    strcpy(entry->Base, ".          ");
    entry->Attr = 0x10;
    entry->Resv1 = 0;
    entry->FileSize = 0;
    entry->ClusterLow = (unsigned short int)(Cluster & 0xFFFF);
    entry->ClusterHi = (unsigned short int)(Cluster >> 16);
    SetCreateTime(entry, RdosTime);
    SetAccessTime(entry, RdosTime);
    SetWriteTime(entry, RdosTime);

    Cluster = (unsigned int)GetInode();
    entry = (struct TFatDirEntry *)(Data + 0x20);
    strcpy(entry->Base, "..         ");
    entry->Attr = 0x10;
    entry->Resv1 = 0;
    entry->FileSize = 0;
    entry->ClusterLow = (unsigned short int)(Cluster & 0xFFFF);
    entry->ClusterHi = (unsigned short int)(Cluster >> 16);
    SetCreateTime(entry, RdosTime);
    SetAccessTime(entry, RdosTime);
    SetWriteTime(entry, RdosTime);

    e1.Write();
}

/*##########################################################################
#
#   Name       : TFatDir::CreateDirEntry
#
#   Purpose....: Create dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::CreateDirEntry(const char *name)
{
    unsigned int Cluster;

    Cluster = FFat->AllocateCluster();

    if (Cluster)
    {
        InitDir(Cluster);
        return CreateEntry(name, Cluster, 0x10);
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TFatDir::CreateFileEntry
#
#   Purpose....: Create file entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatDir::CreateFileEntry(const char *name, int attr)
{
    char fattr = EncodeAttrib(attr);

    if (fattr & 0x10)
        return false;
    else
        return CreateEntry(name, 0, fattr);
}
