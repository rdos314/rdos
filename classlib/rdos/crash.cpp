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
    TCrashCoreInfo *info;

    if (RdosGetCrashCoreInfo(Core, CrashBuf))
    {
        info = new TCrashCoreInfo;
        CrashInfo[Core] = info;
    }    
}
