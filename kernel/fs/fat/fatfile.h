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
# fatfile.h
# FAT file class
#
########################################################################*/

#ifndef _FATFILE_H
#define _FATFILE_H

#include "file.h"
#include "block.h"
#include "cluster.h"

class TFat;

class TFatFile : public TFile
{
public:
    TFatFile(TFat *Fat, TDir *ParentDir, int ParentIndex, unsigned int Cluster, int BytesPerSector, int OffsetSector);
    virtual ~TFatFile();

    virtual void SetRead(long long StartSector, int Sectors);
    virtual void SetWrite(long long StartSector, int Sectors);
    virtual long long GetSector(long long RelSector);

    virtual bool GrowDisc(long long Size);
    virtual bool SetDiscSize(long long Size);

protected:
    unsigned int SizeToClusters(long long size);
    long long ClustersToSize(unsigned int clusters);

    bool Grow(unsigned int count);
    bool Shrink(unsigned int count);

    int FSectorsPerCluster;
    int FClusterCount;
    unsigned int *FClusterArr;

    TFat *FFat;
    TCluster *FClusterChain;
};

#endif

