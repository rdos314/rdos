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
# drive.cpp
# Direct drive access class
#
########################################################################*/

#include "rdos.h"
#include "drive.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TDrive::AllocateFixed  #############
*   Purpose....: Allocate fixed drive							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TDrive::AllocateFixed(int DriveNr)
{
    if (RdosAllocateFixedDrive(DriveNr))
        return new TDrive(DriveNr);
    else
        return 0;
}

/*##################  TDrive::AllocateStatic  #############
*   Purpose....: Allocate static drive							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TDrive::AllocateStatic()
{
	int DriveNr;

	DriveNr = RdosAllocateStaticDrive();
	if (DriveNr)
		return new TDrive(DriveNr);
	else
		return 0;
}

/*##################  TDrive::AllocateDynamic  #############
*   Purpose....: Allocate dynamic drive							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TDrive::AllocateDynamic()
{
    int DriveNr;

    DriveNr = RdosAllocateDynamicDrive();
    if (DriveNr)
        return new TDrive(DriveNr);
    else
        return 0;
}

/*##################  TDrive::TDrive  #############
*   Purpose....: Drive constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive::TDrive(int Drive)
{
    long FreeUnits;

	FDrive = Drive;

	FValid = RdosGetDriveInfo(FDrive, &FreeUnits, &FBytesPerUnit, &FUnits);

	if (FValid && FBytesPerUnit == 0)
		FValid = FALSE;

	if (!FValid)
	{
	    FBytesPerUnit = 0;
	    FUnits = 0;
	}
}

/*##################  TDrive::~TDrive  #############
*   Purpose....: Drive destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive::~TDrive()
{
}

/*##################  TDrive::IsValid  #############
*   Purpose....: Is drive valid?						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDrive::IsValid()
{
    return FValid;
}

/*##################  TDrive::GetDriveNr  #############
*   Purpose....: Get drive #						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDrive::GetDriveNr()
{
    if (FValid)
    	return FDrive;
    else
        return 0;
}

/*##################  TDrive::GetFreeSectors  #############
*   Purpose....: Get free sectors on drive						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TDrive::GetFreeSectors()
{
    long FreeUnits;
    int BytesPerUnit;
	long Units;

    if (FValid)
    {
		RdosGetDriveInfo(FDrive, &FreeUnits, &BytesPerUnit, &Units);

		if (BytesPerUnit >= 512)
		    return BytesPerUnit / 512 * FreeUnits;
		else
    	    return BytesPerUnit * FreeUnits / 512;
	}
	else
	    return 0;
}

/*##################  TDrive::GetTotalSectors  #############
*   Purpose....: Get total sectors on drive						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long TDrive::GetTotalSectors()
{
	return FBytesPerUnit * FUnits / 512;
}

/*##################  TDrive::CreateFileDrive  #############
*   Purpose....: Create a file-base drive				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDrive::CreateFileDrive(long Size, const char *FsName, const char *FileName)
{
	return RdosCreateFileDrive(FDrive, Size, FsName, FileName);
}

/*##################  TDrive::OpenFileDrive  #############
*   Purpose....: Open a file-base drive				                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDrive::OpenFileDrive(const char *FileName)
{
	return RdosOpenFileDrive(FDrive, FileName);
}
