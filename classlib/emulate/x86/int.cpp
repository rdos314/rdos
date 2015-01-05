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
* INT.CPP
* Interrupt emulation
*
*##########################################################################*/

#include "int.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TInterrupt::TInterrupt  ###############
*   Purpose....: Constructor for TInterrupt                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TInterrupt::TInterrupt(TBus *Bus)
  : TBusFunction(Bus)
{
    OnSet = 0;
    OnReset = 0;
}

/*##################  TInterrupt::~TInterrupt  ###############
*   Purpose....: Destructor for TInterrupt                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TInterrupt::~TInterrupt()
{
}

/*##################  TInterrupt::NotifySet  ###############
*   Purpose....: Notify interrupt line active                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TInterrupt::NotifySet(TCpu *Cpu)
{
    if (OnSet)
        (*OnSet)(this, Cpu);
}

/*##################  TInterrupt::NotifyReset  ###############
*   Purpose....: Notify interrupt line inactive                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void TInterrupt::NotifyReset(TCpu *Cpu)
{
    if (OnReset)
        (*OnReset)(this, Cpu);
}
