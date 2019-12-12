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
* emreal.cpp
* Emulate realtime system
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include <memory.h>
#include "path.h"
#include "sigdev.h"
#include "cpu.h"

#define STACK_SIZE  0x4000

#define FALSE 0
#define TRUE !FALSE

/*##################  ReadMemoryByte  ###############
*   Purpose....: Read memory byte                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadMemoryByte(TCpu *Cpu, unsigned long long Address)
{
    return RdosReadPhysicalByte(Address);
}

/*##################  ReadMemoryWord  ###############
*   Purpose....: Read memory word                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int ReadMemoryWord(TCpu *Cpu, unsigned long long Address)
{
    return RdosReadPhysicalWord(Address);
}

/*##################  ReadMemoryDword  ###############
*   Purpose....: Read memory dword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long ReadMemoryDword(TCpu *Cpu, unsigned long long Address)
{
    return RdosReadPhysicalDword(Address);
}

/*##################  ReadMemoryQword  ###############
*   Purpose....: Read memory qword                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long long ReadMemoryQword(TCpu *Cpu, unsigned long long Address)
{
    return RdosReadPhysicalQword(Address);
}

/*##################  WriteMemoryByte  ###############
*   Purpose....:  Write memory byte                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryByte(TCpu *Cpu, unsigned long long Address, char Value)
{
    RdosWritePhysicalByte(Address, Value);
}

/*##################  WriteMemoryWord  ###############
*   Purpose....:  Write memory word                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryWord(TCpu *Cpu, unsigned long long Address, short int Value)
{
    RdosWritePhysicalWord(Address, Value);
}

/*##################  WriteMemoryDword  ###############
*   Purpose....:  Write memory dword                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryDword(TCpu *Cpu, unsigned long long Address, long Value)
{
    RdosWritePhysicalDword(Address, Value);
}

/*##################  WriteMemoryQword  ###############
*   Purpose....:  Write memory qword                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteMemoryQword(TCpu *Cpu, unsigned long long Address, long long Value)
{
    RdosWritePhysicalQword(Address, Value);
}

/*##################  main  ###############
*   Purpose....: main                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void main(void)
{
    char Key;
    TCpu Cpu;

    Cpu.OnReadMemoryByte = ReadMemoryByte;
    Cpu.OnReadMemoryWord = ReadMemoryWord;
    Cpu.OnReadMemoryDword = ReadMemoryDword;
    Cpu.OnReadMemoryQword = ReadMemoryQword;
    Cpu.OnWriteMemoryByte = WriteMemoryByte;
    Cpu.OnWriteMemoryWord = WriteMemoryWord;
    Cpu.OnWriteMemoryDword = WriteMemoryDword;
    Cpu.OnWriteMemoryQword = WriteMemoryQword;
    Cpu.Reset();
    Cpu.CpuState.Reg_cs.base = 0x1000;
    Cpu.CpuState.Reg_cs.selector = 0x100;
    Cpu.CpuState.Reg_eip = 0;
   
    RdosEmulateRealtime();
 
    while (1)
    {
        Cpu.Show();
        Key = RdosReadKeyboard() & 0xFF;
        switch (Key)
        {
            case 'f':
            case 'F':
                Cpu.ShowFpu();
                RdosReadKeyboard();
                break;

            case 'q':
            case 'Q':
                return;

            case 't':
            case 'T':
                Cpu.Trace();
                break;

            case 'p':
            case 'P':
                Cpu.Pace();
                break;

            case 'g':
            case 'G':
                Cpu.Go();
                break;

            case 'u':
            case 'U':
                Cpu.ShowInstruction();
                RdosReadKeyboard();
                break;
        }
    }
}
