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
# fat32.cpp
# Fat32 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat32.h"

struct TFatInfo
{
    int ExtSign;
    char Resv[480];
    int InfoSign;
    int FreeClusters;
    int NextCluster;
};

/*##########################################################################
#
#   Name       : TFa32::TFat32
#
#   Purpose....: Fat32 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat32::TFat32(TDiscServer *server, struct TBootSector *boot)
  : TFat(server, boot),
    Tab1(server),
    Tab2(server)
{
    int Free1;
    int Free2;

    FatSize = 32;
    PartSectors = boot->Sectors;
    if (!PartSectors)
        PartSectors = boot->SectorCount16;

    FatSectors = boot->FatSectors;
    if (!FatSectors)
        FatSectors = boot->FatSectors16;

    RootCluster = boot->RootCluster;
    InfoSector = boot->InfoSector;

    if (Validate())
    {
        Fat1Sector = ReservedSectors;
        Fat2Sector = Fat1Sector + FatSectors;

        RootSector = 0;
        StartSector = Fat2Sector + FatSectors;

        Clusters = PartSectors / SectorsPerCluster + 2;
        FreeClusters = 0;

        if (Clusters > 0x100000)
            if (InfoSector)
                ProcessInfoSector();

        Tab1.Setup(SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
        Tab2.Setup(SectorsPerCluster, Fat2Sector, FatSectors, Clusters);

        if (!FreeClusters)
        {
            Free1 = Tab1.GetFreeClusters();
            Free2 = Tab2.GetFreeClusters();

            if (Free1 > Free2)
                FreeClusters = Free2;
            else
                FreeClusters = Free1;
        }
    }
}

/*##########################################################################
#
#   Name       : TFat32::~TFat32
#
#   Purpose....: Fat32 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat32::~TFat32()
{
}

/*##########################################################################
#
#   Name       : TFat32::ProcessInfoSector
#
#   Purpose....: Process info sector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat32::ProcessInfoSector()
{
    TDiscReq req(Server);
    TDiscReqEntry e1(&req, InfoSector, 1);
    struct TFatInfo *info;

    req.WaitForever();

    info = (struct TFatInfo *)e1.Map();

    if (!info)
        return false;

    if (info->ExtSign != 0x41615252)
        return false;

    if (info->InfoSign != 0x61417272)
        return false;

    FreeClusters = info->FreeClusters;
    return true;
}

/*##########################################################################
#
#   Name       : TFat32::GetFreeSectors
#
#   Purpose....: Get free sectors
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TFat32::GetFreeSectors()
{
    return (long long)FreeClusters * (long long)SectorsPerCluster;
}
