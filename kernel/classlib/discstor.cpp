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

#include <mem.h>

#include "discstor.h"
#include "rdos.h"

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
TDiscStorage::TDiscStorage(int DiscNr)
{
    int SectorSize;
    long Sectors;
    int BiosSectorsPerCyl;
    int BiosHeads;
    
    if (RdosGetDiscInfo(DiscNr, &SectorSize, &Sectors, &BiosSectorsPerCyl, &BiosHeads))
    {
        if (SectorSize == 512)
        {
            FDiscNr = DiscNr;
            FStartSector = 0;
            FSectorCount = Sectors;
        }
        else
            FSectorCount = 0;
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
TDiscStorage::TDiscStorage(int DiscNr, long StartSector, int SectorCount)
{
    int SectorSize;
    long Sectors;
    int BiosSectorsPerCyl;
    int BiosHeads;
    
    if (RdosGetDiscInfo(DiscNr, &SectorSize, &Sectors, &BiosSectorsPerCyl, &BiosHeads))
    {
        if (SectorSize == 512)
        {
            FDiscNr = DiscNr;
            if (StartSector < Sectors)
            {
                FStartSector = StartSector;
                Sectors -= StartSector;
                if (Sectors > SectorCount)
                    FSectorCount = SectorCount;
                else
                    FSectorCount = Sectors;
            }
            else
                FSectorCount = 0;
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
int TDiscStorage::Size()
{
    return 512 * FSectorCount; 
}

/*##########################################################################
#
#   Name       : TDiscStorage::Read
#
#   Purpose....: Read data
#
#
##########################################################################*/
int TDiscStorage::Read(int offset, char *buf, int size)
{
    int RelSector;
    int OffSector;
    int CurrSize;
    char SectorBuf[512];
    int ok;

    RelSector = offset / 512;
    OffSector = offset % 512;
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
				ok = RdosReadDisc(FDiscNr, FStartSector + RelSector, buf, 512);
			else
			{
				ok = RdosReadDisc(FDiscNr, FStartSector + RelSector, SectorBuf, 512);
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
int TDiscStorage::Write(int offset, const char *buf, int size)
{
    int RelSector;
    int OffSector;
    int CurrSize;
    char SectorBuf[512];
    int ok;

    RelSector = offset / 512;
    OffSector = offset % 512;
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
				ok = RdosWriteDisc(FDiscNr, FStartSector + RelSector, buf, 512);
			else
			{
				ok = RdosReadDisc(FDiscNr, FStartSector + RelSector, SectorBuf, 512);
				if (ok)
				{
					memcpy(SectorBuf + OffSector, buf, CurrSize);
					ok = RdosWriteDisc(FDiscNr, FStartSector + RelSector, SectorBuf, 512);
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
