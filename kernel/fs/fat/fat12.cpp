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
# fs.cpp
# Fat FS class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat12.h"

/*##########################################################################
#
#   Name       : TFat12::TFat12
#
#   Purpose....: Fat12 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat12::TFat12(TPartServer *server, struct TBootSector *boot)
  : TFat(server, boot),
    Tab1(server),
    Tab2(server)
{
    unsigned int Free1;
    unsigned int Free2;

    FatSize = 12;
    PartSectors = boot->SectorCount16;
    if (!PartSectors)
        PartSectors = boot->Sectors;

    FatSectors = boot->FatSectors16;
    if (!FatSectors)
        FatSectors = boot->FatSectors;

    RootDirEntries = boot->RootDirEntries;

    if (Validate())
    {
        FatTable1 = &Tab1;
        FatTable2 = &Tab2;

        Fat1Sector = ReservedSectors;
        Fat2Sector = Fat1Sector + FatSectors;
        RootSector = Fat2Sector + FatSectors;
        StartSector = RootSector + RootDirEntries / 16;

        Clusters = PartSectors / SectorsPerCluster + 2;

        if (Clusters > 0xFF0)
            Clusters = 0xFF0;

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
#   Name       : TFat12::~TFat12
#
#   Purpose....: Fat12 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFat12::~TFat12()
{
}

/*##########################################################################
#
#   Name       : TFat12::CacheRootDir
#
#   Purpose....: CacheRootDir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFat12::CacheRootDir()
{
    return CacheFixedDir(RootSector, RootDirEntries);
}
