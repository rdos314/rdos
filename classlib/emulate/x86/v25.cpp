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
    FBus = 0;
    memset(FIdb, 0xFF, 0x100);
    FIdb[0xFF] = 0;
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
    FIdb[0xFF] = 0;
}

/*##################  TV25Cpu::DefineBus  ###############
*   Purpose....: Define bus                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::DefineBus(TBus *Bus)
{
    FBus = Bus;
}

/*##################  TV25Cpu::ReadIdbByte  ###############
*   Purpose....: Read byte from IDB                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TV25Cpu::ReadIdbByte(int offset)
{
    return FIdb[offset];
}

/*##################  TV25Cpu::ReadIdbWord  ###############
*   Purpose....: Read word from IDB                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TV25Cpu::ReadIdbWord(int offset)
{
    short int *ptr = (short int *)(FIdb + offset);
    return *ptr;
}

/*##################  TV25Cpu::WriteIdbByte  ###############
*   Purpose....: Write byte to IDB                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteIdbByte(int offset, char val)
{
    FIdb[offset] = val;
}

/*##################  TV25Cpu::WriteIdbWord  ###############
*   Purpose....: Write word to IDB                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteIdbWord(int offset, short int val)
{
    short int *ptr = (short int *)(FIdb + offset);
    *ptr = val;
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
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;

    if (Address == 0xFFFFF)
        return FIdb[0xFF];

    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
            return ReadIdbByte(offset & 0xFF);
        else
            return -1;
    }

    if (FBus)
        return FBus->ReadMemoryByte(Address);
    else
        return -1;
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
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;

    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
            return ReadIdbWord(offset & 0xFF);
        else
            return -1;
    }

    if (FBus)
        return FBus->ReadMemoryWord(Address);
    else
        return -1;
}

/*##################  TV25Cpu::ReadMemoryDword  ###############
*   Purpose....: Read dword from memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TV25Cpu::ReadMemoryDword(unsigned long long Address)
{
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;

    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
        {
            offset = offset & 0xFF;
            return *(long *)(FIdb + offset);
        }
        else
            return -1;
    }

    if (FBus)
        return FBus->ReadMemoryDword(Address);
    else
        return -1;
}

/*##################  TV25Cpu::ReadMemoryQword  ###############
*   Purpose....: Read qword from memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long long TV25Cpu::ReadMemoryQword(unsigned long long Address)
{
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;

    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
        {
            offset = offset & 0xFF;
            return *(long long *)(FIdb + offset);
        }
        else
            return -1;
    }

    if (FBus)
        return FBus->ReadMemoryQword(Address);
    else
        return -1;
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
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;
    
    if (Address == 0xFFFFF)
    {
        FIdb[0xFF] = val;
        return;
    }

    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
            WriteIdbByte(offset & 0xFF, val);
        return;
    }

    FBus->WriteMemoryByte(Address, val);
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
    unsigned long IdbBase = FIdb[0xFF] << 12;
    int offset;
    
    if ((Address & 0xFF000) == IdbBase)
    {
        offset = Address & 0xFFF;
        if (offset >= 0xF00)
            WriteIdbWord(offset & 0xFF, val);
        return;
    }

    FBus->WriteMemoryWord(Address, val);
}

/*##################  TV25Cpu::WriteMemoryDword  ###############
*   Purpose....: Write memory dword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteMemoryDword(unsigned long long Address, long val)
{
}

/*##################  TV25Cpu::WriteMemoryQword  ###############
*   Purpose....: Write memory qword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TV25Cpu::WriteMemoryQword(unsigned long long Address, long long val)
{
}
