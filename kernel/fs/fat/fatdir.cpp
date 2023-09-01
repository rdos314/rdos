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
}

/*#########################################################################
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
unsigned int TFatDir::GetCluster(struct TFatDirEntry *entry)
{
    unsigned int cluster;
    char *ptr = (char *)&cluster;

    memcpy(ptr, &entry->ClusterLow, 2);
    memcpy(ptr + 2, &entry->ClusterHi, 2);

    return cluster;
}

/*##########################################################################
#
#   Name       : TFatDir::DecodeTime
#
#   Purpose....: Decode time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFatDir::DecodeTime(short int Date, short int Time)
{
    int sec = Time & 0x1F;
    int min = (Time >> 5) & 0x3F;
    int hour = (Time >> 11) & 0x1F;
    int day = Date & 0x1F;
    int month = (Date >> 5) & 0xF;
    int year = (Date >> 9) & 0x7F;
    unsigned long lsb, msb;
    long long res;

    year += 1980;
    sec = 2 * sec;

    lsb = RdosCodeLsbTics(min, sec, 0, 0);
    msb = RdosCodeMsbTics(year, month, day, hour);

    res = lsb + ((long long)msb << 32);
    return res;
}

/*##########################################################################
#
#   Name       : TFatDir::DecodeAttrib
#
#   Purpose....: Decode attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatDir::DecodeAttrib(char attrib)
{
    return attrib;
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
void TFatDir::Add(long long sector, int offset, const char *name, struct TFatDirEntry *fat)
{
    unsigned int cluster = GetCluster(fat);
    RdosDirEntry *entry;

    Section.Enter();

    entry = TDir::Add(name, cluster);

    if (fat->CrDate)
        entry->CreateTime = DecodeTime(fat->CrDate, fat->CrTime);

    if (fat->WrDate)
        entry->ModifyTime = DecodeTime(fat->WrDate, fat->WrTime);

    if (fat->AcDate)
        entry->AccessTime = DecodeTime(fat->AcDate, 0);

    entry->Attrib = DecodeAttrib(fat->Attr);
    entry->Size = fat->FileSize;
    entry->Sector = sector;
    entry->Offset = offset;

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
        NewArr[i].Sector = LfnArr[i].Sector;
        NewArr[i].Offset = LfnArr[i].Offset;
    }

    for (i = MaxCount; i < Size; i++)
    {
        NewArr[i].Name[0] = 0;
        NewArr[i].Sector = 0;
        NewArr[i].Offset = 0;
    }

    delete LfnArr;
    LfnArr = NewArr;
    LfnMax = Size;
}

/*##########################################################################
#
#   Name       : TFatDir::GetEntryName
#
#   Purpose....: Get entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::GetEntryName(char *name, struct TFatDirEntry *entry)
{
    char *src;
    char *dst;
    char ch;
    int i;

    src = entry->Base;
    dst = name;

    for (i = 0; i < 8; i++)
    {
        if (*src == ' ')
            break;
        else
        {
            ch = tolower(*src);
            *dst = ch;
            src++;
            dst++;
        }
    }

    src = entry->Ext;
    if (*src != ' ')
    {
        *dst = '.';
        dst++;

        for (i = 0; i < 3; i++)
        {
            if (*src == ' ')
                break;
            else
            {
                ch = tolower(*src);
                *dst = ch;
                src++;
                dst++;
            }
        }
    }

    *dst = 0;
}

/*##########################################################################
#
#   Name       : TFatDir::SetEntryName
#
#   Purpose....: Set entry name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatDir::SetEntryName(struct TFatDirEntry *entry, const char *name)
{
    const char *src;
    char *dst;
    char ch;
    int i;

    src = name;
    dst = entry->Base;

    for (i = 0; i < 8; i++)
    {
        if (*src == '.' || *src == 0)
            ch = ' ';
        else
        {
            ch = toupper(*src);
            src++;
        }

        *dst = ch;
        dst++;
    }

    dst = entry->Ext;

    if (*src == '.')
        src++;

    for (i = 0; i < 3; i++)
    {
        if (*src == 0)
            ch = ' ';
        else
        {
            ch = toupper(*src);
            src++;
        }

        *dst = ch;
        dst++;
    }
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
void TFatDir::AddStd(long long sector, int offset, struct TFatDirEntry *entry)
{
    char Name[16];

    GetEntryName(Name, entry);
    Add(sector, offset, Name, entry);
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
void TFatDir::AddLfn(long long sector, int offset, struct TFatDirEntry *entry)
{
    int size = FCurrLfn->GetNameSize();
    char *buf = new char[size];

    if (LfnMax == LfnCount)
       GrowLfn();

    GetEntryName(LfnArr[LfnCount].Name, entry);
    LfnArr[LfnCount].Sector = sector;
    LfnArr[LfnCount].Offset = offset;

    LfnCount++;

    FCurrLfn->GetName(buf);
    Add(sector, offset, buf, entry);

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
void TFatDir::Add(long long sector, int offset, struct TFatDirEntry *entry)
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
                        AddLfn(sector, offset, entry);
                    else
                        AddStd(sector, offset, entry);

                    delete FCurrLfn;
                    FCurrLfn = 0;
                }
                else
                    AddStd(sector, offset, entry);
            }
            break;
    }
}
