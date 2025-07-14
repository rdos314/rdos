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
# tab16.h
# 16-bit Fat table class
#
########################################################################*/

#ifndef _FAT_TAB16_H
#define _FAT_TAB16_H

#include "tab.h"

class TFatTable16 : public TFatTable
{
public:
    TFatTable16(TPartServer *Server);
    virtual ~TFatTable16();

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
    unsigned int GetFreeInBlock(long long Sector, unsigned int Clusters);
    unsigned int FormatBlock(long long Sector, unsigned int Clusters);

    void ClearMod();
    void ClearCache();

    void SetupCache(unsigned int Cluster);
    void SetupMod(unsigned int Cluster);

    TPartReqEntry *FReqEntry;
    unsigned short int *FTab;

    TPartReqEntry *FModReq;
    unsigned int FModCluster;
    unsigned short int *FModTab;
};

#endif

