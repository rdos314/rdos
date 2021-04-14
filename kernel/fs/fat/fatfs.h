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
# fs.h
# Fat class
#
########################################################################*/

#ifndef _FAT_FS_H
#define _FAT_FS_H

#include "fs.h"
#include "tab.h"

class TFat : public TFs
{
public:
    TFat();
    ~TFat();

    void Run(const char *FsName);

protected:
    void Test();
    void GetSectors(TDiscReq *Req, long long sector, int count);


    bool ProcessBootSector(const char *FsName);
    bool ProcessInfoSector();
    void CreateTables();

    int PartSectors;
    int SectorsPerCluster;
    int ReservedSectors;

    int Clusters;
    int RootDirEntries;
    int RootCluster;

    long long RootSector;
    long long StartSector;
    long long InfoSector;

    long long Fat1Sector;
    long long Fat2Sector;
    int FatSize;
    int FatCount;
    int FatSectors;

    TFatTable *Tab1;
    TFatTable *Tab2;

    int FreeClusters;
};

#endif

