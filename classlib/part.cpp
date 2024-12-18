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
# part.cpp
# Harddrive partition handling classes
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "part.h"

#define FALSE   0
#define TRUE    !FALSE

/*##################  TPartition::TPartition  #############
*   Purpose....: Partition constructor                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartition::TPartition(TDisc *Disc, long PStart, long PSize)
{
    FDisc = Disc;
    Start = PStart;
    Size = PSize;
}

/*##################  TPartition::~TPartition  #############
*   Purpose....: Partition destructor                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TPartition::~TPartition()
{
}

/*##################  TPartition::GetDisc  #############
*   Purpose....: Get disc nr                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc *TPartition::GetDisc()
{
    return FDisc;
}

/*##################  TPartition::GetDrive  #############
*   Purpose....: Get drive nr                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDrive *TPartition::GetDrive()
{
    return 0;
}

/*##################  TPartition::IsFs  #############
*   Purpose....: Check if entry is fs                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsFs()
{
    return FALSE;
}

/*##################  TPartition::GetBytesPerSector  #############
*   Purpose....: Get bytes per sector                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::GetBytesPerSector()
{
    if (FDisc)
        return FDisc->GetBytesPerSector();
    else
        return 0;
}

/*##################  TPartition::GetTotalSpace  #############
*   Purpose....: Get total space in MB                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TPartition::GetTotalSpace()
{
   return (double)Size * (double)GetBytesPerSector() / (double)0x100000;
}

/*##################  TPartition::GetFreeSpace  #############
*   Purpose....: Get free space in MB                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
double TPartition::GetFreeSpace()
{
    return 0;
}

/*##################  TPartition::Read  #############
*   Purpose....: Read data from partition                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::Read(long Sector, char *Buf, int Count)
{
    if (Sector < 0 || Sector >= Size)
        return 0;

    return FDisc->Read(Start + Sector, Buf, Count);
}

/*##################  TPartition::Write  #############
*   Purpose....: Write data to partition                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::Write(long Sector, const char *Buf, int Count)
{
   if (Sector < 0 || Sector >= Size)
        return 0;

    return FDisc->Write(Start + Sector, Buf, Count);
}

/*##################  TPartition::IsFree  #############
*   Purpose....: Check if entry is free                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TPartition::IsFree()
{
    return FALSE;
}

/*##################  TFreePartition::TFreePartition  #############
*   Purpose....: Partition free constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFreePartition::TFreePartition(TDisc *Disc)
 : TPartition(Disc, 0, 0)
{
}

/*##################  TFreePartition::~TFreePartition  #############
*   Purpose....: Partition free destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFreePartition::~TFreePartition()
{
}

/*##################  TFreePartition::GetPartName  #############
*   Purpose....: Get partition name                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFreePartition::GetPartName()
{
    return "Free";
}

/*##################  TFreePartition::IsFree  #############
*   Purpose....: Check if entry is free                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFreePartition::IsFree()
{
    return TRUE;
}

/*##################  TDiscPartition::TDiscPartition  #############
*   Purpose....: Disc partition constructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDiscPartition::TDiscPartition(TDisc *Disc)
{
    int i;

    FDisc = Disc;
    PartCount = 0;

    for (i = 0; i < MAX_PART_COUNT; i++)
        PartArr[i] = 0; 
}

/*##################  TDiscPartition::~TDiscPartition  #############
*   Purpose....: Disc partition destructor                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDiscPartition::~TDiscPartition()
{
}

/*##################  TDiscPartition::InsertEntry  #############
*   Purpose....: Insert partition entry
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::InsertEntry(TPartition *Part)
{
    if (Part->IsFs())
    {
        PartArr[PartCount] = Part;
        PartCount++;
    }
}

/*##################  TDiscPartition::Sort  #############
*   Purpose....: Sort partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::Sort()
{
    int i;
    int Changed;
    TPartition *Temp;

    Changed = TRUE;

    while (Changed)
    {
        Changed = FALSE;
        for (i = 1; i < PartCount; i++)
        {
            if (PartArr[i-1]->Start > PartArr[i]->Start)
            {
                Temp = PartArr[i-1];
                PartArr[i-1] = PartArr[i];
                PartArr[i] = Temp;
                Changed = TRUE;
            }
        }
    }
}

/*##################  TDiscPartition::AddFree  #############
*   Purpose....: Add free entries partition array
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TDiscPartition::AddFree()
{
    int i;
    int j;
    long Start;

    Start = 0;

    for (i = 0; i < PartCount; i++)
    {
        if (Start + 1024 < PartArr[i]->Start)
        {
            for (j = PartCount; j > i; j--)
                PartArr[j] = PartArr[j-1];

            PartArr[i] = new TFreePartition(FDisc);
            PartArr[i]->Start = Start;
            PartArr[i]->Size = PartArr[i+1]->Start - Start - 1;
            PartCount++;
        }
        Start = PartArr[i]->Start + PartArr[i]->Size;
    }

    if (Start + 1024 < FDisc->GetTotalSectors())
    {
        PartArr[i] = new TFreePartition(FDisc);
        PartArr[i]->Start = Start;
        PartArr[i]->Size = (int)FDisc->GetTotalSectors() - Start;
        PartCount++;
    }
}

/*##################  TDiscPartition::GetDisc  #############
*   Purpose....: Get disc
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TDisc *TDiscPartition::GetDisc()
{
    return FDisc;
}
