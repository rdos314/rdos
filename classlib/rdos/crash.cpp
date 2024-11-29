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

struct TRdosLog
{
    unsigned long LsbTime;
    unsigned long MsbTime;
    short int Type;
    short int Proc;
    int Data;
};

struct TRdosSelector
{
    short int Sel;
    short int Flags;
    int Base;
    int Limit;
};

struct TRdosThread
{
    short int Sel;
    short int Prio;
    short int State;
    short int Core;
    short int WantedCore;
    char Name[32];
};

struct TRdosCrashCore
{
    char Filler[10];

    short int Core;
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

    short int Nesting;

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

    short int ThreadCount;

    struct TRdosThread ThreadArr[50];
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
#   Name       : DecodeDt
#
#   Purpose....: Decode descriptor table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void DecodeDt(TCrashSelectorInfo *info, struct TRdosSelector *raw)
{
    info->InfoText[0] = 0;
    info->Selector = 0;
    info->Base = raw->Base;
    info->Limit = raw->Limit;
    info->Valid = TRUE;
}

/*##########################################################################
#
#   Name       : DecodeCrashThread
#
#   Purpose....: Decode crash thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void DecodeCrashThread(short int Core, TCrashThreadInfo *info, struct TRdosThread *raw)
{
    switch (raw->State)
    {
        case 1:
            strcpy(info->StateText, "Running");
            break;

        case 2:
            strcpy(info->StateText, "Wakeup");
            break;

        case 3:
            strcpy(info->StateText, "Ready");
            break;

        default:
            strcpy(info->StateText, "Unknown");
            break;
    }

    info->Selector = raw->Sel;
    info->Prio = raw->Prio;

    if (Core != raw->Core)
        info->Core = raw->Core;
    else
        info->Core = 0;

    if (Core != raw->WantedCore)
        info->WantedCore = raw->WantedCore;
    else
        info->WantedCore = 0;
            
    strncpy(info->NameText, raw->Name, 32);
    info->NameText[32] = 0;
}

/*##########################################################################
#
#   Name       : TCrashCoreInfo::TCrashLogInfo
#
#   Purpose....: Constructor for TCrashLogInfo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrashLogInfo::TCrashLogInfo(unsigned long Msb, unsigned long Lsb)
  : Time(Msb, Lsb)
{
    Type = 0;
    Proc = 0;
    Data = 0;
}

/*##########################################################################
#
#   Name       : TCrashCoreInfo::TCrashCoreInfo
#
#   Purpose....: Constructor for TCrashCoreInfo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrashCoreInfo::TCrashCoreInfo()
{
    int i;

    StackData = 0;

    for (i = 0; i < MAX_CRASH_INFO_THREADS; i++)
        ThreadArr[i] = 0;

    for (i = 0; i < MAX_CRASH_INFO_LOGS; i++)
        LogArr[i] = 0;
}

/*##########################################################################
#
#   Name       : TCrashCoreInfo::~TCrashCoreInfo
#
#   Purpose....: Destructor for TCrashCoreInfo
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrashCoreInfo::~TCrashCoreInfo()
{
    int i;

    if (StackData)
        delete StackData;
        
    for (i = 0; i < MAX_CRASH_INFO_THREADS; i++)
        if (ThreadArr[i])
            delete ThreadArr[i];
        
    for (i = 0; i < MAX_CRASH_INFO_LOGS; i++)
        if (LogArr[i])
            delete LogArr[i];
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

    LogCount = 0;

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
    TCrashThreadInfo *thread;
    struct TRdosLog *rawlog;
    TCrashLogInfo *log;
    int i;
    char *ptr;

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

        info->Nesting = raw->Nesting;

        DecodeCrashSelector(&info->Es, &raw->Es);
        DecodeCrashSelector(&info->Cs, &raw->Cs);
        DecodeCrashSelector(&info->Ss, &raw->Ss);
        DecodeCrashSelector(&info->Ds, &raw->Ds);
        DecodeCrashSelector(&info->Fs, &raw->Fs);
        DecodeCrashSelector(&info->Gs, &raw->Gs);

        DecodeCrashSelector(&info->Ldt, &raw->Ldt);
        DecodeCrashSelector(&info->Tr, &raw->Tr);

        DecodeDt(&info->Gdt, &raw->Gdtr);
        DecodeDt(&info->Idt, &raw->Idtr);

        info->Core = raw->Core;
        
        info->ThreadCount = raw->ThreadCount;
        if (info->ThreadCount > MAX_CRASH_INFO_THREADS)
            info->ThreadCount = MAX_CRASH_INFO_THREADS;

        for (i = 0; i < info->ThreadCount; i++)
        {
            thread = new TCrashThreadInfo;
            info->ThreadArr[i] = thread;            
            DecodeCrashThread(info->Core, thread, &raw->ThreadArr[i]);
        }

        info->LogCount = 0;
        for (i = 0; i < MAX_CRASH_INFO_LOGS; i++)
        {
            ptr = &CrashBuf[0x2000 + 16 * i];
            rawlog = (struct TRdosLog *)ptr;

            if (rawlog->Type)
            {   
                log = new TCrashLogInfo(rawlog->MsbTime, rawlog->LsbTime);
                log->Core = Core;
                log->Type = rawlog->Type;
                log->Proc = rawlog->Proc;
                log->Data = rawlog->Data;
                info->LogArr[info->LogCount] = log;            
                info->LogCount++;

                InsertLog(log);
            }
        }

        if (info->Ss.Limit == 0xFFF)
            info->StackSize = 0x1000 - (int)info->Rsp;
        else
            info->StackSize = 0;

        if (info->StackSize > 0)
        {
            info->StackData = new char[info->StackSize];
            ptr = &CrashBuf[0x1000];
            ptr += 0x1000 - info->StackSize;
            memcpy(info->StackData, ptr, info->StackSize);
        }
        
        CrashInfo[Core] = info;
    }    
}

/*##########################################################################
#
#   Name       : TCrashInfo::InsertLog
#
#   Purpose....: Insert log into sorted list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCrashInfo::InsertLog(TCrashLogInfo *log)
{
    int pos;
    int i;

    for (pos = 0; pos < LogCount; pos++)
        if (LogArr[pos]->Time > log->Time)
            break;

    for (i = LogCount; i >= pos; i--)
        LogArr[i + 1] = LogArr[i];

    LogArr[pos] = log;    
    LogCount++;
}
