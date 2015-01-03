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
* PCI.CPP
* PCI emulation
*
*##########################################################################*/

#include "pci.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPciFunction::PciFunction  ###############
*   Purpose....: Constructor                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciFunction::TPciFunction(TPci *Pci)
{
    int i;

    for (i = 0; i < 256; i++)
        FConfig[i] = 0;

    FPci = Pci;
}

/*##################  TPciFunction::~PciFunction  ###############
*   Purpose....: Destructor                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciFunction::~TPciFunction()
{
}

/*##################  TPciFunction::ReadConfig  ###############
*   Purpose....: Read config                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciFunction::ReadConfig(int Index)
{
    return FConfig[Index];
}

/*##################  TPciFunction::WriteConfig  ###############
*   Purpose....: Write config                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteConfig(int Index, char Data)
{
    FConfig[Index] = Data;
}

/*##################  TPciDevice::TPciDevice  ###############
*   Purpose....: Constructor for PCI device                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciDevice::TPciDevice()
{
    int i;

    for (i = 0; i < 8; i++)
        FunctionArr[i] = 0;
}

/*##################  TPciDevice::~TPciDevice  ###############
*   Purpose....: Destructor for PCI device                                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciDevice::~TPciDevice()
{
    int i;

    for (i = 0; i < 8; i++)
        if (FunctionArr[i])
            delete FunctionArr[i];
}

/*##################  TPci::TPci  ###############
*   Purpose....: Constructor for PCI                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPci::TPci(TBus *Bus)
  : TBusFunction(Bus)
{
    int i;

    for (i = 0; i < 256; i++)
        DeviceArr[i] = 0;
        
        DefineIo(0, 0xCF8, 8, 0);
}

/*##################  TPci::~TPci  ###############
*   Purpose....: Destructor for PCI                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPci::~TPci()
{
    int i;

    for (i = 0; i < 256; i++)
        if (DeviceArr[i])
            delete DeviceArr[i];
}

/*##################  TPci::GetSize  ###############
*   Purpose....: Get mapping size of device                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPci::GetSize()
{
    return 8;
}

/*##################  TPci::WriteConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteConfig(int Index, char Value)
{
}

/*##################  TPci::ReadConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::ReadConfig(int Index)
{
    return 0xFF;
}

/*##################  TPci::Out  ###############
*   Purpose....: Perform out instruction                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::Out(int Num, int Offset, char Value)
{
    int LVal;

    LVal = (int)Value & 0xFF;

    switch (Offset)
    {
        case 0:
            FIndex = LVal;
            break;

        case 1:
            FIndex |= LVal << 8;
            break;

        case 2:
            FIndex |= LVal << 16;
            break;

        case 3:
            FIndex |= LVal << 24;
            break;

        case 4:
            WriteConfig(FIndex, Value);
            break;

        case 5:
            WriteConfig(FIndex + 1, Value);
            break;

        case 6:
            WriteConfig(FIndex + 2, Value);
            break;

        case 7:
            WriteConfig(FIndex + 3, Value);
            break;

        default:
            break;

    }
}

/*##################  TPci::In  ###############
*   Purpose....: Perform in instruction                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::In(int Num, int Offset)
{
    switch (Offset)
    {
        case 0:
            return (char)(FIndex & 0xFF);

        case 1:
            return (char)((FIndex >> 8) & 0xFF);

        case 2:
            return (char)((FIndex >> 16) & 0xFF);

        case 3:
            return (char)((FIndex >> 24) & 0xFF);

        case 4:
            return ReadConfig(FIndex);

        case 5:
            return ReadConfig(FIndex + 1);

        case 6:
            return ReadConfig(FIndex + 2);

        case 7:
            return ReadConfig(FIndex + 3);

        default:
            return 0xFF;
    }
}
