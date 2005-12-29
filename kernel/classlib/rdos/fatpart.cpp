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
# fatpart.cpp
# FAT partition class
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdio.h>

#include "rdos.h"
#include "fatpart.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TFatPartition::TFatPartition  #############
*   Purpose....: Partition FAT constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFatPartition::TFatPartition(TDisc *Disc, unsigned char Type, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFsPartition(Disc, Type, Parent, Entry, Start, Size)
{
}

/*##################  TFat12Partition::TFat12Partition  #############
*   Purpose....: Partition FAT12 constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat12Partition::TFat12Partition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFatPartition(Disc, 1, Parent, Entry, Start, Size)
{
}

/*##################  TFat12Partition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFat12Partition::GetPartName()
{
	return "FAT12";
}

/*##################  TFat12Partition::Format  #############
*   Purpose....: Format FAT12 partition					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFat12Partition::Format()
{
	return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT12");
}

/*##################  TFat16Partition::TFat16Partition  #############
*   Purpose....: Partition FAT16 constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat16Partition::TFat16Partition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFatPartition(Disc, 6, Parent, Entry, Start, Size)
{
}

/*##################  TFat16Partition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFat16Partition::GetPartName()
{
	return "FAT16";
}

/*##################  TFat16Partition::Format  #############
*   Purpose....: Format FAT16 partition					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFat16Partition::Format()
{
	return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT16");
}

/*##################  TFat32Partition::TFat32Partition  #############
*   Purpose....: Partition FAT32 constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat32Partition::TFat32Partition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFatPartition(Disc, 11, Parent, Entry, Start, Size)
{
}

/*##################  TFat32Partition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFat32Partition::GetPartName()
{
	return "FAT32";
}

/*##################  TFat32Partition::Format  #############
*   Purpose....: Format FAT32 partition					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFat32Partition::Format()
{
	return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FAT32");
}

/*##################  TFat12PartitionFactory::TFat12PartitionFactory  #############
*   Purpose....: FAT12 partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat12PartitionFactory::TFat12PartitionFactory()
  : TFsPartitionFactory(1, "FAT12")
{
}

/*##################  TFat12PartitionFactory::~TFat12PartitionFactory  #############
*   Purpose....: FAT12 partition factory destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat12PartitionFactory::~TFat12PartitionFactory()
{
}

/*##################  TFat12PartitionFactory::Open  #############
*   Purpose....: Open FAT12 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat12PartitionFactory::Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	return new TFat12Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TFat12PartitionFactory::Create  #############
*   Purpose....: Create FAT12 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat12PartitionFactory::Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	TFat12Partition *FatPart;

	FatPart = new TFat12Partition(Disc, Parent, Entry, Start, Size);
	FatPart->Format();
	return FatPart;
}

/*##################  TFat16PartitionFactory::TFat16PartitionFactory  #############
*   Purpose....: FAT16 partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat16PartitionFactory::TFat16PartitionFactory()
  : TFsPartitionFactory(6, "FAT16")
{
}

/*##################  TFat16PartitionFactory::~TFat16PartitionFactory  #############
*   Purpose....: FAT16 partition factory destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat16PartitionFactory::~TFat16PartitionFactory()
{
}

/*##################  TFat16PartitionFactory::Open  #############
*   Purpose....: Open FAT16 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat16PartitionFactory::Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	return new TFat16Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TFat16PartitionFactory::Create  #############
*   Purpose....: Create FAT16 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat16PartitionFactory::Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	TFat16Partition *FatPart;

	FatPart = new TFat16Partition(Disc, Parent, Entry, Start, Size);
	FatPart->Format();
	return FatPart;
}

/*##################  TFat32PartitionFactory::TFat32PartitionFactory  #############
*   Purpose....: FAT32 partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat32PartitionFactory::TFat32PartitionFactory()
  : TFsPartitionFactory(11, "FAT32")
{
}

/*##################  TFat32PartitionFactory::~TFat32PartitionFactory  #############
*   Purpose....: FAT32 partition factory destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFat32PartitionFactory::~TFat32PartitionFactory()
{
}

/*##################  TFat32PartitionFactory::Open  #############
*   Purpose....: Open FAT32 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat32PartitionFactory::Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	return new TFat32Partition(Disc, Parent, Entry, Start, Size);
}

/*##################  TFat32PartitionFactory::Create  #############
*   Purpose....: Create FAT32 partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFat32PartitionFactory::Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	TFat32Partition *FatPart;

	FatPart = new TFat32Partition(Disc, Parent, Entry, Start, Size);
	FatPart->Format();
	return FatPart;
}
