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
