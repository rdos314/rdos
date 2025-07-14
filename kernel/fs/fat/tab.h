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
# tab.h
# Fat table base class
#
########################################################################*/

#ifndef _FAT_TAB_H
#define _FAT_TAB_H

#include "partint.h"

class TFatTable
{
public:
    TFatTable(TPartServer *Server);
    virtual ~TFatTable();

    void SetAllocateCluster(unsigned int Cluster);
    bool IsFree(unsigned int Cluster);

    virtual unsigned int GetClusterLink(unsigned int Cluster) = 0;
    virtual unsigned int GetFreeClusters() = 0;
    virtual unsigned int FormatClusters() = 0;

    virtual unsigned int AllocateCluster() = 0;
    virtual bool ReserveCluster(unsigned int Cluster) = 0;
    virtual void LinkCluster(unsigned int Cluster, unsigned int Link) = 0;
    virtual void LinkCluster(unsigned int Cluster) = 0;
    virtual void FreeCluster(unsigned int Cluster) = 0;
    virtual void Complete() = 0;

protected:
    long long FStartSector;
    int FSectorsPerCluster;
    TPartReq FReq;

    unsigned int FStartCluster;
    unsigned int FAllocateCluster;

    unsigned int FClusters;
    unsigned int FFreeClusters;
    int FCachedSectors;
    int FCachedClusters;
    bool FWrite;
};

#endif

