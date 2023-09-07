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
# fat16.h
# Fat16 class
#
########################################################################*/

#ifndef _FAT16_H
#define _FAT16_H

#include "fatfs.h"
#include "tab16.h"
#include "dir.h"

class TFat16 : public TFat
{
public:
    TFat16(TPartServer *server, struct TBootSector12_16 *boot, bool format);
    ~TFat16();

    static bool InitFs(TPartServer *Server, struct TBootSector12_16 *boot);

    virtual TDir *CacheRootDir();

protected:
    static unsigned int Adjust(TPartServer *Server);
    static unsigned int CalcClusterSize(unsigned int TotalSectors);
    static unsigned short int CalcClusterCount(unsigned int TotalSectors, unsigned int ClusterSize);
    static unsigned short int CalcFatSectors(unsigned int Clusters);

    void WriteBootSector(struct TBootSector12_16 *BootSector);

    int RootDirEntries;
    long long RootSector;

private:
    TPartServer *FServer;

    TFatTable16 Tab1;
    TFatTable16 Tab2;
};

#endif

