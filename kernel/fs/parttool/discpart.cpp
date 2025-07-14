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
# discpart.cpp
# Discpart base class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "str.h"
#include "discpart.h"

/*##########################################################################
#
#   Name       : TPartition::TPartition
#
#   Purpose....: Partition constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartition::TPartition(long long StartSector, long long SectorCount)
{
    FStartSector = StartSector;
    FSectorCount = SectorCount;
    FPartType = PART_TYPE_UNKNOWN;

    Handle = 0;
}

/*##########################################################################
#
#   Name       : TPartition::~TPartition
#
#   Purpose....: Partition destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartition::~TPartition()
{
}

/*##########################################################################
#
#   Name       : TPartition::SetType
#
#   Purpose....: Set partition type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartition::SetType(int PartType)
{
    FPartType = PartType;
}

/*##########################################################################
#
#   Name       : TPartition::GetType
#
#   Purpose....: Get partition type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartition::GetType()
{
    return FPartType;
}

/*##########################################################################
#
#   Name       : TPartition::GetDrive
#
#   Purpose....: Get partition drive
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TPartition::GetDrive()
{
    return ServGetVfsPartDrive(Handle);
}

/*##########################################################################
#
#   Name       : TPartition::GetStartSector
#
#   Purpose....: Get start sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TPartition::GetStartSector()
{
    return FStartSector;
}

/*##########################################################################
#
#   Name       : TPartition::GetSectorCount
#
#   Purpose....: Get sector count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TPartition::GetSectorCount()
{
    return FSectorCount;
}

/*##########################################################################
#
#   Name       : TPartition::CheckInside
#
#   Purpose....: Check if sector is inside partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TPartition::CheckInside(long long sector, int count)
{
    if (sector >= FStartSector)
    {
        if (sector >= FStartSector + FSectorCount)
            return false;
        else
            return true;
    }
    else
    {
        if (sector + count > FStartSector)
            return true;
        else
            return false;
    }
}

/*##########################################################################
#
#   Name       : TDisc::TDisc
#
#   Purpose....: Disc contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisc::TDisc(TDiscServer *server)
{
    int i;

    FServer = server;
    FStopped = false;

    FBytesPerSector = FServer->GetBytesPerSector();
    FSectorCount = FServer->GetDiscSectors();

    FCurrPartCount = 0;
    FMaxPartCount = 4;
    FPartArr = new TPartition*[FMaxPartCount];

    for (i = 0; i < FMaxPartCount; i++)
        FPartArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TDisc::~TDisc
#
#   Purpose....: Disc destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDisc::~TDisc()
{
    int i;

    for (i = 0; i < FMaxPartCount; i++)
        if (FPartArr[i])
            DeletePart(FPartArr[i]);

    delete FPartArr;
}

/*##########################################################################
#
#   Name       : TDisc::SizeToCount
#
#   Purpose....: Size in bytes to sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::SizeToCount(int size)
{
    int count = size / FBytesPerSector;

    if (count * FBytesPerSector != size)
        count++;

    return count;
}

/*##########################################################################
#
#   Name       : TDisc::IsInsidePartition
#
#   Purpose....: Check if sector is inside a partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDisc::IsInsidePartition(long long sector, int count)
{
    int i;

    for (i = 0; i < FCurrPartCount; i++)
        if (FPartArr[i]->CheckInside(sector, count))
            return true;

    return false;
}

/*##########################################################################
#
#   Name       : TDisc::ReadSector
#
#   Purpose....: Read sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::ReadSector(long long sector, char *buf, int size)
{
    char *Data;
    int count = SizeToCount(size);

    if (IsInsidePartition(sector, count))
        return false;

    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, sector, count);

    req.WaitForever();

    Data = (char *)e1.Map();
    memcpy(buf, Data, size);

    return true;
}

/*##########################################################################
#
#   Name       : TDisc::WriteSector
#
#   Purpose....: Write sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::WriteSector(long long sector, char *buf, int size)
{
    char *Data;
    int count = SizeToCount(size);

    if (IsInsidePartition(sector, count))
        return false;

    TDiscReq req(FServer);
    TDiscReqEntry e1(&req, sector, count, false);

    req.WaitForever();

    Data = (char *)e1.Map();
    memcpy(Data, buf, size);

    e1.Write();

    return true;
}

/*##########################################################################
#
#   Name       : TDisc::GetServer
#
#   Purpose....: Get disc server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscServer *TDisc::GetServer()
{
    return FServer;
}

/*##########################################################################
#
#   Name       : TDisc::GetDiscNr
#
#   Purpose....: Get disc #
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::GetDiscNr()
{
    int handle = FServer->GetHandle();

    handle = (handle >> 8) & 0xFF;
    return handle - 1;    
}

/*##########################################################################
#
#   Name       : TDisc::GetSectorCount
#
#   Purpose....: Get sector count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDisc::GetSectorCount()
{
    return FSectorCount;
}

/*##################  TDisc::GetCached  #############
*   Purpose....: Get current cache size                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDisc::GetCached()
{
    return RdosGetDiscCache(GetDiscNr());
}

/*##################  TDisc::GetLocked  #############
*   Purpose....: Get current locked size                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDisc::GetLocked()
{
    return RdosGetDiscLocked(GetDiscNr());
}

/*##########################################################################
#
#   Name       : TDisc::FsTypeToName
#
#   Purpose....: Convert FS type to name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TDisc::FsTypeToName(int type)
{
    switch (type)
    {
        case PART_TYPE_FAT12:
            return "FAT12";

        case PART_TYPE_FAT16:
            return "FAT16";

        case PART_TYPE_FAT32:
            return "FAT32";

        case PART_TYPE_FAT:
            return "FAT";

        case PART_TYPE_EFI:
            return "EFI";

        default:
            return "UNKNOWN";
    }
}

/*##########################################################################
#
#   Name       : TDisc::FsNameToType
#
#   Purpose....: Convert FS type to name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::FsNameToType(const char *FsName)
{
    if (!strcmp(FsName, "FAT12"))
        return PART_TYPE_FAT12;

    if (!strcmp(FsName, "FAT16"))
        return PART_TYPE_FAT16;

    if (!strcmp(FsName, "FAT32"))
        return PART_TYPE_FAT32;

    if (!strcmp(FsName, "FAT"))
        return PART_TYPE_FAT;

    if (!strcmp(FsName, "EFI"))
        return PART_TYPE_EFI;

    return 0;
}

/*##########################################################################
#
#   Name       : TDisc::DeletePart
#
#   Purpose....: Delete partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::DeletePart(TPartition *Part)
{
    if (Part)
    {
        ServStopVfsPartition(Part->Handle);
        delete Part;
    }
}

/*##########################################################################
#
#   Name       : TDisc::GrowPart
#
#   Purpose....: Grow part array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::GrowPart()
{
    int i;
    int Size = 2 * FMaxPartCount;
    TPartition **NewArr;

    NewArr = new TPartition*[Size];

    for (i = 0; i < FMaxPartCount; i++)
        NewArr[i] = FPartArr[i];

    for (i = FMaxPartCount; i < Size; i++)
        NewArr[i] = 0;

    delete FPartArr;
    FPartArr = NewArr;
    FMaxPartCount = Size;
}

/*##########################################################################
#
#   Name       : TDisc::Sort
#
#   Purpose....: Sort partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Sort()
{
    int i;
    bool Changed;
    TPartition *Temp;

    Changed = true;

    while (Changed)
    {
        Changed = false;

        for (i = 1; i < FCurrPartCount; i++)
        {
            if (FPartArr[i-1]->GetStartSector() > FPartArr[i]->GetStartSector())
            {
                Temp = FPartArr[i-1];
                FPartArr[i-1] = FPartArr[i];
                FPartArr[i] = Temp;
                Changed = true;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TDisc::Add
#
#   Purpose....: Add partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Add(TPartition *part)
{
    if (FCurrPartCount == FMaxPartCount)
        GrowPart();

    FPartArr[FCurrPartCount] = part;
    FCurrPartCount++;
    Sort();
}

/*##########################################################################
#
#   Name       : TDisc::Remove
#
#   Purpose....: Remove partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Remove(TPartition *part)
{
    int i;
    int j;

    for (i = 0; i < FCurrPartCount; i++)
    {
        if (FPartArr[i] == part)
        {
            FPartArr[i] = 0;
            FCurrPartCount--;

            for (j = i; j < FCurrPartCount; j++)
                FPartArr[j] = FPartArr[j+1];

            FPartArr[FCurrPartCount] = 0;

            DeletePart(part);
            break;
        }
    }
}

/*##########################################################################
#
#   Name       : TDisc::LoadPart
#
#   Purpose....: Load partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDisc::LoadPart()
{
    int PartNr;
    TPartition *Part;
    int Handle = FServer->GetHandle();
    long long Start;
    long long Size;
    int Type;

    for (PartNr = 0; PartNr < FCurrPartCount; PartNr++)
    {
        Part = FPartArr[PartNr];
        if (Part)
        {
            Start = Part->GetStartSector();
            Size = Part->GetSectorCount();
            Type = Part->GetType();
            Part->Handle = ServLoadVfsPartition(Handle, Type, Start, Size);
            ServStartVfsPartition(Part->Handle);
        }
    }
    return true;
}

/*##########################################################################
#
#   Name       : TDisc::AllocateSectors
#
#   Purpose....: Allocate sectors from non-partitioned space
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TDisc::AllocateSectors(long long Start, long long Count)
{
    long long pos = Start;
    long long size;
    int i;

    for (i = 0; i < FCurrPartCount; i++)
    {
        size = FPartArr[i]->GetStartSector() - pos;
        if (size >= Count)
            return pos;

        pos = FPartArr[i]->GetStartSector() + FPartArr[i]->GetSectorCount();
    }
            
    size = GetSectorCount() - pos;
    if (size > 0)
        return pos;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TDisc::FormatPart
#
#   Purpose....: Format partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::FormatPart(const char *FsName, long long *Start, long long *Count, int *Type)
{
    int Handle = FServer->GetHandle();
    int FsType = FsNameToType(FsName);
    int PartHandle;
    int PartType = 0;

    PartHandle = ServLoadVfsPartition(Handle, FsType, *Start, *Count);

    if (PartHandle)
    {
        Handle = ServFormatVfsPartition(PartHandle);
        *Count = 0;

        if (Handle)
        {
            *Start = ServGetVfsStartSector(Handle);
            *Count = ServGetVfsSectors(Handle);
            *Type = ServGetVfsPartType(Handle);

            if (*Count)
                return PartHandle;
        }
            
    }

    return 0;

}

/*##########################################################################
#
#   Name       : TDisc::Stop
#
#   Purpose....: Stop disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Stop()
{
    int PartNr;
    TPartition *Part;

    FStopped = true;

    for (PartNr = 0; PartNr < FCurrPartCount; PartNr++)
    {
        Part = FPartArr[PartNr];
        if (Part)
        {
            DeletePart(Part);
            FPartArr[PartNr] = 0;
        }
    }

    FCurrPartCount = 0;
}
