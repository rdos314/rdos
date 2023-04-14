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
#   Name       : TDisc::OpenPart
#
#   Purpose....: Open partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::OpenPart(int handle)
{
}

/*##########################################################################
#
#   Name       : TDisc::ClosePart
#
#   Purpose....: Close partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDisc::ClosePart(int handle)
{
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
