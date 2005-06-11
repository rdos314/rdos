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
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TPciFunction::TPciFunction(TPci *Pci)
{
    int i;

    for (i = 0; i < 256; i++)
    {
        FConfig[i] = 0;
        FData[i] = 0xFF;
        FIoArr[i] = 0;
        FMemArr[i] = 0;
    }

	FPci = Pci;
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

/*##################  TPciFunction::WriteMem  ###############
*   Purpose....: Write to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::WriteMem(int Num, unsigned long Offset, char Value)
{
    TPciAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TPciFunction::ReadMem  ###############
*   Purpose....: Read from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciFunction::ReadMem(int Num, unsigned long Offset)
{
    TPciAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TPciFunction::Out  ###############
*   Purpose....: Out to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::Out(int Num, int Offset, char Value)
{
    TPciAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TPciFunction::In  ###############
*   Purpose....: In from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPciFunction::In(int Num, int Offset)
{
    TPciAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TPciFunction::DefineIo  ###############
*   Purpose....: Define an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::DefineIo(int Num, int Base, int Size, char *Data)
{
    TPciAreaData *area;
    
    if (FIoArr[Num])
    {
		FPci->UndefineIo(this, Num);
		delete FIoArr[Num];
    }

    area = new TPciAreaData;
    area->Base = Base;
    area->Size = Size;
    area->Data = Data;
    FIoArr[Num] = area;

    FPci->DefineIo(this, Num, Base, Size);
}

/*##################  TPciFunction::UndefineIo  ###############
*   Purpose....: Undefine an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::UndefineIo(int Num)
{
    if (FIoArr[Num])
    {
        FPci->UndefineIo(this, Num);
        delete FIoArr[Num];
        FIoArr[Num] = 0;
    }
}

/*##################  TPciFunction::DefineMem  ###############
*   Purpose....: Define a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::DefineMem(int Num, int Base, int Size, char *Data)
{
    TPciAreaData *area;
    
    if (FMemArr[Num])
    {
        FPci->UndefineMem(this, Num);
        delete FMemArr[Num];
    }

    area = new TPciAreaData;
    area->Base = Base;
    area->Size = Size;
    area->Data = Data;
    FMemArr[Num] = area;

    FPci->DefineMem(this, Num, Base, Size);
}

/*##################  TPciFunction::UndefineMem  ###############
*   Purpose....: Undefine a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPciFunction::UndefineMem(int Num)
{
    if (FMemArr[Num])
    {
        FPci->UndefineMem(this, Num);
        delete FMemArr[Num];
        FMemArr[Num] = 0;
    }
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
TPci::TPci(TBus *Isa)
{
    int i;

	FIsa = Isa;
    FIndex = 0;
    FValue = 0;
    FIndexChanged = FALSE;
    FDataChanged = FALSE;
    FKeyboardEnabled = FALSE;

    for (i = 0; i < 256; i++)
	{
        FBusArr[i] = 0;
		FHookIoArr[i] = 0;
		FHookMemArr[i] = 0;
	}
	FHookIoMax = 0;
	FHookMemMax = 0;
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

    for (i = 0; i < 256; i++)
	{
        if (FBusArr[i])
            delete FBusArr[i];

		if (FHookIoArr[i])
			delete FHookIoArr[i];

		if (FHookMemArr[i])
			delete FHookMemArr[i];
	}
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

/*##################  TPci::EnableKeyboard  ###############
*   Purpose....: Enable keyboard							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::EnableKeyboard()
{
    FKeyboardEnabled = TRUE;
}

/*##################  TPci::IsKeyboardEnabled  ###############
*   Purpose....: Check if keyboard is enabled							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TPci::IsKeyboardEnabled()
{
    return FKeyboardEnabled;
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
    
    switch (Port)
    {
		case 0x60:
		case 0x62:
		case 0x64:
			if (FKeyboardEnabled)
				DefaultOut(Port, Value);
			break;

        case 0xCF8:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex = LVal;
            FIndexChanged = TRUE;
            break;

        case 0xCF9:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 8;
            FIndexChanged = TRUE;
            break;

        case 0xCFA:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 16;
            FIndexChanged = TRUE;
            break;

        case 0xCFB:
            if (FDataChanged)
            {
                WriteData(FIndex, FValue);
                FDataChanged = FALSE;
            }
            FIndex |= LVal << 24;
            FIndexChanged = TRUE;
            break;

        case 0xCFC:
            FDataChanged = TRUE;
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFFFFFF00;
			FValue |= LVal;
			break;

		case 0xCFD:
			FDataChanged = TRUE;
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFFFF00FF;
			FValue |= LVal << 8;
			break;

		case 0xCFE:
			FDataChanged = TRUE;
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			FValue &= 0xFF00FFFF;
			FValue |= LVal << 16;
			break;

		case 0xCFF:
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

		default:
			DefaultOut(Port, Value);
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
	switch (Port)
	{
		case 0x60:
		case 0x62:
		case 0x64:
			if (FKeyboardEnabled)
				return DefaultIn(Port);
			else
				return 0xFF;
				
		case 0xCF8:
			return (char)(FIndex & 0xFF);

		case 0xCF9:
			return (char)((FIndex >> 8) & 0xFF);

		case 0xCFA:
			return (char)((FIndex >> 16) & 0xFF);

		case 0xCFB:
            return (char)((FIndex >> 24) & 0xFF);

        case 0xCFC:
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
                FIndexChanged = FALSE;
            }
            return (char)(FValue & 0xFF);

        case 0xCFD:
            if (FIndexChanged)
            {
				FValue = ReadData(FIndex);
                FIndexChanged = FALSE;
            }
            return (char)((FValue >> 8) & 0xFF);

		case 0xCFE:
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			return (char)((FValue >> 16) & 0xFF);

		case 0xCFF:
			if (FIndexChanged)
			{
				FValue = ReadData(FIndex);
				FIndexChanged = FALSE;
			}
			return (char)((FValue >> 24) & 0xFF);

		default:
			return DefaultIn(Port);
	}
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

/*##################  TPci::DefineIo  ###############
*   Purpose....: Define an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::DefineIo(TPciFunction *func, int Num, int Base, int Size)
{
	TPciArea *area;
	int i;

	area = new TPciArea;
	area->Base = Base;
	area->Size = Size;
	area->func = func;
	area->Num = Num;

	for (i = 0; i < 256; i++)
		if (FHookIoArr[i] == 0)
		{
			FHookIoArr[i] = area;
			if (i > FHookIoMax)
				FHookIoMax = i;
			break;
		}
}

/*##################  TPci::UndefineIo  ###############
*   Purpose....: Undefine an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::UndefineIo(TPciFunction *func, int Num)
{
	TPciArea *area;
	int i;

	for (i = 0; i < 256; i++)
	{
		area = FHookIoArr[i];
		if (area)
			if (area->func == func && area->Num == Num)
			{
				delete area;
				FHookIoArr[i] = 0;
				break;
			}
	}
}

/*##################  TPci::DefineMem  ###############
*   Purpose....: Define a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::DefineMem(TPciFunction *func, int Num, int Base, int Size)
{
	TPciArea *area;
	int i;

	area = new TPciArea;
	area->Base = Base;
	area->Size = Size;
	area->func = func;
	area->Num = Num;

	for (i = 0; i < 256; i++)
		if (FHookMemArr[i] == 0)
		{
			FHookMemArr[i] = area;
			if (i > FHookMemMax)
				FHookMemMax = i;
			break;
		}
}

/*##################  TPci::UndefineMem  ###############
*   Purpose....: Undefine a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::UndefineMem(TPciFunction *func, int Num)
{
	TPciArea *area;
	int i;

	for (i = 0; i < 256; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->func == func && area->Num == Num)
			{
				delete area;
				FHookMemArr[i] = 0;
				break;
			}
	}
}

/*##################  TPci::WriteMem  ###############
*   Purpose....: Perform write memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::WriteMem(unsigned long Address, char Value)
{
	TPciArea *area;
	int i;

	for (i = 0; i <= FHookMemMax; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->Base <= Address && area->Base + area->Size - 1 >= Address)
			{
				area->func->WriteMem(area->Num, Address - area->Base, Value);
				return;
			}
	}

	FIsa->WriteMem(Address, Value);
}

/*##################  TPci::ReadMem  ###############
*   Purpose....: Perform read memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::ReadMem(unsigned long Address)
{
	TPciArea *area;
	int i;

	for (i = 0; i <= FHookMemMax; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->Base <= Address && area->Base + area->Size - 1 >= Address)
				return area->func->ReadMem(area->Num, Address - area->Base);
	}

	return FIsa->ReadMem(Address);
}

/*##################  TPci::DefaultOut  ###############
*   Purpose....: Perform default out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TPci::DefaultOut(int Port, char Value)
{
	TPciArea *area;
	int i;

	for (i = 0; i <= FHookIoMax; i++)
	{
		area = FHookIoArr[i];
		if (area)
			if (area->Base <= Port && area->Base + area->Size > Port)
			{
				area->func->Out(area->Num, Port - area->Base, Value);
				return;
			}
	}

	FIsa->Out(Port, Value);
}

/*##################  TPci::DefaultIn  ###############
*   Purpose....: Perform default in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TPci::DefaultIn(int Port)
{
	TPciArea *area;
	int i;

	for (i = 0; i <= FHookIoMax; i++)
	{
		area = FHookIoArr[i];
		if (area)
			if (area->Base <= Port && area->Base + area->Size > Port)
				return area->func->In(area->Num, Port - area->Base);
	}

	return FIsa->In(Port);
}
