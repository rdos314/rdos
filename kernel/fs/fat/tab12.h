/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# tab12.h
# 12-bit Fat table class
#
########################################################################*/

#ifndef _FAT_TAB12_H
#define _FAT_TAB12_H

#include "tab.h"

class TFatTable12 : public TFatTable
{
public:
    TFatTable12(TPartServer *Server);
    virtual ~TFatTable12();

    virtual unsigned int GetClusterLink(unsigned int Cluster);
    virtual unsigned int GetFreeClusters();
    virtual unsigned int FormatClusters();

    virtual unsigned int AllocateCluster();
    virtual bool ReserveCluster(unsigned int Cluster);
    virtual void LinkCluster(unsigned int Cluster, unsigned int Link);
    virtual void UnlinkCluster(unsigned int Cluster);
    virtual void FreeCluster(unsigned int Cluster);
    virtual void Complete();

    void Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters);
    void SetCacheSize(int size);

protected:
    unsigned int GetFreeInBlock(long long Sector, unsigned int Clusters);

    unsigned int FClusters;

    int FCachedSectors;
    int FCachedClusters;
    unsigned int FStartCluster;
    TPartReqEntry *FReqEntry;
    char *FTab;
};

#endif

