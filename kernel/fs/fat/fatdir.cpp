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
TFatDir::TFatDir(TDir *ParentDir, int ParentIndex)
  : TDir(ParentDir, ParentIndex)
{
    FCurrLfn = 0;
    LfnCount = 0;
    LfnMax = 4;
    LfnArr = new TLfnEntry[MaxCount];

    SectorCount = 0;
    FreeEntries = 0;
    SectorArr = 0;
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

    if (SectorArr)
        delete SectorArr;
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
    unsigned int cluster = GetCluster(fat);
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

    for (i = 0; i < MaxCount; i++)
    {
        strcpy(NewArr[i].Name, LfnArr[i].Name);
        NewArr[i].Pos = LfnArr[i].Pos;
    }

    for (i = MaxCount; i < Size; i++)
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
#   Name       : TFatDir::GrowSector
#
#   Purpose....: Grow sector array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::GrowSector(int count)
{
    int i;
    int Size = 2 * count + 4;
    struct TFatDirSector *NewArr;

    NewArr = new struct TFatDirSector[Size];

    for (i = 0; i < SectorCount; i++)
    {
        NewArr[i].Sector = SectorArr[i].Sector;
        NewArr[i].FreeMask = SectorArr[i].FreeMask;
    }

    for (i = SectorCount; i < Size; i++)
    {
        NewArr[i].Sector = 0;
        NewArr[i].FreeMask = 0;
    }

    if (SectorArr)
        delete SectorArr;

    SectorArr = NewArr;
    SectorCount = Size;
}

/*##########################################################################
#
#   Name       : TFatDir::AddSector
#
#   Purpose....: Add sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::AddSector(int pos, unsigned int sector)
{
    int entry;

    if (pos)
    {
        pos--;
        entry = pos / 16;

        if (entry >= SectorCount)
            GrowSector(entry);

        SectorArr[entry].Sector = sector;            
    }
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

        SectorArr[entry].FreeMask |= mask;            
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

        if (entry < SectorCount)
        {
            SectorArr[entry].FreeMask &= ~mask;            
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

    for (i = 0; i < SectorCount; i++)
    {
        val = SectorArr[i].FreeMask;
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
                    if (i < SectorCount)
                        val = SectorArr[i].FreeMask;
                    else
                        return 0;
                }
            }
            offset += bits;
        }
    }
    return 0;
}
