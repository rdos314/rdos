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
* PCI.CPP
* PCI emulation
*
*##########################################################################*/

#include "pci.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TPciFunction::PciFunction  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciFunction::TPciFunction()
{
    int i;

    for (i = 0; i < 256; i++)
    {
        FConfig[i] = 0;
        FData[i] = 0xFF;
    }
}

/*##################  TPciFunction::ReadConfig  ###############
*   Purpose....: Read config							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TPciFunction::ReadConfig(int Index)
{
    int val;
    int tmp;

    val = FConfig[Index];
    val &= 0xFF;

    tmp = FConfig[Index + 1];
    tmp &= 0xFF;
    val |= tmp << 8;

    tmp = FConfig[Index + 2];
    tmp &= 0xFF;
    val |= tmp << 16;

    tmp = FConfig[Index + 3];
    tmp &= 0xFF;
    val |= tmp << 24;    
    
    return val;
}

/*##################  TPciFunction::ReadData  ###############
*   Purpose....: Read data							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TPciFunction::ReadData(int Index)
{
    int val;
    int tmp;

    val = FData[Index];
    val &= 0xFF;

    tmp = FData[Index + 1];
    tmp &= 0xFF;
    val |= tmp << 8;

    tmp = FData[Index + 2];
    tmp &= 0xFF;
    val |= tmp << 16;

    tmp = FData[Index + 3];
    tmp &= 0xFF;
    val |= tmp << 24;    
    
    return val;
}

/*##################  TPciFunction::WriteConfig  ###############
*   Purpose....: Write config							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteConfig(int Index, int Data)
{
    FConfig[Index] = (char)(Data & 0xFF);
    FConfig[Index + 1] = (char)((Data & 0xFF00) >> 8);
    FConfig[Index + 2] = (char)((Data & 0xFF0000) >> 16);
    FConfig[Index + 3] = (char)((Data & 0xFF000000) >> 24);
}

/*##################  TPciFunction::WriteData  ###############
*   Purpose....: Write data							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteData(int Index, int Data)
{
    FData[Index] = (char)(Data & 0xFF);
    FData[Index + 1] = (char)((Data & 0xFF00) >> 8);
    FData[Index + 2] = (char)((Data & 0xFF0000) >> 16);
    FData[Index + 3] = (char)((Data & 0xFF000000) >> 24);
}

/*##################  TPciDevice::TPciDevice  ###############
*   Purpose....: Constructor for PCI device							            #
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
*   Purpose....: Destructor for PCI device							            #
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

/*##################  TPciBus::TPciBus  ###############
*   Purpose....: Constructor for PCI bus							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciBus::TPciBus()
{
    int i;

    for (i = 0; i < 32; i++)
        DeviceArr[i] = 0;
}

/*##################  TPciBus::~TPciBus  ###############
*   Purpose....: Destructor for PCI bus							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciBus::~TPciBus()
{
    int i;

    for (i = 0; i < 32; i++)
        if (DeviceArr[i])
            delete DeviceArr[i];
}

/*##################  TPci::TPci  ###############
*   Purpose....: Constructor for PCI							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPci::TPci()
{
    int i;

    FIndex = 0;
    FValue = 0;
    FIndexChanged = FALSE;
    FDataChanged = FALSE;

    for (i = 0; i < 256; i++)
        FBusArr[i] = 0;
}

/*##################  TPci::~TPci  ###############
*   Purpose....: Destructor for PCI							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPci::~TPci()
{
    int i;

    for (i = 0; i < 32; i++)
        if (FBusArr[i])
            delete FBusArr[i];
}

/*##################  TPci::RegisterFunction  ###############
*   Purpose....: Register a new device     						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::RegisterFunction(TPciFunction *func, int Bus, int Device, int Function)
{
    TPciBus *BusDev;
    TPciDevice *Dev;

	if (FBusArr[Bus] == 0)
		FBusArr[Bus] = new TPciBus;

	BusDev = FBusArr[Bus];
	if (BusDev->DeviceArr[Device] == 0)
		BusDev->DeviceArr[Device] = new TPciDevice;

	Dev = BusDev->DeviceArr[Device];

	if (Dev->FunctionArr[Function])
		delete Dev->FunctionArr[Function];

	Dev->FunctionArr[Function] = func;
}

/*##################  TPci::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::Out(int Port, char Value)
{
    long LVal;

    LVal = (long)Value & 0xFF;
    
    switch (Port & 0xF)
    {
        case 8:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex = LVal;
            FIndexChanged = TRUE;
            break;

        case 9:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 8;
            FIndexChanged = TRUE;
            break;

        case 0xA:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 16;
            FIndexChanged = TRUE;
            break;

        case 0xB:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 24;
            FIndexChanged = TRUE;
            break;

        case 0xC:
            FDataChanged = TRUE;
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFFFFFF00;
			FValue |= LVal;
			break;

		case 0xD:
			FDataChanged = TRUE;
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFFFF00FF;
			FValue |= LVal << 8;
			break;

		case 0xE:
			FDataChanged = TRUE;
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFF00FFFF;
			FValue |= LVal << 16;
			break;

		case 0xF:
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0x00FFFFFF;
			FValue |= LVal << 24;
			WriteData(FIndex, FValue);
			FDataChanged = FALSE;
			break;

	}
}

/*##################  TPci::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::In(int Port)
{
	switch (Port & 0xF)
	{
		case 8:
			return (char)(FIndex & 0xFF);

		case 9:
			return (char)((FIndex >> 8) & 0xFF);

		case 0xA:
			return (char)((FIndex >> 16) & 0xFF);

		case 0xB:
            return (char)((FIndex >> 24) & 0xFF);

        case 0xC:
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
                FIndexChanged = FALSE;
            }
            return (char)(FValue & 0xFF);

        case 0xD:
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
                FIndexChanged = FALSE;
            }
            return (char)((FValue >> 8) & 0xFF);

		case 0xE:
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			return (char)((FValue >> 16) & 0xFF);

		case 0xF:
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			return (char)((FValue >> 24) & 0xFF);

	}
	return 0xFF;
}

/*##################  TPci::ReadData  ###############
*   Purpose....: Read data index        						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TPci::ReadData(int Index)
{
    
    int i;
    TPciFunction *Function;
    TPciDevice *Dev;
    TPciBus *Bus;

    i = (Index & 0xFF0000) >> 16;

    Bus = FBusArr[i];
    if (Bus)
    {
        i = (Index & 0xF800) >> 11;

        Dev = Bus->DeviceArr[i];                
        if (Dev)
        {
            i = (Index & 0x700) >> 8;

            Function = Dev->FunctionArr[i];
            if (Function)
            {
                if (Index & 0x80000000)
                    return Function->ReadConfig(Index & 0xFF);
                else
                    return Function->ReadData(Index & 0xFF);
            }
            else
                return 0xFFFFFFFF;
        }
        else
            return 0xFFFFFFFF;
    }
    else
        return 0xFFFFFFFF; 
}

/*##################  TPci::WriteData  ###############
*   Purpose....: Write data index        						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteData(int Index, int Data)
{    
    int i;
    TPciFunction *Function;
    TPciDevice *Dev;
    TPciBus *Bus;

    i = (Index & 0xFF0000) >> 16;

    Bus = FBusArr[i];
    if (Bus)
    {
        i = (Index & 0xF800) >> 11;

        Dev = Bus->DeviceArr[i];                
        if (Dev)
        {
            i = (Index & 0x700) >> 8;

            Function = Dev->FunctionArr[i];
            if (Function)
            {
                if (Index & 0x80000000)
                    Function->WriteConfig(Index & 0xFF, Data);
                else
                    Function->WriteData(Index & 0xFF, Data);
            }
        }
    }
}
