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
* FLASH.CPP
* Flash ROM emulation
*
*##########################################################################*/

#include "flash.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TFlash::TFlash  ###############
*   Purpose....: Constructor for flash							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TFlash::TFlash(unsigned long Size)
  : TIsaFunction(0)
{
	int i;

	FSize = Size;
	FData = new char[Size];

	for (i = 0; i < Size; i++)
		*(FData + i) = 0xFF;

	DefineMem(0, 0, Size, FData);
}

/*##################  TFlash::TFlash  ###############
*   Purpose....: Constructor for flash							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TFlash::TFlash(TIsa *Isa, unsigned long Base, unsigned long Size)
  : TIsaFunction(Isa)
{
	int i;

	FSize = Size;
	FData = new char[Size];

	for (i = 0; i < Size; i++)
		*(FData + i) = 0xFF;

	DefineMem(0, Base, Size, FData);
}

/*##################  TFlash::~TFlash  ###############
*   Purpose....: Destructor for flash							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TFlash::~TFlash()
{
	if (FData)
		delete FData;
}

/*##################  TFlash::GetSize  ###############
*   Purpose....: Get mapping size of device						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TFlash::GetSize()
{
    return FSize;
}

/*##################  TFlash::WriteMem  ###############
*   Purpose....: Write to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TFlash::WriteMem(int Num, unsigned long Offset, char Value)
{
}

/*##################  TFlash::LoadTop ###############
*   Purpose....: Load image at top						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TFlash::LoadTop(TFile *File)
{
	int pos;
	int size;

	size = File->GetSize();
	if (size > FSize)
	{
		File->SetPos(size - FSize);
		pos = 0;
	}
	else
		pos = FSize - size;

	File->Read(FData + pos, size);
}

/*##################  TFlash::LoadBottom ###############
*   Purpose....: Load image at bottom						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TFlash::LoadBottom(TFile *File)
{
	File->Read(FData, FSize);
}
