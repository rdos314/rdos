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

#define FALSE   0
#define TRUE    !FALSE

/*##################  TDrive::AllocateFixed  #############
*   Purpose....: Allocate fixed drive                                                                       #
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

/*##################  TDrive::TDrive  #############
*   Purpose....: Drive constructor                                                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive::TDrive(int Drive)
{
    long long DiscSectors;
    int SectorsPerCyl;
    int Heads;
    int DiscNr = -1;

    FDrive = Drive;
    FBytesPerSector = 512;

    FSectors = RdosGetVfsDriveSize(FDrive);
    if (FSectors > 0)
    {
        DiscNr = RdosGetVfsDriveDisc(Drive);
        RdosGetDiscInfo(DiscNr, &FBytesPerSector, &DiscSectors, &SectorsPerCyl, &Heads);
        FValid = TRUE;
    }
    else
    {
        FValid = RdosGetDriveInfo(FDrive, &FFreeUnits, &FBytesPerSector, &FUnits);

        if (FValid && FBytesPerSector == 0)
                FValid = FALSE;

        if (!FValid)
        {
            FBytesPerSector = 0;
            FFreeUnits = 0;
            FUnits = 0;
            FSectors = 0;
        }
    }
}

/*##################  TDrive::~TDrive  #############
*   Purpose....: Drive destructor                                                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive::~TDrive()
{
}

/*##################  TDrive::IsValid  #############
*   Purpose....: Is drive valid?                                                                    #
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
*   Purpose....: Get drive #                                                                #
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

/*##################  TDrive::GetBytesPerSector  #############
*   Purpose....: Get bytes per sector                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TDrive::GetBytesPerSector()
{
    return FBytesPerSector;
}

/*##################  TDrive::GetFreeSectors  #############
*   Purpose....: Get free sectors on drive                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDrive::GetFreeSectors()
{
    if (FValid)
    {
        if (FSectors > 0)
            return RdosGetVfsDriveFree(FDrive);
        else
            return FFreeUnits;
    }
    else
        return 0;
}

/*##################  TDrive::GetTotalSectors  #############
*   Purpose....: Get total sectors on drive                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
long long TDrive::GetTotalSectors()
{
    if (FSectors > 0)
        return FSectors;
    else
        return FUnits;
}
