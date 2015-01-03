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
* PCIIDE.CPP
* PCI IDE emulation
*
*##########################################################################*/

#include "pciide.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPciIde::TPciIde  ###############
*   Purpose....: Constructor for PCI IDE                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciIde::TPciIde(TPci *Pci, int DiscId)
  : TPciFunction(Pci)
{
    FConfig[0xA] = 1;
    FConfig[0xB] = 1;

    FDiscId = DiscId;
}

/*##################  TPciIde::~TPciIde  ###############
*   Purpose....: Destructor for PCI IDE                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciIde::~TPciIde()
{
}
