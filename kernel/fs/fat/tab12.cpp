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
TFatTable12::TFatTable12(TDiscServer *Server, int SectorsPerCluster, long long StartSector, int FatSectors, int Clusters)
 :  TFatTable(Server, SectorsPerCluster, StartSector)
{
    if (FatSectors * 512 * 3 / 2 < Clusters)
        FClusters = FatSectors * 512 * 3 / 2;
    else
        FClusters = Clusters;
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
#   Name       : TFatTable12::GetFreeInBlock
#
#   Purpose....: Get free clusters in block
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFatTable12::GetFreeInBlock(long long Sector, int Clusters)
{
    int i;
    int FreeClusters = 0;
    TDiscReqEntry e1(&FReq, Sector, 3);
    short int *tab;

    FReq.WaitForever();

    tab = (short int *)e1.Map();

    for (i = 0; i < Clusters; i++)
        if (tab[i] == 0)
            FreeClusters++;

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
int TFatTable12::GetFreeClusters()
{
    int FreeClusters = 0;
    int i;
    long long Sector = FStartSector;
    int Cluster = 0;
    int Count;
    int Blocks = FClusters / 512 / 3;

    for (i = 0; i <= Blocks; i++)
    {
        Count = FClusters - Cluster;
        if (Count > 512)
            Count = 512;

        FreeClusters += GetFreeInBlock(Sector, Count);
        Sector += 3;
        Cluster += Count;
    }

    return FreeClusters;
}
