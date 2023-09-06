/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# fatdir.cpp
# FAT directory class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <rdos.h>
#include "fatdir.h"

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
TFatDir::TFatDir(long long RootSector, int Sectors)
  : TDir(0, 0)
{
    Init();

    FStartSector = RootSector;
    FSectorCount = Sectors;
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
TFatDir::TFatDir(TDir *ParentDir, int ParentIndex, long long StartSector, int SectorsPerCluster)
  : TDir(ParentDir, ParentIndex)
{
    Init();

    FStartSector = StartSector;
    FSectorsPerCluster = SectorsPerCluster;
    FClusterChain = new TCluster();
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
        entry->CreateTime = DecodeTime(fat->CrDate, fat->CrTime, fat->CrMs);

    if (fat->WrDate)
        entry->ModifyTime = DecodeTime(fat->WrDate, fat->WrTime, 0);

    if (fat->AcDate)
        entry->AccessTime = DecodeTime(fat->AcDate, 0, 0);

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
    }

    for (i = LfnMax; i < Size; i++)
    {
        NewArr[i].Name[0] = 0;
        NewArr[i].Pos = 0;
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
    char *buf = new char[size];

    if (LfnMax == LfnCount)
       GrowLfn();

    GetEntryName(entry, LfnArr[LfnCount].Name);
    LfnArr[LfnCount].Pos = pos;

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
void TFatDir::AddLfn(int pos, const char *name, struct TFatDirEntry *entry)
{
    if (LfnMax == LfnCount)
       GrowLfn();

    GetEntryName(entry, LfnArr[LfnCount].Name);
    LfnArr[LfnCount].Pos = pos;

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
    if (FClusterChain)
        return FClusterChain->GetSize();
    else
        return 0;
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
        FClusterChain->Add(cluster);
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
    unsigned int *chain;

    if (FClusterChain)
    {
        chain = FClusterChain->GetChain();
        if (index < FClusterChain->GetSize())
            return chain[index];
    }
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
    unsigned int *chain;

    if (pos)
    {
        pos--;
        entry = pos / 16;

        if (FClusterChain)
        {
            cluster = entry / FSectorsPerCluster;
            entry = entry % FSectorsPerCluster;
            if (cluster < FClusterChain->GetSize())
            {
                chain = FClusterChain->GetChain();
                chain += cluster;
                return FStartSector + (*chain - 2) * FSectorsPerCluster + entry;            
            }
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
    unsigned short int *NewArr;

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
