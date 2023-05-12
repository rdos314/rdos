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
#include "cmdfact.h"

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
            delete FPartArr[i];

    delete FPartArr;
}

/*##########################################################################
#
#   Name       : TDisc::RunCmd
#
#   Purpose....: Run cmd
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDisc::RunCmd(int handle, char *msg)
{
    TCommandOutput out(handle);
    TCommandFactory::Run(&out, msg);
    return true;
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
    return false;
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
#   Name       : TDisc::Clear
#
#   Purpose....: Clear part array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Clear()
{
    int i;

    for (i = 0; i < FCurrPartCount; i++)
    {
        if (FPartArr[i])
        {
            delete FPartArr[i];
            FPartArr[i] = 0;
        }
    }

    FCurrPartCount = 0;
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
void TDisc::LoadPart()
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
        }
    }
}

/*##########################################################################
#
#   Name       : TDisc::Run
#
#   Purpose....: Run
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::Run()
{
    FServer->WaitForMsg(this);
}
