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
# rdfspart.cpp
# RDFS partition class
#
########################################################################*/

#ifdef __GNUC__
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdio.h>

#include "rdos.h"
#include "rdfspart.h"

#define FALSE	0
#define TRUE	!FALSE

/*##################  TRdfsPartition::TRdfsPartition  #############
*   Purpose....: Partition RDFS constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TRdfsPartition::TRdfsPartition(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
 : TFsPartition(Disc, 7, Parent, Entry, Start, Size)
{
}

/*##################  TRdfsPartition::GetPartName  #############
*   Purpose....: Get partition name						                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
const char *TRdfsPartition::GetPartName()
{
	return "RDFS";
}

/*##################  TRdfsPartition::Format  #############
*   Purpose....: Format RDFS partition					                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
int TRdfsPartition::Format()
{
	return RdosFormatDrive(FDisc->GetDiscNr(), Start, Size, "RDFS");
}

/*##################  TRdfsPartitionFactory::TRdfsPartitionFactory  #############
*   Purpose....: RDFS partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TRdfsPartitionFactory::TRdfsPartitionFactory()
  : TFsPartitionFactory(7, "RDFS")
{
	FBootSectorID = 0;
	memset(BootSector, 0, 512);
	Init();
}

/*##################  TRdfsPartitionFactory::~TRdfsPartitionFactory  #############
*   Purpose....: RDFS partition factory destructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TRdfsPartitionFactory::~TRdfsPartitionFactory()
{
}

/*##################  TRdfsPartitionFactory::TRdfsPartitionFactory  #############
*   Purpose....: RDFS partition factory constructor							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TRdfsPartitionFactory::TRdfsPartitionFactory(int BootSectorID)
  : TFsPartitionFactory(7, "RDFS")
{
	FBootSectorID = BootSectorID;
	memset(BootSector, 0, 512);
	RdosReadResource(0, BootSectorID, BootSector, 512);
	Init();
}

/*##################  TRdfsPartitionFactory::Init  #############
*   Purpose....: Init object							                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
void TRdfsPartitionFactory::Init()
{
	RdosGetRdfsInfo(CryptTab, KeyTab, ExtentSizeTab);
}

/*##################  TRdfsPartitionFactory::Open  #############
*   Purpose....: Open RDFS partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TRdfsPartitionFactory::Open(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	return new TRdfsPartition(Disc, Parent, Entry, Start, Size);
}

/*##################  TRdfsPartitionFactory::Create  #############
*   Purpose....: Create RDFS partition
*   In params..: *                                                        #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
TFsPartition *TRdfsPartitionFactory::Create(TDisc *Disc, TPartitionTable *Parent, int Entry, long Start, long Size)
{
	TRdfsPartition *RdfsPart;

	RdfsPart = new TRdfsPartition(Disc, Parent, Entry, Start, Size);
	RdfsPart->Format();
	return RdfsPart;
}
