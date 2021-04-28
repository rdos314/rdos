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
# tab12.cpp
# 12-bit Fat table class
#
########################################################################*/

#include <memory.h>
#include "tab12.h"

/*##########################################################################
#
#   Name       : TFatTable12::TFatTable12
#
#   Purpose....: Fat table12 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable12::TFatTable12(TDiscServer *Server)
 :  TFatTable(Server)
{
    FClusters = 0;
}

/*##########################################################################
#
#   Name       : TFatTable12::~TFatTable12
#
#   Purpose....: Fat table12 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable12::~TFatTable12()
{
}

/*##########################################################################
#
#   Name       : TFatTable12::Setup
#
#   Purpose....: Setup parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable12::Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters)
{
    FSectorsPerCluster = SectorsPerCluster;
    FStartSector = StartSector;

    if (FatSectors * 512 * 2 / 3 < Clusters)
        FClusters = FatSectors * 512 * 2 / 3;
    else
        FClusters = Clusters;
}

/*##########################################################################
#
#   Name       : TFatTable12::GetFreeInBlock
#
#   Purpose....: Get free clusters in block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::GetFreeInBlock(long long Sector, unsigned int Clusters)
{
    unsigned int i;
    unsigned int FreeClusters = 0;
    TDiscReqEntry e1(&FReq, Sector, 3);
    char *tab;
    unsigned int val;

    FReq.WaitForever();

    tab = (char *)e1.Map();

    i = 0;

    while (i < Clusters)
    {
        val = 0;
        memcpy(&val, tab, 3);
        tab += 3;
        i += 2;

        if (val == 0)
            FreeClusters += 2;
        else
        {
            if ((val & 0xFFF) == 0)
                FreeClusters ++;

            val = val >> 12;

            if ((val & 0xFFF) == 0)
                FreeClusters ++;
        }
    }

    return FreeClusters;
}

/*##########################################################################
#
#   Name       : TFatTable12::GetFreeClusters
#
#   Purpose....: Get free clusters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int TFatTable12::GetFreeClusters()
{
    unsigned int FreeClusters = 0;
    int i;
    long long Sector = FStartSector;
    unsigned int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 / 2;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512 * 2)
            Count = 512 * 2;

        FreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 3;
        Cluster += Count;
    }

    return FreeClusters;
}
