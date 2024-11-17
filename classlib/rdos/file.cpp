/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# file.cpp
# File class
#
########################################################################*/

#include <string.h>
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Constructor for TFile
#
#   In params..: Filename to open
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const char *FileName)
{
    int len;

    FHandle = RdosOpenHandle(FileName, O_RDWR);

    if (FHandle < 0)
        FHandle = 0;

    if (FHandle)
        FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    else
        FMap = 0;

    if (FMap)
        FFileName = 0;
    else
    {
        len = strlen(FileName);
        FFileName = new char[len + 1];
        strcpy(FFileName, FileName);
    }
    FLastIndex = -1;
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Constructor for TFile
#
#   In params..: Filename to create
#                                File attribute
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const char *FileName, int Attrib)
{
    int len;

    FHandle = RdosOpenHandle(FileName, O_CREAT | O_RDWR);

    if (FHandle < 0)
        FHandle = 0;

    if (FHandle)
        FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    else
        FMap = 0;

    if (FMap)
        FFileName = 0;
    else
    {
        len = strlen(FileName);
        FFileName = new char[len + 1];
        strcpy(FFileName, FileName);
    }
    FLastIndex = -1;
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Copy constructor for TFile
#
#   In params..: file to duplicate handle on
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const TFile &file)
{
    int len;

    if (file.FFileName)
    {
        len = strlen(file.FFileName);
        FFileName = new char[len + 1];
        strcpy(FFileName, file.FFileName);
    }
    else
        FFileName = 0;

    FMap = 0;

    if (file.FHandle)
    {
        FHandle = RdosDupHandle(file.FHandle);

        if (FHandle < 0)
            FHandle = 0;

        if (FHandle)
            FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    }
    else
        FHandle = 0;

    FLastIndex = file.FLastIndex;
}

