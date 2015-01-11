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
    Pci->Add(this);
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

/*##################  TPciFunction::ReadByteConfig  ###############
*   Purpose....: Read config                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciFunction::ReadByteConfig(int Register)
{
    return FConfig[Register];
}

/*##################  TPciFunction::ReadWordConfig  ###############
*   Purpose....: Read config                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TPciFunction::ReadWordConfig(int Register)
{
    short int *ptr = (short int *)&FConfig[Register];
    return *ptr;
}

/*##################  TPciFunction::ReadDwordConfig  ###############
*   Purpose....: Read config                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TPciFunction::ReadDwordConfig(int Register)
{
    long *ptr = (long *)&FConfig[Register];
    return *ptr;
}

/*##################  TPciFunction::WriteByteConfig  ###############
*   Purpose....: Write config                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteByteConfig(int Register, char Data)
{
    FConfig[Register] = Data;
}

/*##################  TPciFunction::WriteWordConfig  ###############
*   Purpose....: Write config                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteWordConfig(int Register, short int Data)
{
    short int *ptr = (short int *)&FConfig[Register];
    *ptr = Data;
}

/*##################  TPciFunction::WriteDwordConfig  ###############
*   Purpose....: Write config                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteDwordConfig(int Register, long Data)
{
    long *ptr = (long *)&FConfig[Register];
    *ptr = Data;
}

/*##################  TPciFunction::DefineIoBar  ###############
*   Purpose....: Define IO bar                                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TPciFunction::DefineIoBar(int BarNr, int Size)
{
    int *ptr = (int *)&FConfig[0x10 + 4 * BarNr];
    int IoBase = FPci->AllocateIo(Size);

    *ptr = IoBase | 1;

    return IoBase;
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

/*##################  TPciDevice::Add  ###############
*   Purpose....: Add PCI device                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciDevice::Add(TPciFunction *PciFunction)
{
    int func;

    for (func = 0; func < 8; func++)
        if (FunctionArr[func] == 0)
            break;

    if (FunctionArr[func] == 0)
        FunctionArr[func] = PciFunction;
}

/*##################  TPciDevice::WriteByteConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciDevice::WriteByteConfig(int Function, int Register, char Value)
{
    if (FunctionArr[Function])
        FunctionArr[Function]->WriteByteConfig(Register, Value);
}

/*##################  TPciDevice::WriteWordConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciDevice::WriteWordConfig(int Function, int Register, short int Value)
{
    if (FunctionArr[Function])
        FunctionArr[Function]->WriteWordConfig(Register, Value);
}

/*##################  TPciDevice::WriteDwordConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciDevice::WriteDwordConfig(int Function, int Register, long Value)
{
    if (FunctionArr[Function])
        FunctionArr[Function]->WriteDwordConfig(Register, Value);
}

/*##################  TPciDevice::ReadByteConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciDevice::ReadByteConfig(int Function, int Register)
{
    if (FunctionArr[Function])
        return FunctionArr[Function]->ReadByteConfig(Register);

    return 0xFF;
}

/*##################  TPciDevice::ReadWordConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TPciDevice::ReadWordConfig(int Function, int Register)
{
    if (FunctionArr[Function])
        return FunctionArr[Function]->ReadWordConfig(Register);

    return 0xFFFF;
}

/*##################  TPciDevice::ReadDwordConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TPciDevice::ReadDwordConfig(int Function, int Register)
{
    if (FunctionArr[Function])
        return FunctionArr[Function]->ReadDwordConfig(Register);

    return 0xFFFFFFFF;
}

/*##################  TPci::TPci  ###############
*   Purpose....: Constructor for PCI                                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPci::TPci(TBus *Bus, int PciBus)
  : TBusFunction(Bus)
{
    int i;

    for (i = 0; i < 32; i++)
        DeviceArr[i] = 0;

    FBus = Bus;
    FPciBus = PciBus | 0x8000;        
    FIoBase = 0x4000;
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

    for (i = 0; i < 32; i++)
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

/*##################  TPci::WriteByteConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteByteConfig(int Index, char Value)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            DeviceArr[Device]->WriteByteConfig(Function, Register, Value);
}

/*##################  TPci::WriteWordConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteWordConfig(int Index, short int Value)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            DeviceArr[Device]->WriteWordConfig(Function, Register, Value);
}

/*##################  TPci::WriteDwordConfig  ###############
*   Purpose....: Write config                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteDwordConfig(int Index, long Value)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            DeviceArr[Device]->WriteDwordConfig(Function, Register, Value);
}

/*##################  TPci::ReadByteConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::ReadByteConfig(int Index)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            return DeviceArr[Device]->ReadByteConfig(Function, Register);

    return 0xFF;
}

/*##################  TPci::ReadWordConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TPci::ReadWordConfig(int Index)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            return DeviceArr[Device]->ReadWordConfig(Function, Register);

    return 0xFFFF;
}

/*##################  TPci::ReadDwordConfig  ###############
*   Purpose....: Read config                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TPci::ReadDwordConfig(int Index)
{
    int Bus = (Index >> 16) & 0xFFFF;
    int Device = (Index >> 11) & 0x1F;
    int Function = (Index >> 8) & 0x7;
    int Register = Index & 0xFF;

    if (Bus == FPciBus)
        if (DeviceArr[Device])
            return DeviceArr[Device]->ReadDwordConfig(Function, Register);

    return 0xFFFFFFFF;
}

/*##################  TPci::OutByte  ###############
*   Purpose....: Perform out instruction                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::OutByte(int Num, int Offset, char Value)
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
            WriteByteConfig(FIndex, Value);
            break;

        case 5:
            WriteByteConfig(FIndex + 1, Value);
            break;

        case 6:
            WriteByteConfig(FIndex + 2, Value);
            break;

        case 7:
            WriteByteConfig(FIndex + 3, Value);
            break;

        default:
            break;

    }
}

/*##################  TPci::OutWord  ###############
*   Purpose....: Perform out instruction                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::OutWord(int Num, int Offset, short int Value)
{
    int LVal;

    LVal = (int)Value & 0xFFFF;

    switch (Offset)
    {
        case 0:
            FIndex = LVal;
            break;

        case 2:
            FIndex |= LVal << 16;
            break;

        case 4:
            WriteWordConfig(FIndex, Value);
            break;

        case 6:
            WriteWordConfig(FIndex + 2, Value);
            break;

        default:
            break;

    }
}

/*##################  TPci::OutDword  ###############
*   Purpose....: Perform out instruction                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::OutDword(int Num, int Offset, long Value)
{
    switch (Offset)
    {
        case 0:
            FIndex = Value;
            break;

        case 4:
            WriteDwordConfig(FIndex, Value);
            break;

        default:
            break;

    }
}

/*##################  TPci::InByte  ###############
*   Purpose....: Perform in instruction                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::InByte(int Num, int Offset)
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
            return ReadByteConfig(FIndex);

        case 5:
            return ReadByteConfig(FIndex + 1);

        case 6:
            return ReadByteConfig(FIndex + 2);

        case 7:
            return ReadByteConfig(FIndex + 3);

        default:
            return 0xFF;
    }
}

/*##################  TPci::InWord  ###############
*   Purpose....: Perform in instruction                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TPci::InWord(int Num, int Offset)
{
    switch (Offset)
    {
        case 0:
            return (short int)(FIndex & 0xFFFF);

        case 2:
            return (short int)((FIndex >> 16) & 0xFFFF);

        case 4:
            return ReadWordConfig(FIndex);

        case 6:
            return ReadWordConfig(FIndex + 2);

        default:
            return 0xFFFF;
    }
}

/*##################  TPci::InDword  ###############
*   Purpose....: Perform in instruction                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TPci::InDword(int Num, int Offset)
{
    switch (Offset)
    {
        case 0:
            return FIndex;

        case 4:
            return ReadDwordConfig(FIndex);

        default:
            return 0xFFFFFFFF;
    }
}

/*##################  TPci::GetBus  ###############
*   Purpose....: Get bus                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
TBus *TPci::GetBus()
{
    return FBus;
}

/*##################  TPci::AllocateIo  ###############
*   Purpose....: Allocate IO range                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TPci::AllocateIo(int Size)
{
    int IoBase = FIoBase;

    FIoBase += Size;
    return IoBase;
}

/*##################  TPci::Add  ###############
*   Purpose....: Add PCI device                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::Add(TPciFunction *PciFunction)
{
    int dev;

    for (dev = 0; dev < 32; dev++)
        if (DeviceArr[dev] == 0)
            break;

    if (DeviceArr[dev] == 0)
    {
        DeviceArr[dev] = new TPciDevice;
        DeviceArr[dev]->Add(PciFunction);
    }
}
