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
* CPU.CPP
* CPU emulation
*
*##########################################################################*/

#include <stdio.h>
#include <mem.h>

#include "v25.h"
#include "ram.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TV25Cpu::TV25Cpu  ###############
*   Purpose....: Constructor for V25 CPU							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TV25Cpu::TV25Cpu()
{
    FIdb = new char[0x1000];
    memset(FIdb, 0xFF, 0x1000);
}

/*##################  TV25::~TV25  ###############
*   Purpose....: Destructor for V25							            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TV25Cpu::~TV25Cpu()
{
    if (FIdb)
        delete FIdb;
}

/*##################  TV25Cpu::Reset  ###############
*   Purpose....: Set CPU registers to reset state				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::Reset()
{
	TCpu::Reset();
	Reg_cs.base = 0xF0000;
	*(FIdb + 0xFFF) = 0xFF;
}

/*##################  TV25Cpu::ReadCode  ###############
*   Purpose....: Read code                      				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TV25Cpu::ReadCode(unsigned long Address)
{
	return TCpu::ReadCode(Address);
}

/*##################  TV25Cpu::ReadFromMemory  ###############
*   Purpose....: Read from memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TV25Cpu::ReadFromMemory(unsigned long Address)
{
    unsigned long IdbBase = *(FIdb + 0xFFF) << 12;

	if (Address == 0xFFFFF)
		return *(FIdb + 0xFFF);

	if ((Address & 0xFF000) == IdbBase)
		return *(FIdb + (Address & 0xFFF));

	return TCpu::ReadFromMemory(Address);
}

/*##################  TV25Cpu::WriteToMemory  ###############
*   Purpose....: Write to memory				            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteToMemory(unsigned long Address, char Value)
{
	unsigned long IdbBase = *(FIdb + 0xFFF) << 12;
    
    if (Address == 0xFFFFF)
    {
        *(FIdb + 0xFFF) = Value;
        return;
    }

    if ((Address & 0xFF000) == IdbBase)
    {
        *(FIdb + (Address & 0xFFF)) = Value;
        return;
    }

    TCpu::WriteToMemory(Address, Value);
}
