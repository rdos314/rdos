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
# tab32.h
# 32-bit Fat table class
#
########################################################################*/

#ifndef _FAT_TAB32_H
#define _FAT_TAB32_H

#include "tab.h"

class TFatTable32 : public TFatTable
{
public:
    TFatTable32(TPartServer *Server);
    virtual ~TFatTable32();

    virtual unsigned int GetClusterLink(unsigned int Cluster);
    virtual unsigned int GetFreeClusters();
    virtual unsigned int FormatClusters();

    virtual unsigned int AllocateCluster();
    virtual bool ReserveCluster(unsigned int Cluster);
    virtual void LinkCluster(unsigned int Cluster, unsigned int Link);
    virtual void LinkCluster(unsigned int Cluster);
    virtual void FreeCluster(unsigned int Cluster);
    virtual void Complete();

    void Setup(int SectorsPerCluster, long long StartSector, int FatSectors, unsigned int Clusters);
    void SetCacheSize(int size);

protected:
    unsigned int FormatBlock(long long Sector, unsigned int Clusters);
    unsigned int GetFreeInBlock(long long Sector, unsigned int Clusters);

    void ClearMod();
    void ClearCache();

    void SetupCache(unsigned int Cluster);
    void SetupMod(unsigned int Cluster);

    unsigned int FClusters;
    unsigned int FFreeClusters;

    int FCachedSectors;
    int FCachedClusters;

    unsigned int FStartCluster;
    TPartReqEntry *FReqEntry;
    unsigned int *FTab;

    unsigned int FAllocateCluster;
    TPartReqEntry *FModReq;
    unsigned int FModCluster;
    unsigned int *FModTab;
    bool FWrite;
};

#endif
