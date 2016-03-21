/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# crash.cpp
# Crash info class
#
########################################################################*/

#include "rdos.h"
#include "crash.h"
#include <string.h>

#define FALSE 0
#define TRUE !FALSE

struct TRdosSelector
{
    short int Sel;
    short int Flags;
    int Base;
    int Limit;
};

struct TRdosCrashCore
{
    char Filler[12];
    int Sign;

    int Irq;
    int Fault;

    int Cr0;
    int Cr2;
    int Cr3;
    int Cr4;

    int Dr0;
    int Dr1;
    int Dr2;
    int Dr3;
    int Dr7;

    long long Rip;
    long long Rflags;
    long long Rax;
    long long Rcx;
    long long Rdx;
    long long Rbx;
    long long Rsp;
    long long Rbp;
    long long Rsi;
    long long Rdi;
    long long R8;
    long long R9;
    long long R10;
    long long R11;
    long long R12;
    long long R13;
    long long R14;
    long long R15;

    struct TRdosSelector Es;
    struct TRdosSelector Cs;
    struct TRdosSelector Ss;
    struct TRdosSelector Ds;
    struct TRdosSelector Fs;
    struct TRdosSelector Gs;

    struct TRdosSelector Ldt;
    struct TRdosSelector Tr;
    struct TRdosSelector Gdtr;
    struct TRdosSelector Idtr;
};

static char CrashBuf[0x4000];

/*##########################################################################
#
#   Name       : DecodeCrashSelector
#
#   Purpose....: Decode crash selector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void DecodeCrashSelector(TCrashSelectorInfo *info, struct TRdosSelector *raw)
{
    if (raw->Flags & 0x80)
    {
        switch (raw->Flags & 0x1F)
        {
            case 0:
            case 8:
            case 0xA:
            case 0xD:
                strcpy(info->InfoText, "Invalid");
                break;

            case 1:
                strcpy(info->InfoText, "TSS 16, avail");
                break;

            case 2:
                strcpy(info->InfoText, "LDT");
                break;

            case 3:
                strcpy(info->InfoText, "TSS 16, busy");
                break;

            case 4:
                strcpy(info->InfoText, "Call gate 16");
                break;

            case 5:
                strcpy(info->InfoText, "Task gate");
                break;

            case 6:
                strcpy(info->InfoText, "Int gate 16");
                break;

            case 7:
                strcpy(info->InfoText, "Trap gate 16");
                break;

            case 9:
                strcpy(info->InfoText, "TSS 32, avail");
                break;

            case 0xB:
                strcpy(info->InfoText, "TSS 32, busy");
                break;

            case 0xC:
                strcpy(info->InfoText, "Call gate 32");
                break;

            case 0xE:
                strcpy(info->InfoText, "Int gate 32");
                break;

            case 0xF:
                strcpy(info->InfoText, "Trap gate 32");
                break;

            case 0x10:
            case 0x11:
                strcpy(info->InfoText, "Read, up");
                break;

            case 0x12:
            case 0x13:
                strcpy(info->InfoText, "Read/write, up");
                break;

            case 0x14:
            case 0x15:
                strcpy(info->InfoText, "Read, down");
                break;

            case 0x16:
            case 0x17:
                strcpy(info->InfoText, "Read/write, down");
                break;

            case 0x18:
            case 0x19:
                strcpy(info->InfoText, "Code");
                break;

            case 0x1A:
            case 0x1B:
                strcpy(info->InfoText, "Code/read");
                break;

            case 0x1C:
            case 0x1D:
                strcpy(info->InfoText, "Code conf");
                break;

            case 0x1E:
            case 0x1F:
                strcpy(info->InfoText, "Code/read conf");
                break;
        }

        info->Selector = raw->Sel;
        info->Base = raw->Base;
        info->Limit = raw->Limit;
        info->Valid = TRUE;
    }
    else
    {
        strcpy(info->InfoText, "Invalid");
        info->Selector = 0;
        info->Base = 0; 
        info->Limit = 0;
        info->Valid = FALSE;
    }
}

/*##########################################################################
#
#   Name       : TCrashInfo::TCrashInfo
#
#   Purpose....: Constructor for TCrashInfo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrashInfo::TCrashInfo()
{
    int i;

    for (i = 0; i < MAX_CRASH_INFO_CORES; i++)
        CrashInfo[i] = 0;

    if (RdosHasCrashInfo())
        for (i = 0; i < MAX_CRASH_INFO_CORES; i++)
            GetCrashInfo(i);
}

/*##########################################################################
#
#   Name       : TCrashInfo::~TCrashInfo
#
#   Purpose....: Destructor for TCrashInfo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrashInfo::~TCrashInfo()
{
    int i;

    for (i = 0; i < MAX_CRASH_INFO_CORES; i++)
        if (CrashInfo[i])
            delete CrashInfo[i];
}

/*##########################################################################
#
#   Name       : TCrashInfo::GetCrashInfo
#
#   Purpose....: Get crash info for core
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCrashInfo::GetCrashInfo(int Core)
{
    struct TRdosCrashCore *raw;
    TCrashCoreInfo *info;

    if (RdosGetCrashCoreInfo(Core, CrashBuf))
    {
        raw = (struct TRdosCrashCore *)CrashBuf;
        info = new TCrashCoreInfo;

        info->Irq = raw->Irq;
        info->Fault = raw->Fault;

        info->Cr0 = raw->Cr0;
        info->Cr2 = raw->Cr2;
        info->Cr3 = raw->Cr3;
        info->Cr4 = raw->Cr4;

        info->Dr0 = raw->Dr0;
        info->Dr1 = raw->Dr1;
        info->Dr2 = raw->Dr2;
        info->Dr3 = raw->Dr3;
        info->Dr7 = raw->Dr7;

        info->Rip = raw->Rip;
        info->Rflags = raw->Rflags;
        info->Rax = raw->Rax;
        info->Rbx = raw->Rbx;
        info->Rcx = raw->Rcx;
        info->Rdx = raw->Rdx;
        info->Rsp = raw->Rsp;
        info->Rbp = raw->Rbp;
        info->Rsi = raw->Rsi;
        info->Rdi = raw->Rdi;
        info->R8 = raw->R8;
        info->R9 = raw->R9;
        info->R10 = raw->R10;
        info->R11 = raw->R11;
        info->R12 = raw->R12;
        info->R13 = raw->R13;
        info->R14 = raw->R14;
        info->R15 = raw->R15;

        DecodeCrashSelector(&info->Es, &raw->Es);
        DecodeCrashSelector(&info->Cs, &raw->Cs);
        DecodeCrashSelector(&info->Ss, &raw->Ss);
        DecodeCrashSelector(&info->Ds, &raw->Ds);
        DecodeCrashSelector(&info->Fs, &raw->Fs);
        DecodeCrashSelector(&info->Gs, &raw->Gs);

        DecodeCrashSelector(&info->Ldt, &raw->Ldt);
        DecodeCrashSelector(&info->Tr, &raw->Tr);
        
        CrashInfo[Core] = info;
    }    
}
