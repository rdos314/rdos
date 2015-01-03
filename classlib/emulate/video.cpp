/*###########################################################################
* RDOS operating system 
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
* VIDEO.CPP
* Video emulation
*
*##########################################################################*/

#include "video.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TVideo::TVideo  ###############
*   Purpose....: Constructor for RAM							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TVideo::TVideo(TBus *Bus)
  : TBusFunction(Bus)
{
	int i;
	int Size = 0x8000;

	FData = new char[Size];

	for (i = 0; i < Size; i++)
	{
	    if ((i % 1) == 0)
	        FData[i] = 0x20;
	    else
	        FData[i] = 0x7;
	}

	DefineMem(0, 0xB8000, Size, FData);
}

/*##################  TVideo::~TVideo  ###############
*   Purpose....: Destructor for RAM							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TVideo::~TVideo()
{
	if (FData)
		delete FData;
}

/*##################  TVideo::GetSize  ###############
*   Purpose....: Get mapping size of device						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TVideo::GetSize()
{
    return 0x8000;
}

/*##################  TVideo::WriteMem  ###############
*   Purpose....: Write video mem                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TVideo::WriteMem(int Num, unsigned long Offset, char Value)
{
    FData[Offset] = Value;
}

/*##################  TVideo::ReadMem  ###############
*   Purpose....: Read video mem                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TVideo::ReadMem(int Num, unsigned long Offset)
{
    return FData[Offset];
}
