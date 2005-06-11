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
* BUS.CPP
* Bus emulation
*
*##########################################################################*/

#include "bus.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TBusFunction::TBusFunction  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TBusFunction::TBusFunction(TBus *Bus)
{
    int i;

    for (i = 0; i < 256; i++)
    {
        FIoArr[i] = 0;
        FMemArr[i] = 0;
    }

	FBus = Bus;
}

/*##################  TBusFunction::WriteMem  ###############
*   Purpose....: Write to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::WriteMem(int Num, unsigned long Offset, char Value)
{
    TBusAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TBusFunction::ReadMem  ###############
*   Purpose....: Read from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TBusFunction::ReadMem(int Num, unsigned long Offset)
{
    TBusAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TBusFunction::Out  ###############
*   Purpose....: Out to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::Out(int Num, int Offset, char Value)
{
    TBusAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TBusFunction::In  ###############
*   Purpose....: In from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TBusFunction::In(int Num, int Offset)
{
    TBusAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TBusFunction::DefineIo  ###############
*   Purpose....: Define an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::DefineIo(int Num, int Base, int Size, char *Data)
{
    TBusAreaData *area;

    if (FIoArr[Num])
    {
        if (FBus)
    	    FBus->UndefineIo(this, Num);
        delete FIoArr[Num];
    }

    area = new TBusAreaData;
    area->Base = Base;
    area->Size = Size;
    area->Data = Data;
    FIoArr[Num] = area;

    if (FBus)
        FBus->DefineIo(this, Num, Base, Size);
}

/*##################  TBusFunction::UndefineIo  ###############
*   Purpose....: Undefine an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::UndefineIo(int Num)
{
    if (FIoArr[Num])
    {
        if (FBus)
            FBus->UndefineIo(this, Num);

        delete FIoArr[Num];
        FIoArr[Num] = 0;
    }
}

/*##################  TBusFunction::DefineMem  ###############
*   Purpose....: Define a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::DefineMem(int Num, int Base, int Size, char *Data)
{
    TBusAreaData *area;

    if (FMemArr[Num])
    {
        if (FBus)
            FBus->UndefineMem(this, Num);

        delete FMemArr[Num];
    }

    area = new TBusAreaData;
    area->Base = Base & 0x00FFFFFF;
    area->Size = Size;
    area->Data = Data;
    FMemArr[Num] = area;

    if (FBus)
        FBus->DefineMem(this, Num, Base, Size);
}

/*##################  TBusFunction::UndefineMem  ###############
*   Purpose....: Undefine a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBusFunction::UndefineMem(int Num)
{
    if (FMemArr[Num])
    {
        if (FBus)
            FBus->UndefineMem(this, Num);

        delete FMemArr[Num];
        FMemArr[Num] = 0;
    }
}

/*##################  TBus::TBus  ###############
*   Purpose....: Constructor for Bus							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TBus::TBus()
{
    int i;

    for (i = 0; i < 256; i++)
	{
		FHookIoArr[i] = 0;
		FHookMemArr[i] = 0;
	}
	FHookIoMax = 0;
	FHookMemMax = 0;
}

/*##################  TBus::~TBus  ###############
*   Purpose....: Destructor for bus					            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TBus::~TBus()
{
    int i;

    for (i = 0; i < 256; i++)
	{
		if (FHookIoArr[i])
			delete FHookIoArr[i];

		if (FHookMemArr[i])
			delete FHookMemArr[i];
	}
}

/*##################  TBus::DefineIo  ###############
*   Purpose....: Define an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::DefineIo(TBusFunction *func, int Num, int Base, int Size)
{
	TBusArea *area;
	int i;

	area = new TBusArea;
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

/*##################  TBus::UndefineIo  ###############
*   Purpose....: Undefine an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::UndefineIo(TBusFunction *func, int Num)
{
	TBusArea *area;
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

/*##################  TBus::DefineMem  ###############
*   Purpose....: Define a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::DefineMem(TBusFunction *func, int Num, int Base, int Size)
{
	TBusArea *area;
	int i;

	area = new TBusArea;
	area->Base = Base & 0x00FFFFFF;
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

/*##################  TBus::UndefineMem  ###############
*   Purpose....: Undefine a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::UndefineMem(TBusFunction *func, int Num)
{
	TBusArea *area;
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

/*##################  TBus::WriteMem  ###############
*   Purpose....: Perform write memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::WriteMem(unsigned long Address, char Value)
{
	TBusArea *area;
	int i;

	Address = Address & 0x00FFFFFF;

	for (i = 0; i <= FHookMemMax; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->Base <= Address && area->Base + area->Size - 1 >= Address)
			{
				area->func->WriteMem(area->Num, Address - area->Base, Value);
				break;
			}
	}
}

/*##################  TBus::ReadMem  ###############
*   Purpose....: Perform read memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TBus::ReadMem(unsigned long Address)
{
	TBusArea *area;
	int i;

	Address = Address & 0x00FFFFFF;

	for (i = 0; i <= FHookMemMax; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->Base <= Address && area->Base + area->Size - 1 >= Address)
				return area->func->ReadMem(area->Num, Address - area->Base);
	}
	return 0xFF;
}

/*##################  TBus::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TBus::Out(int Port, char Value)
{
	TBusArea *area;
	int i;

	for (i = 0; i <= FHookIoMax; i++)
	{
		area = FHookIoArr[i];
		if (area)
			if (area->Base <= Port && area->Base + area->Size > Port)
			{
				area->func->Out(area->Num, Port - area->Base, Value);
				break;
			}
	}
}

/*##################  TBus::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TBus::In(int Port)
{
	TBusArea *area;
	int i;

	for (i = 0; i <= FHookIoMax; i++)
	{
		area = FHookIoArr[i];
		if (area)
			if (area->Base <= Port && area->Base + area->Size > Port)
				return area->func->In(area->Num, Port - area->Base);
	}
	return 0xFF;
}
