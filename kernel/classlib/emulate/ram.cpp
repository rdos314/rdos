/*###########################################################################
* Em486 CPU emulator
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* RAM.CPP
* RAM emulation
*
*##########################################################################*/

#include "ram.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TRam::TRam  ###############
*   Purpose....: Constructor for ram							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TRam::TRam(unsigned long Size)
  : TIsaFunction(0)
{
	int i;

	FSize = Size;
	FData = new char[Size];

	for (i = 0; i < Size; i++)
		*(FData + i) = 0xFF;

	DefineMem(0, 0, Size, FData);
}

/*##################  TRam::TRam  ###############
*   Purpose....: Constructor for RAM							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TRam::TRam(TIsa *Isa, unsigned long Base, unsigned long Size)
  : TIsaFunction(Isa)
{
	int i;

	FSize = Size;
	FData = new char[Size];

	for (i = 0; i < Size; i++)
		*(FData + i) = 0x77;

	DefineMem(0, Base, Size, FData);
}

/*##################  TRam::~TRam  ###############
*   Purpose....: Destructor for RAM							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TRam::~TRam()
{
	if (FData)
		delete FData;
}

/*##################  TRam::GetSize  ###############
*   Purpose....: Get mapping size of device						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TRam::GetSize()
{
    return FSize;
}
