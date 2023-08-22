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
# discpart.h
# Dispart base class
#
########################################################################*/

#ifndef _DISCPART_H
#define _DISCPART_H

#define PART_TYPE_UNKNOWN       0
#define PART_TYPE_FAT12         1
#define PART_TYPE_FAT16         2
#define PART_TYPE_FAT32         3

#include "discint.h"

class TDisc;

class TPartition
{
public:
    TPartition(long long StartSector, long long SectorCount);
    virtual ~TPartition();

    void SetType(int PartType);
    int GetType();

    long long GetStartSector();
    long long GetSectorCount();

    bool CheckInside(long long sector, int count);

    int Handle;

protected:
    int FPartType;

    long long FStartSector;
    long long FSectorCount;
};

class TDisc
{
public:
    TDisc(TDiscServer *server);
    virtual ~TDisc();

    virtual void LoadPart();
    virtual void Stop();
    void Run();

    bool IsStopped();

    TDiscServer *GetServer();
    int GetDiscNr();

    long long GetCached();
    long long GetLocked();

    void Add(TPartition *part);
    void Remove(TPartition *part);

    virtual bool IsGpt() = 0;

    int ReadSector(long long, char *buf, int size);
    int WriteSector(long long, char *buf, int size);

    int FBytesPerSector;
    long long FSectorCount;

    TPartition **FPartArr;
    int FCurrPartCount;
    int FMaxPartCount;

protected:
    void GrowPart();
    void DeletePart(TPartition *part);
  
    int SizeToCount(int size);
    bool IsInsidePartition(long long sector, int count);

    bool FStopped;
    TDiscServer *FServer;
};

#endif

