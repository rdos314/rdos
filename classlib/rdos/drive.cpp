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