/*##########################################################################
#
#   Name       : TFile::~TFile
#
#   Purpose....: Destructor for TFile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::~TFile()
{
    if (FHandle)
        RdosCloseHandle(FHandle);

    if (FFileName)
        delete FFileName;
}

/*##########################################################################
#
#   Name       : TFile::IsOpen
#
#   Purpose....: Check if file is open
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open
#
##########################################################################*/
int TFile::IsOpen()
{
    if (FHandle)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::IsDevice
#
#   Purpose....: Check if file is device
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and device
#
##########################################################################*/
int TFile::IsDevice()
{
    if (FHandle)
        return RdosIsHandleDevice(FHandle);
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::IsFile
#
#   Purpose....: Check if file is ordinary file
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and file
#
##########################################################################*/
int TFile::IsFile()
{
    if (FHandle)
        return !RdosIsHandleDevice(FHandle);
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::GetFileName
#
#   Purpose....: Get file name
#
#   In params..: *
#   Out params.: *
#   Returns....: Filename
#
##########################################################################*/
const char *TFile::GetFileName()
{
    if (FMap)
        return FMap->Info->Name;
    else
        return FFileName;
}

/*##########################################################################
#
#   Name       : TFile::GetSize
#
#   Purpose....: Get file size
#
#   In params..: *
#   Out params.: *
#   Returns....: File size
#
##########################################################################*/
long long TFile::GetSize()
{
    if (FMap)
        return FMap->Info->CurrSize;
    else
    {
        if (FHandle)
            return RdosGetHandleSize(FHandle);
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TFile::SetSize
#
#   Purpose....: Set file size
#
#   In params..: File size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetSize(long long Size)
{
    if (FHandle)
    {
        RdosSetHandleSize(FHandle, Size);

        if (FMap && FMap->Update)
            RdosUpdateHandle(FHandle);
    }
}

/*##########################################################################
#
#   Name       : TFile::GetPos
#
#   Purpose....: Get file position
#
#   In params..: *
#   Out params.: *
#   Returns....: File position
#
##########################################################################*/
long long TFile::GetPos()
{
    if (FMap)
        return FMap->Handle->PosArr[FMapIndex - 1];
    else
    {
        if (FHandle)
            return RdosGetHandlePos(FHandle);
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TFile::SetPos
#
#   Purpose....: Set file position
#
#   In params..: File position
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetPos(long long Pos)
{
    if (FMap)
        FMap->Handle->PosArr[FMapIndex - 1] = Pos;
    else
    {
        if (FHandle)
            RdosSetHandlePos(FHandle, Pos);
    }
}

/*##########################################################################
#
#   Name       : TFile::GetTime
#
#   Purpose....: Get file time & date
#
#   In params..: File time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TFile::GetTime()
{
    unsigned long msb, lsb;

    if (FHandle)
    {
        RdosGetHandleModifyTime(FHandle, &msb, &lsb);
        return TDateTime(msb, lsb);
    }

    return TDateTime();
}

/*##########################################################################
#
#   Name       : TFile::SetTime
#
#   Purpose....: Set file time & date
#
#   In params..: File time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetTime(const TDateTime &time)
{
    long msb, lsb;

    if (FHandle)
    {
        msb = time.GetMsb();
        lsb = time.GetLsb();
        RdosSetHandleModifyTime(FHandle, msb, lsb);
    }
}

/*##########################################################################
#
#   Name       : TFile::VfsFind
#
#   Purpose....: VFS find
#
#   In params..: pos, size
#   Out params.: *
#   Returns....: Buffer index
#
##########################################################################*/
int TFile::VfsFind(long long Pos)
{
    int Step = 0x80;
    int Curr = 0;
    unsigned char index;
    long long Diff;

    for (;;)
    {
        if (FMap->Update)
            RdosUpdateHandle(FHandle);

        index = FMap->SortedArr[Curr + Step];
        if (index != 0xFF)
        {
            Diff = Pos - FMap->MapArr[index].Pos;
            if (Diff >= 0)
            {
                Curr += Step;

                if (Diff < FMap->MapArr[index].Size)
                    return Curr;
            }
        }
        if (Step)
            Step = Step >> 1;
        else
            break;
    }
    return -1;
}

/*##########################################################################
#
#   Name       : TFile::VfsReadOne
#
#   Purpose....: Do one read
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
int TFile::VfsReadOne(int index, char *buf, long long pos, int size)
{
    int diff;
    int count = 0;
    char *src;
    struct RdosFileMapEntry *entry;

    index = FMap->SortedArr[index];

    if (index >= 0)
    {
        entry = &FMap->MapArr[index];
        diff = pos - entry->Pos;

        if (((long)entry->Base & 0xFFF) != 0 || (entry->Size & 0xFFF) != 0)
        {
            SetPos(pos);
            count = RdosReadHandle(FHandle, buf, size);
        }
        else
        {
            if (entry->Base && diff >= 0)
            {
                count = entry->Size - diff;

                if (count > 0)
                {
                    src = entry->Base + diff;
                    if (count > size)
                        count = size;

                    memcpy(buf, src, count);
                }
                else
                    count = 0;
            }
        }
    }

    return count;
}

/*##########################################################################
#
#   Name       : TFile::VfsRead
#
#   Purpose....: VFS read
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
int TFile::VfsRead(void *Buf, int Size)
{
    long long Pos = GetPos();
    long long TotalSize = GetSize();
    int count;
    int diff;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;

    if (FMap->Update)
        RdosUpdateHandle(FHandle);

    if (Pos + Size > TotalSize)
        Size = TotalSize - Pos;

    if (Size < 0)
        Size = 0;

    RdosEnterFutex(&FMap->Handle->Futex);

    if (FLastIndex < 0)
        FLastIndex = VfsFind(Pos);

    while (Size)
    {
        if (FLastIndex >= 0)
        {
            count = VfsReadOne(FLastIndex, ptr, Pos, Size);
            ptr += count;
            Size -= count;
            ret += count;
            Pos += count;
        }

        if (Size)
        {
            for (i = 0; i < 10; i++)
            {
                RdosLeaveFutex(&FMap->Handle->Futex);

                RdosMapHandle(FHandle, Pos, Size);

                RdosEnterFutex(&FMap->Handle->Futex);
                FLastIndex = VfsFind(Pos);
                if (FLastIndex >= 0)
                    break;
            }

            if (FLastIndex < 0)
                break;
        }
    }

    RdosLeaveFutex(&FMap->Handle->Futex);

    SetPos(Pos);
    return ret;
}

/*##########################################################################
#
#   Name       : TFile::Read
#
#   Purpose....: Read data from file
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
int TFile::Read(void *Buf, int Size)
{
    if (FMap)
        return VfsRead(Buf, Size);
    else
    {
        if (FHandle)
            return RdosReadHandle(FHandle, Buf, Size);
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TFile::VfsWriteOne
#
#   Purpose....: Do one write
#
#   In params..:
#   Out params.: *
#   Returns....:
#
##########################################################################*/
int TFile::VfsWriteOne(int index, char *buf, long long pos, int size)
{
    int diff;
    int count = 0;
    char *dst;
    struct RdosFileMapEntry *entry;
    long long FileSize;

    index = FMap->SortedArr[index];

    if (index >= 0)
    {
        entry = &FMap->MapArr[index];
        diff = pos - entry->Pos;

        if (((long)entry->Base & 0xFFF) != 0 || (entry->Size & 0xFFF) != 0)
        {
            SetPos(pos);
            count = RdosWriteHandle(FHandle, buf, size);
        }
        else
        {
            if (entry->Base && diff >= 0)
            {
                count = entry->Size - diff;

                if (count > 0)
                {
                    dst = entry->Base + diff;
                    if (count > size)
                        count = size;

                    memcpy(dst, buf, count);

                    FileSize = pos + count;
                    if (FileSize > FMap->Handle->ReqSize)
                        FMap->Handle->ReqSize = FileSize;
                }
                else
                    count = 0;
            }
        }
    }

    return count;
}

/*##########################################################################
#
#   Name       : TFile::VfsWrite
#
#   Purpose....: VFS write
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
int TFile::VfsWrite(const void *Buf, int Size)
{
    long long Pos = GetPos();
    long long TotalSize = GetSize();
    int count;
    int diff;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    struct RdosFileInfo *info = FMap->Info;
    long long Grow;

    if (FMap->Update)
        RdosUpdateHandle(FHandle);

    Grow = Pos + Size - info->DiscSize;

    if (Grow > 0)
        RdosGrowHandle(FHandle, info->DiscSize, Grow);

    RdosEnterFutex(&FMap->Handle->Futex);

    if (FLastIndex < 0 || Grow > 0)
        FLastIndex = VfsFind(Pos);

    while (Size)
    {
        if (FLastIndex >= 0)
        {
            count = VfsWriteOne(FLastIndex, ptr, Pos, Size);
            ptr += count;
            Size -= count;
            ret += count;
            Pos += count;
        }

        if (Size)
        {
            for (i = 0; i < 10; i++)
            {
                RdosLeaveFutex(&FMap->Handle->Futex);

                Grow = Pos + Size - info->DiscSize;

                if (Grow > 0)
                    RdosGrowHandle(FHandle, info->DiscSize, Grow);
                else
                    RdosMapHandle(FHandle, Pos, Size);

                RdosEnterFutex(&FMap->Handle->Futex);
                FLastIndex = VfsFind(Pos);
                if (FLastIndex >= 0)
                    break;
            }

            if (FLastIndex < 0)
                break;
        }
    }

    RdosLeaveFutex(&FMap->Handle->Futex);

    SetPos(Pos);
    return ret;
}

/*##########################################################################
#
#   Name       : TFile::Write
#
#   Purpose....: Write data to file
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes written
#
##########################################################################*/
int TFile::Write(const void *Buf, int Size)
{
    if (FMap)
        return VfsWrite(Buf, Size);
    else
    {
        if (FHandle)
            return RdosWriteHandle(FHandle, Buf, Size);
        else
            return 0;
    }
}

/*##########################################################################
#
#   Name       : TFile::Write
#
#   Purpose....: Write data to file
#
#   In params..: buf
#   Out params.: *
#   Returns....: Bytes written
#
##########################################################################*/
int TFile::Write(const char *str)
{
    return Write(str, strlen(str));
}
