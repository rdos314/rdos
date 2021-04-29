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
TFatDir::TFatDir(long long parent)
  : TDir(parent)
{
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
    TDirEntry *entry = TDir::Add(name, cluster);

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
    char *src;
    char *dst;
    char ch;
    int i;
    unsigned short int cluster;

    src = entry->Base;
    dst = Name;

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

    Add(sector, offset, Name, entry);
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
    switch (entry->Base[0])
    {
        case ' ':
        case '.':
        case 0xE5:
        case 0:
            break;

        default:
            if (entry->Attr != 0xF)
                AddStd(sector, offset, entry);
            break;
    }
}
