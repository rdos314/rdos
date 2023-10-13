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
# fatdir.h
# FAT directory class
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
    virtual long long GetSector(long long RelSector);

    virtual bool GrowDisc(long long Size);
    virtual bool SetSize(long long Size);

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

