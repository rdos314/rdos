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
* ZFL.CPP
* ZF-Logic emulation
*
*##########################################################################*/

#include "zfl.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TZflMemArea::TZflMemArea  ###############
*   Purpose....: Constructor for mem area class						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZflMemArea::TZflMemArea()
{
    func = 0;
    Enabled = FALSE;
}

/*##################  TZflIoArea::TZflIoArea  ###############
*   Purpose....: Constructor for IO area class						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZflIoArea::TZflIoArea()
{
    func = 0;
    Enabled = FALSE;
}

/*##################  TZFLogic::TZFLogic  ###############
*   Purpose....: Constructor for ZF-Logic						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TZFLogic::TZFLogic(TIsa *Isa, int Base)
  : TIsaFunction(Isa)
{
	int i;

	FIndex = 0;
	for (i = 0; i < 0x82; i++)
		FData[i] = 0;

	FData[0x28] = 0xFF;
	FData[0x2B] = 0xFF;

	DefineIo(4, Base, 8, 0);

    for (i = 0; i < 4; i++)
    {
    	UpdateMemWindow(i);
    	UpdateIoWindow(i);
    }
}

/*##################  TZFLogic::GetSize  ###############
*   Purpose....: Get mapping size of device						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int TZFLogic::GetSize()
{
    return 8;
}

/*##################  TZFLogic::DefineIoCs  ###############
*   Purpose....: Define an IO chip-select device    						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::DefineIoCs(TIsaFunction *func, int Num)
{
    ZflMemArr[Num].func = func;
    UpdateIoWindow(Num);
}

/*##################  TZFLogic::DefineMemCs  ###############
*   Purpose....: Define an mem chip-select device   						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::DefineMemCs(TIsaFunction *func, int Num)
{
    ZflMemArr[Num].func = func;
    UpdateMemWindow(Num);
}

/*##################  TZFLogic::Out  ###############
*   Purpose....: Perform out instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::Out(int Num, int Offset, char Value)
{
    if (Num == 4)
    	switch (Offset)
	    {
    		case 0:
	    		FIndex = Value;
		    	break;

    		case 1:
	    	case 2:
		    	FData[FIndex] = Value;
			    UpdateData(FIndex);
    			break;

	    	case 3:
		    	FData[FIndex + 1] = Value;
			    UpdateData(FIndex + 1);
    			break;

	    	case 4:
			    FData[FIndex + 2] = Value;
		    	UpdateData(FIndex + 2);
    			break;

	    	case 5:
		    	FData[FIndex + 3] = Value;
			    UpdateData(FIndex + 3);
    			break;

	    	default:
		    	break;
    	}
    else
        if (ZflIoArr[Num].Write)
            ZflIoArr[Num].func->Out(0, Offset % ZflIoArr[Num].func->GetSize(), Value);
}

/*##################  TZFLogic::In  ###############
*   Purpose....: Perform in instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TZFLogic::In(int Num, int Offset)
{
    if (Num == 4)
    	switch (Offset)
	    {
		    case 0:
			    return FIndex;

    		case 1:
	    	case 2:
		    	return FData[FIndex];

    		case 3:
	    		return FData[FIndex + 1];

    		case 4:
	    		return FData[FIndex + 2];

    		case 5:
	    		return FData[FIndex + 3];

		    default:
			    return 0xFF;
    	}
    else
        return ZflIoArr[Num].func->In(0, Offset % ZflIoArr[Num].func->GetSize());
}

/*##################  TZFLogic::UpdateData  ###############
*   Purpose....: Update data						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::UpdateData(int Index)
{
    switch (FIndex)
    {
        case 0x14:
        case 0x15:
        case 0x16:
            UpdateIoWindow(0);
            break;

        case 0x18:
        case 0x19:
        case 0x1A:
            UpdateIoWindow(1);
            break;

        case 0x1C:
        case 0x1D:
        case 0x1E:
            UpdateIoWindow(2);
            break;

        case 0x20:
        case 0x21:
        case 0x22:
            UpdateIoWindow(3);
            break;

        case 0x26:
        case 0x27:
        case 0x28:
        case 0x29:
        case 0x2A:
        case 0x2B:
        case 0x2C:
        case 0x2D:
        case 0x2E:
        case 0x2F:
        case 0x30:
        case 0x31:
            UpdateMemWindow(0);
            break;

        case 0x32:
        case 0x33:
        case 0x34:
        case 0x35:
        case 0x36:
        case 0x37:
        case 0x38:
        case 0x39:
        case 0x3A:
        case 0x3B:
        case 0x3C:
        case 0x3D:
            UpdateMemWindow(1);
            break;

        case 0x3E:
        case 0x3F:
        case 0x40:
        case 0x41:
        case 0x42:
        case 0x43:
        case 0x44:
        case 0x45:
        case 0x46:
        case 0x47:
        case 0x48:
        case 0x49:
            UpdateMemWindow(2);
            break;

        case 0x4A:
        case 0x4B:
        case 0x4C:
        case 0x4D:
        case 0x4E:
        case 0x4F:
        case 0x50:
        case 0x51:
        case 0x52:
        case 0x53:
        case 0x54:
        case 0x55:
            UpdateMemWindow(3);
            break;

        case 0x5A:
            UpdateMemWindow(0);        
            UpdateMemWindow(1);        
            UpdateMemWindow(2);        
            UpdateMemWindow(3);
            break;        
        
    }
}

/*##################  TZFLogic::UpdateIoWindow  ###############
*   Purpose....: Update a IO window						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::UpdateIoWindow(int Num)
{
    int IndexBase;

    switch (Num)
    {
        case 0:
            IndexBase = 0x14;
            break;

        case 1:
            IndexBase = 0x18;
            break;

        case 2:
            IndexBase = 0x1C;
            break;

        case 3:
            IndexBase = 0x20;
            break;
    }

    ZflIoArr[Num].Base = FData[IndexBase] & 0xFF;
    ZflIoArr[Num].Base |= (FData[IndexBase + 1] << 8) & 0xFF00;

    ZflIoArr[Num].Size = FData[IndexBase + 2] & 0xF + 1;

	if (FData[IndexBase + 2] & 0x10)
		ZflIoArr[Num].Enabled = TRUE;
	else
		ZflIoArr[Num].Enabled = FALSE;

	if (FData[IndexBase + 2] & 0x80)
        ZflIoArr[Num].Write = TRUE;
    else
        ZflIoArr[Num].Write = FALSE;

    if (ZflIoArr[Num].func && ZflIoArr[Num].Enabled)
        DefineIo(Num, ZflIoArr[Num].Base, ZflIoArr[Num].Size, 0);
    else
		UndefineIo(Num);
}

/*##################  TZFLogic::UpdateMemWindow  ###############
*   Purpose....: Update a memory window						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::UpdateMemWindow(int Num)
{
    int IndexBase;

    switch (Num)
    {
        case 0:
            IndexBase = 0x26;
            break;

        case 1:
            IndexBase = 0x32;
            break;

        case 2:
            IndexBase = 0x3E;
            break;

        case 3:
            IndexBase = 0x4A;
            break;
    }

    ZflMemArr[Num].Base = (FData[IndexBase + 1] << 8) & 0xF000;
    ZflMemArr[Num].Base |= (FData[IndexBase + 2] << 16) & 0xFF0000;

	ZflMemArr[Num].Size = (FData[IndexBase + 5] << 8) & 0xF000;
	ZflMemArr[Num].Size |= (FData[IndexBase + 6] << 16) & 0xFF0000;

	ZflMemArr[Num].Page = (FData[IndexBase + 9] << 8) & 0xF000;
	ZflMemArr[Num].Page |= (FData[IndexBase + 10] << 16) & 0xFF0000;

    if (ZflMemArr[Num].Size)
    {
		ZflMemArr[Num].Size += 0x1000;
		ZflMemArr[Num].Enabled = TRUE;
    }
	else
		ZflMemArr[Num].Enabled = FALSE;

	if (FData[0x5A] & (0x10 << Num))
		ZflMemArr[Num].Write = FALSE;
	else
		ZflMemArr[Num].Write = TRUE;

    if (ZflMemArr[Num].func && ZflMemArr[Num].Enabled)
		DefineMem(Num, ZflMemArr[Num].Base, ZflMemArr[Num].Size, 0);
    else
        UndefineMem(Num);		
}

/*##################  TZFLogic::WriteMem  ###############
*   Purpose....: Perform write instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TZFLogic::WriteMem(int Num, unsigned long Offset, char Value)
{
    if (ZflMemArr[Num].Write)
    {
        Offset += ZflMemArr[Num].Base;
        Offset = Offset % ZflMemArr[Num].func->GetSize();
        ZflMemArr[Num].func->WriteMem(0, Offset, Value);
    }
}

/*##################  TZFLogic::ReadMem ###############
*   Purpose....: Perform read instruction						            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TZFLogic::ReadMem(int Num, unsigned long Offset)
{
    Offset += ZflMemArr[Num].Base;
    Offset = Offset % ZflMemArr[Num].func->GetSize();
    return ZflMemArr[Num].func->ReadMem(0, Offset);
}
