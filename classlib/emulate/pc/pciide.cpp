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

#include "rdos.h"
#include "pciide.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPciIdeUnit::TPciIdeUnit  ###############
*   Purpose....: Constructor for PCI IDE unit                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciIdeUnit::TPciIdeUnit(TBus *Bus, int IoBase, int DiscId)
  : TBusFunction(Bus)
{
    FDiscId = DiscId;
    DefineIo(0, IoBase, 0x10, 0);
}

/*##################  TPciIdeUnit::~TPciIdeUnit  ###############
*   Purpose....: Destructor for PCI IDE unit                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciIdeUnit::~TPciIdeUnit()
{
}

/*##################  TPciIdeUnit::GetSize  ###############
*   Purpose....: Get mapping size of device                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPciIdeUnit::GetSize()
{
    return 0x10;
}

/*##################  TPciIdeUnit::Out  ###############
*   Purpose....: Perform out instruction                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciIdeUnit::Out(int Num, int Offset, char Value)
{
    int LVal;

    LVal = (int)Value & 0xFF;

    switch (Offset)
    {
        case 0:
            break;

        case 1:
            break;

        case 2:
            FCount = LVal;
            break;

        case 3:
            FLba = LVal;
            break;

        case 4:            
            FLba |= LVal << 8;
            break;

        case 5:            
            FLba |= LVal << 16;
            break;

        case 6:
            FSel = Value;
            break;

        case 7:
            FCmd = Value;
            FPos = 0;
            RdosReadDisc(FDiscId, FLba, FBuf, 512);
            break;
    }
}

/*##################  TPciIdeUnit::In  ###############
*   Purpose....: Perform in instruction                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciIdeUnit::In(int Num, int Offset)
{
    char ch;
    
    switch (Offset)
    {
        case 0:
            ch = FBuf[FPos];
            FPos++;
            return ch;

        case 1:
            ch = FBuf[FPos];
            FPos++;

            if (FPos == 512)
            {
                FPos = 0;
                FCount--;

                if (FCount)
                {
                    FLba++;
                    RdosReadDisc(FDiscId, FLba, FBuf, 512);
                }
            }
            return ch;

        case 2:
            return (char)(FCount & 0xFF);

        case 3:
            return (char)(FLba & 0xFF);

        case 4:            
            return (char)((FLba >> 8) & 0xFF);

        case 5:            
            return (char)((FLba >> 16) & 0xFF);

        case 6:
            return FSel;

        case 7:
            return 0x50;
    }
    return 0xFF;
}

/*##################  TPciIde::TPciIde  ###############
*   Purpose....: Constructor for PCI IDE                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciIde::TPciIde(TPci *Pci)
  : TPciFunction(Pci)
{
    int i;

    for (i = 0; i < 4; i++)
        DiscArr[i] = 0;
        
    FConfig[0xA] = 1;
    FConfig[0xB] = 1;
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
    int i;

    for (i = 0; i < 4; i++)
        if (DiscArr[i])
            delete DiscArr[i];
}

/*##################  TPciIde::AddDisc  ###############
*   Purpose....: Add new disc                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciIde::AddDisc(int DiscId)
{
    int disc;
    int IoBase;
    TBus *Bus;
    TPciIdeUnit *IdeUnit;

    for (disc = 0; disc < 4; disc++)
        if (DiscArr[disc] == 0)
            break;

    if (DiscArr[disc] == 0)
    {
        IoBase = DefineIoBar(disc, 0x10);
        Bus = FPci->GetBus();
        IdeUnit = new TPciIdeUnit(Bus, IoBase, DiscId);
        DiscArr[disc] = IdeUnit;
    }
}
