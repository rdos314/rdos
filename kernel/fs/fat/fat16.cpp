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
# fat16.cpp
# Fat16 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat16.h"

/*##########################################################################
#
#   Name       : TFat16::TFat16
#
#   Purpose....: Fat16 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat16::TFat16(TDiscServer *server, struct TBootSector *boot)
  : TFat(server, boot),
    Tab1(server),
    Tab2(server)
{
    int Free1;
    int Free2;

    FatSize = 16;
    PartSectors = boot->SectorCount16;
    if (!PartSectors)
        PartSectors = boot->Sectors;

    FatSectors = boot->FatSectors16;
    if (!FatSectors)
        FatSectors = boot->FatSectors;

    RootDirEntries = boot->RootDirEntries;

    if (Validate())
    {
        Fat1Sector = ReservedSectors;
        Fat2Sector = Fat1Sector + FatSectors;
        RootSector = Fat2Sector + FatSectors;
        StartSector = RootSector + RootDirEntries / 16;

        Clusters = PartSectors / SectorsPerCluster + 2;

        if (Clusters > 0x10000)
            Clusters = 0x10000;

        Tab1.Setup(SectorsPerCluster, Fat1Sector, FatSectors, Clusters);
        Tab2.Setup(SectorsPerCluster, Fat2Sector, FatSectors, Clusters);

        Free1 = Tab1.GetFreeClusters();
        Free2 = Tab2.GetFreeClusters();

        if (Free1 > Free2)
            FreeClusters = Free2;
        else
            FreeClusters = Free1;
    }
}

/*##########################################################################
#
#   Name       : TFat16::~TFat16
#
#   Purpose....: Fat16 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat16::~TFat16()
{
}

/*##########################################################################
#
#   Name       : TFat16::GetClusterChain
#
#   Purpose....: Get cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCluster *TFat16::GetClusterChain(unsigned int Cluster)
{
    TCluster *Chain = new TCluster;
    unsigned int NextCluster1;
    unsigned int NextCluster2;

    while (Cluster < Clusters)
    {
        Chain->Add(Cluster);

        NextCluster1 = Tab1.GetClusterLink(Cluster);
        NextCluster2 = Tab2.GetClusterLink(Cluster);

        if (NextCluster1 == NextCluster2)
            Cluster = NextCluster1;
        else
        {
            if (NextCluster1 >= Clusters && NextCluster2 >= Clusters)
                break;

            if (NextCluster1 < Clusters && NextCluster2 < Clusters)
                break;

            if (NextCluster1 > NextCluster2)
                Cluster = NextCluster2;
            else
                Cluster = NextCluster1;
        }
    }

    return Chain;
}
