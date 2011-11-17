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
# ffspart.cpp
# FLASHFS partition class
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdio.h>

#include "rdos.h"
#include "ffspart.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TFlashFsPartition::TFlashFsPartition  #############
*   Purpose....: Partition FLASHFS constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFlashFsPartition::TFlashFsPartition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFsPartition(Disc, 0xAF, Parent, Entry, Start, Size)
{
}

/*##################  TFlashFsPartition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TFlashFsPartition::GetPartName()
{
	return "FLASHFS";
}

/*##################  TFlashFsPartition::Format  #############
*   Purpose....: Format FLASHFS partition					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TFlashFsPartition::Format()
{
	return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "FLASHFS");
}

/*##################  TFlashFsPartitionFactory::TFlashFsPartitionFactory  #############
*   Purpose....: FLASHFS partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFlashFsPartitionFactory::TFlashFsPartitionFactory()
  : TFsPartitionFactory(0xAF, "FLASHFS")
{
}

/*##################  TFlashFsPartitionFactory::~TFlashFsPartitionFactory  #############
*   Purpose....: FLASHFS partition factory destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFlashFsPartitionFactory::~TFlashFsPartitionFactory()
{
}

/*##################  TFlashFsPartitionFactory::Open  #############
*   Purpose....: Open FLASHFS partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFlashFsPartitionFactory::Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
    return new TFlashFsPartition(Disc, Parent, Entry, Start, Size);
}

/*##################  TFlashFsPartitionFactory::Create  #############
*   Purpose....: Create FLASHFS partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TFlashFsPartitionFactory::Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	TFlashFsPartition *FatPart;

    FatPart = new TFlashFsPartition(Disc, Parent, Entry, Start, Size);
    FatPart->Format();
	return FatPart;
}
