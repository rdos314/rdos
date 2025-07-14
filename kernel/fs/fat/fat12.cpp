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
# fat12.cpp
# Fat12 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "fat12.h"

/*##########################################################################
#
#   Name       : TFat12::InitFs
#
#   Purpose....: Validate before format
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFat12::InitFs(TPartServer *server, struct TBootSector12_16 *boot)
{
    return false;
}

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
TFat12::TFat12(TPartServer *server, struct TBootSector12_16 *boot, bool format)
  : TFat(server, (struct TBaseBootSector *)boot),
    Tab1(server),
    Tab2(server)
{
    unsigned int Free1;
    unsigned int Free2;

    FatSize = 12;
    PartSectors = boot->base.SectorCount16;
    if (!PartSectors)
        PartSectors = boot->base.Sectors;

    FatSectors = boot->base.FatSectors16;

    RootDirEntries = boot->base.RootDirEntries;

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

        if (format)
        {
            Free1 = Tab1.FormatClusters();
            Free2 = Tab2.FormatClusters();

            if (Free1 > Free2)
                FreeClusters = Free2;
            else
                FreeClusters = Free1;
        }
        else
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
