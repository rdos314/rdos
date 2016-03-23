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
# crash.h
# Crash info class
#
########################################################################*/

#ifndef _CRASHINFO_H
#define _CRASHINFO_H

#define MAX_CRASH_INFO_CORES    16
#define MAX_CRASH_INFO_THREADS  50
#define MAX_CRASH_INFO_LOGS     0x200

#include "datetime.h"

class TCrashLogInfo
{
public:
    TCrashLogInfo(unsigned long Msb, unsigned long Lsb);

    TDateTime Time;
    short int Type;
    short int Proc;
    int Data;
};

class TCrashSelectorInfo
{
public:
    short int Selector;
    int Base;
    int Limit;
    int Valid;
    char InfoText[32];
};
    
class TCrashThreadInfo
{
public:
    short int Selector;
    int Prio;
    int Core;
    int WantedCore;
    char StateText[32];
    char NameText[33];
};
    

class TCrashCoreInfo
{
public:
    TCrashCoreInfo();
    ~TCrashCoreInfo();

    short int Core;    

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

    TCrashSelectorInfo Es;
    TCrashSelectorInfo Cs;
    TCrashSelectorInfo Ss;
    TCrashSelectorInfo Ds;
    TCrashSelectorInfo Fs;
    TCrashSelectorInfo Gs;
    TCrashSelectorInfo Ldt;
    TCrashSelectorInfo Tr;

    TCrashSelectorInfo Gdt;
    TCrashSelectorInfo Idt;

    int StackSize;
    char *StackData;

    int ThreadCount;
    TCrashThreadInfo *ThreadArr[MAX_CRASH_INFO_THREADS];

    int LogCount;
    TCrashLogInfo *LogArr[MAX_CRASH_INFO_LOGS];
};

class TCrashInfo
{
public:
    TCrashInfo();
    virtual ~TCrashInfo();

    TCrashCoreInfo *CrashInfo[MAX_CRASH_INFO_CORES];

private:
    void GetCrashInfo(int Core);
};

#endif

