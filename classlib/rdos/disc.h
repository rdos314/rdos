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
# disc.h
# Direct disc access classes
#
########################################################################*/

#ifndef _DISC_H
#define _DISC_H

#include "str.h"

class TDisc
{
public:
	TDisc(int Disc);
	~TDisc();

    int IsValid();
	int GetDiscNr();
	int GetBytesPerSector();
	long GetTotalSectors();
	int GetSectorsPerCyl();
	int GetHeads();

	int Read(long Sector, char *buf, int size);
	int Write(long Sector, const char *buf, int size);
	int GetDrive(long Start, long Size);

	long ChsToLba(const char *Data);
	void LbaToChs(long Sector, char *Data);

protected:
    TDisc();
    void Define(int Disc);

	int FDisc;
	int FBytesPerSector;
	long FSectors;
	int FSectorsPerCyl;
	int FHeads;
	int FValid;
};

#endif

