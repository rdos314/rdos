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
* LATCH.CPP
* Latch emulation
*
*##########################################################################*/

#include "latch.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TLatch::TLatch  ###############
*   Purpose....: Constructor for RAM                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TLatch::TLatch(TBus *Bus, int Address)
  : TBusFunction(Bus)
{
    FData = 0;
    OnChange = 0;
    DefineIo(0, Address, 1, &FData);
}

/*##################  TLatch::~TLatch  ###############
*   Purpose....: Destructor for RAM                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TLatch::~TLatch()
{
}

/*##################  TLatch::GetSize  ###############
*   Purpose....: Get mapping size of device                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TLatch::GetSize()
{
    return 1;
}

/*##################  TLatch::OutByte  ###############
*   Purpose....: Out byte                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TLatch::OutByte(int Num, int Offset, char val)
{
    FData = val;

    if (OnChange)
        (*OnChange)(this, val);
}
