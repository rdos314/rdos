/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

    int Core;
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
    short int Nesting;

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

    int LogCount;
    TCrashLogInfo *LogArr[MAX_CRASH_INFO_CORES * MAX_CRASH_INFO_LOGS];

private:
    void GetCrashInfo(int Core);
    void InsertLog(TCrashLogInfo *log);
};

#endif

