/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# discstor.cpp
# Disc storage class
#
########################################################################*/

#include <string.h>
#include "discstor.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TDiscStorage::TDiscStorage
#
#   Purpose....: Constructor for disc storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscStorage::TDiscStorage(TDisc *Disc)
{
    FDisc = 0;

    if (Disc->IsValid() && Disc->GetBytesPerSector() == 512)
    {
        FDisc = Disc;
        FStartSector = 0;
        FSectorCount = (int)Disc->GetTotalSectors();
    }
    else
        FSectorCount = 0;
}

/*##########################################################################
#
#   Name       : TDiscStorage::TDiscStorage
#
#   Purpose....: Constructor for disc storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscStorage::TDiscStorage(TDisc *Disc, long long StartSector, int SectorCount)
{
    long long Sectors;

    FDisc = 0;

    if (Disc->IsValid() && Disc->GetBytesPerSector() == 512)
    {
        Sectors = Disc->GetTotalSectors();
        FDisc = Disc;
        if (StartSector < Sectors)
        {
            FStartSector = StartSector;
            Sectors -= StartSector;
            if (Sectors > SectorCount)
                FSectorCount = SectorCount;
            else
                FSectorCount = (int)Sectors;
        }
        else
            FSectorCount = 0;
    }
    else
        FSectorCount = 0;
}

/*##########################################################################
#
#   Name       : TDiscStorage::~TDiscStorage
#
#   Purpose....: Destructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDiscStorage::~TDiscStorage()
{
}

/*##########################################################################
#
#   Name       : TDiscStorage::Size
#
#   Purpose....: Get size
#
#
##########################################################################*/
long TDiscStorage::Size()
{
    return 512L * (long)FSectorCount;
}

/*##########################################################################
#
#   Name       : TDiscStorage::Read
#
#   Purpose....: Read data
#
#
##########################################################################*/
int TDiscStorage::Read(long offset, char *buf, int size)
{
    int RelSector;
    int OffSector;
    int CurrSize;
    char SectorBuf[512];
    int ok;

    RelSector = (int)(offset / 512L);
    OffSector = (int)(offset % 512L);
    CurrSize = 512 - OffSector;

    if (CurrSize > size)
        CurrSize = size;

    ok = TRUE;

    while (size && ok)
    {
        memset(SectorBuf, 0xFF, 512);

        if (RelSector < FSectorCount)
        {
            if (CurrSize == 512)
                ok = FDisc->Read(FStartSector + RelSector, buf, 512);
            else
            {
                ok = FDisc->Read(FStartSector + RelSector, SectorBuf, 512);
                memcpy(buf, SectorBuf + OffSector, CurrSize);
            }
        }
        else
            ok = FALSE;

        size -= CurrSize;
        buf += CurrSize;

        RelSector++;
        OffSector = 0;
        CurrSize = 512;

        if (CurrSize > size)
            CurrSize = size;

    }

    return ok;

}

/*##########################################################################
#
#   Name       : TDiscStorage::Write
#
#   Purpose....: Write data
#
#
##########################################################################*/
int TDiscStorage::Write(long offset, const char *buf, int size)
{
    int RelSector;
    int OffSector;
    int CurrSize;
    char SectorBuf[512];
    int ok;

    RelSector = (int)(offset / 512L);
    OffSector = (int)(offset % 512L);
    CurrSize = 512 - OffSector;

    if (CurrSize > size)
        CurrSize = size;

    ok = TRUE;

    while (size && ok)
    {
        memset(SectorBuf, 0xFF, 512);

        if (RelSector < FSectorCount)
        {
            if (CurrSize == 512)
                ok = FDisc->Write(FStartSector + RelSector, buf, 512);
            else
            {
                ok = FDisc->Read(FStartSector + RelSector, SectorBuf, 512);
                if (ok)
                {
                    memcpy(SectorBuf + OffSector, buf, CurrSize);
                    ok = FDisc->Write(FStartSector + RelSector, SectorBuf, 512);
                }
            }
        }
        else
            ok = FALSE;

        size -= CurrSize;
        buf += CurrSize;

        RelSector++;
        OffSector = 0;
        CurrSize = 512;

        if (CurrSize > size)
            CurrSize = size;

    }

    return ok;

}
