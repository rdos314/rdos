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
* ISA.CPP
* ISA bus emulation
*
*##########################################################################*/

#include "isa.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TIsaFunction::IsaFunction  ###############
*   Purpose....: Constructor							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TIsaFunction::TIsaFunction(TIsa *Isa)
{
    int i;

    for (i = 0; i < 256; i++)
    {
        FIoArr[i] = 0;
        FMemArr[i] = 0;
    }

	FIsa = Isa;
}

/*##################  TIsaFunction::WriteMem  ###############
*   Purpose....: Write to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::WriteMem(int Num, unsigned long Offset, char Value)
{
    TIsaAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TIsaFunction::ReadMem  ###############
*   Purpose....: Read from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TIsaFunction::ReadMem(int Num, unsigned long Offset)
{
    TIsaAreaData *area;

    area = FMemArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TIsaFunction::Out  ###############
*   Purpose....: Out to data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::Out(int Num, int Offset, char Value)
{
    TIsaAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			*(area->Data + Offset) = Value;

}

/*##################  TIsaFunction::In  ###############
*   Purpose....: In from data block								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TIsaFunction::In(int Num, int Offset)
{
    TIsaAreaData *area;

    area = FIoArr[Num];
    if (area)
		if (area->Data && Offset >= 0 && Offset < area->Size)
			return *(area->Data + Offset);

	return 0xFF;
}

/*##################  TIsaFunction::DefineIo  ###############
*   Purpose....: Define an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::DefineIo(int Num, int Base, int Size, char *Data)
{
    TIsaAreaData *area;
    
    if (FIoArr[Num])
    {
		FIsa->UndefineIo(this, Num);
		delete FIoArr[Num];
    }

    area = new TIsaAreaData;
    area->Base = Base;
    area->Size = Size;
    area->Data = Data;
    FIoArr[Num] = area;

    FIsa->DefineIo(this, Num, Base, Size);
}

/*##################  TIsaFunction::UndefineIo  ###############
*   Purpose....: Undefine an io area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::UndefineIo(int Num)
{
    if (FIoArr[Num])
    {
        FIsa->UndefineIo(this, Num);
        delete FIoArr[Num];
        FIoArr[Num] = 0;
    }
}

/*##################  TIsaFunction::DefineMem  ###############
*   Purpose....: Define a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::DefineMem(int Num, int Base, int Size, char *Data)
{
    TIsaAreaData *area;
    
    if (FMemArr[Num])
    {
        FIsa->UndefineMem(this, Num);
        delete FMemArr[Num];
    }

    area = new TIsaAreaData;
    area->Base = Base;
    area->Size = Size;
    area->Data = Data;
    FMemArr[Num] = area;

    FIsa->DefineMem(this, Num, Base, Size);
}

/*##################  TIsaFunction::UndefineMem  ###############
*   Purpose....: Undefine a memory area								            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsaFunction::UndefineMem(int Num)
{
    if (FMemArr[Num])
    {
        FIsa->UndefineMem(this, Num);
        delete FMemArr[Num];
        FMemArr[Num] = 0;
    }
}

/*##################  TIsa::TIsa  ###############
*   Purpose....: Constructor for ISA							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TIsa::TIsa()
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

/*##################  TIsa::~TIsa  ###############
*   Purpose....: Destructor for ISA							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TIsa::~TIsa()
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

/*##################  TIsa::DefineIo  ###############
*   Purpose....: Define an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::DefineIo(TIsaFunction *func, int Num, int Base, int Size)
{
	TIsaArea *area;
	int i;

	area = new TIsaArea;
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

/*##################  TIsa::UndefineIo  ###############
*   Purpose....: Undefine an IO area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::UndefineIo(TIsaFunction *func, int Num)
{
	TIsaArea *area;
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

/*##################  TIsa::DefineMem  ###############
*   Purpose....: Define a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::DefineMem(TIsaFunction *func, int Num, int Base, int Size)
{
	TIsaArea *area;
	int i;

	area = new TIsaArea;
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

/*##################  TIsa::UndefineMem  ###############
*   Purpose....: Undefine a memory area						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::UndefineMem(TIsaFunction *func, int Num)
{
	TIsaArea *area;
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

/*##################  TIsa::WriteMem  ###############
*   Purpose....: Perform write memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::WriteMem(unsigned long Address, char Value)
{
	TIsaArea *area;
	int i;

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

/*##################  TIsa::ReadMem  ###############
*   Purpose....: Perform read memory instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TIsa::ReadMem(unsigned long Address)
{
	TIsaArea *area;
	int i;

	for (i = 0; i <= FHookMemMax; i++)
	{
		area = FHookMemArr[i];
		if (area)
			if (area->Base <= Address && area->Base + area->Size - 1 >= Address)
				return area->func->ReadMem(area->Num, Address - area->Base);
	}
	return 0xFF;
}

/*##################  TIsa::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TIsa::Out(int Port, char Value)
{
	TIsaArea *area;
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

/*##################  TIsa::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TIsa::In(int Port)
{
	TIsaArea *area;
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
