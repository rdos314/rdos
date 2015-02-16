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
#include <string.h>

#include "v25.h"
#include "ram.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  TV25Cpu::TV25Cpu  ###############
*   Purpose....: Constructor for V25 CPU                                        #
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
*   Purpose....: Destructor for V25                                     #
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
*   Purpose....: Set CPU registers to reset state                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::Reset()
{
    TCpu::Reset();
    CpuState.Reg_cs.base = 0xF0000;
    *(FIdb + 0xFFF) = 0xFF;
}

/*##################  TV25Cpu::ReadMemoryByte  ###############
*   Purpose....: Read byte from memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TV25Cpu::ReadMemoryByte(unsigned long long Address)
{
    unsigned long IdbBase = *(FIdb + 0xFFF) << 12;

    if (Address == 0xFFFFF)
        return *(FIdb + 0xFFF);

    if ((Address & 0xFF000) == IdbBase)
        return *(FIdb + (Address & 0xFFF));

    return TCpu::ReadMemoryByte(Address);
}

/*##################  TV25Cpu::ReadMemoryWord  ###############
*   Purpose....: Read word from memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TV25Cpu::ReadMemoryWord(unsigned long long Address)
{
    unsigned long IdbBase = *(FIdb + 0xFFF) << 12;

    if ((Address & 0xFF000) == IdbBase)
        return *((short int *)(FIdb + (Address & 0xFFE)));

    return TCpu::ReadMemoryWord(Address);
}

/*##################  TV25Cpu::WriteMemoryByte  ###############
*   Purpose....: Write memory byte                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteMemoryByte(unsigned long long Address, char val)
{
    unsigned long IdbBase = *(FIdb + 0xFFF) << 12;
    
    if (Address == 0xFFFFF)
    {
        *(FIdb + 0xFFF) = val;
        return;
    }

    if ((Address & 0xFF000) == IdbBase)
    {
        *(FIdb + (Address & 0xFFF)) = val;
        return;
    }

    TCpu::WriteMemoryByte(Address, val);
}

/*##################  TV25Cpu::WriteMemoryWord  ###############
*   Purpose....: Write memory word                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteMemoryWord(unsigned long long Address, short int val)
{
    unsigned long IdbBase = *(FIdb + 0xFFF) << 12;
    
    if ((Address & 0xFF000) == IdbBase)
    {
        *((short int *)(FIdb + (Address & 0xFFE))) = val;
        return;
    }

    TCpu::WriteMemoryWord(Address, val);
}
