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
# disc.cpp
# Direct disc access class
#
########################################################################*/

#include "rdos.h"
#include "disc.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TDisc::TDisc  #############
*   Purpose....: Disc constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc::TDisc(int Disc)
{
	FDisc = Disc;
	FValid = RdosGetDiscInfo(Disc, &FBytesPerSector, &FSectors, &FSectorsPerCyl, &FHeads);

	if (!FValid)
	{
	    FBytesPerSector = 0;
	    FSectors = 0;
	    FSectorsPerCyl = 0;
	    FHeads = 0;
	}
}

/*##################  TDisc::~TDisc  #############
*   Purpose....: Disc destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc::~TDisc()
{
}

/*##################  TDisc::IsValid  #############
*   Purpose....: Is disc valid?						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::IsValid()
{
    return FValid;
}

/*##################  TDisc::GetDiscNr  #############
*   Purpose....: Get disc #						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetDiscNr()
{
    if (FValid)
    	return FDisc;
    else
        return 0;
}

/*##################  TDisc::GetBytesPerSector  #############
*   Purpose....: Get bytes per sector						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetBytesPerSector()
{
	return FBytesPerSector;
}

/*##################  TDisc::GetTotalSectors  #############
*   Purpose....: Get total sectors on disc		  		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TDisc::GetTotalSectors()
{
	return FSectors;
}

/*##################  TDisc::GetSectorsPerCyl  #############
*   Purpose....: Get sectors per cylinder		  		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetSectorsPerCyl()
{
	return FSectorsPerCyl;
}

/*##################  TDisc::GetHeads  #############
*   Purpose....: Get heads		  		                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetHeads()
{
	return FHeads;
}

/*##################  TDisc::Read  #############
*   Purpose....: Read a sector
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::Read(long Sector, char *buf, int size)
{
	return RdosReadDisc(FDisc, Sector, buf, size);
}

/*##################  TDisc::Write  #############
*   Purpose....: Write a sector
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::Write(long Sector, const char *buf, int size)
{
	return RdosWriteDisc(FDisc, Sector, buf, size);
}

/*##################  TDisc::GetDrive  #############
*   Purpose....: Get drive from physical sectors							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDisc::GetDrive(long Start, long Size)
{
    int DriveNr;
    int DiscNr;
    long StartSector;
    long DriveSize;

    for (DriveNr = 0; DriveNr < 25; DriveNr++)
	    if (RdosGetDriveDiscParam(DriveNr, &DiscNr, &StartSector, &DriveSize))
	        if (DiscNr == FDisc)
			    if (Start <= StartSector && Start + Size >= StartSector + DriveSize)
					return DriveNr;

    return 0;
}

/*##################  TDisc::ChsToLba  #############
*   Purpose....: Convert CHS to LBA						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TDisc::ChsToLba(const char *Data)
{
	int chs[3];
	int BiosHead;
	int BiosSector;
	int BiosCyl;

	chs[0] = *(unsigned char *)Data;
	chs[1] = *(unsigned char *)(Data + 1);
	chs[2] = *(unsigned char *)(Data + 2);

	BiosCyl = chs[2];
	BiosCyl += (chs[1] & 0xC0) << 2;
	BiosSector = chs[1] & 0x3F;
	BiosHead = chs[0];

	if (BiosCyl == 1023)
		return 0;

	if (BiosSector == 0)
		return 0;

	return BiosSector + FSectorsPerCyl * (BiosHead + FHeads * BiosCyl) - 1;
}

/*##################  TDisc::LbaToChs  #############
*   Purpose....: Convert LBA to CHS						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDisc::LbaToChs(long Sector, char *Data)
{
	int BiosHead;
	int BiosSector;
	int BiosCyl;

	BiosCyl = Sector / FSectorsPerCyl / FHeads;
	if (BiosCyl >= 1024)
	{
		BiosCyl = 1023;
		BiosHead = FHeads - 1;
		BiosSector = FSectorsPerCyl;
	}
	else
	{
		Sector = Sector - BiosCyl * FSectorsPerCyl * FHeads;
		BiosHead = Sector / FSectorsPerCyl;
		BiosSector = Sector - BiosHead * FSectorsPerCyl + 1;
	}

	*Data = (char)BiosHead;
	*(Data + 1) = (char)BiosSector;
	*(Data + 2) = (char)BiosCyl;
	*(Data + 1) |= (char)((BiosCyl >> 2) & 0xC0);
}
