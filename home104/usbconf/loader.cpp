/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# loader.cpp
# Loader for heat.
#
########################################################################*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <process.h>
#include <unistd.h>
#include <fcntl.h>
#include "rdos.h"
#include "disc.h"
#include "part.h"
#include "fatpart.h"
#include "gptpart.h"
#include "strlist.h"
#include "direntry.h"
#include "rdosimg.h"
#include "rdoslog.h"
#include "crash.h"
#include "ftpfact.h"
#include "sockobj.h"

#include "wdfact.h"
#include "wdfile.h"
#include "wdfinfo.h"
#include "wdenv.h"
#include "wdrtrd.h"
#include "wdcap.h"
#include "wdasync.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_FAULT_THREADS   128

int FaultThreads;
ThreadActionState FaultStateArr[MAX_FAULT_THREADS];
Tss FaultTssArr[MAX_FAULT_THREADS];

long Timeout = 0;

int IsLoading = FALSE;

/*##################  OnMsg  #####################################
*   Purpose....: Debug message                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void OnMsg(TWdSocketServerFactory *fact, const char *msg)
{
//    Log.Write(TLog::INFO, "Debugger", msg);
}

/*##################  WriteCommand ##########################
*   Purpose....: Write command echo                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCommand(TFtpSocketServer *server, const char *str)
{
//    printf(str);
}

/*##################  SetupFaultSave  #####################################
*   Purpose....: Setup fault save                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void SetupFaultSave()
{
    int DiscNr;
    TDisc *Disc;
    TIdeDiscPartition *DiscPart;
    TGptDiscPartition *GptDisc;
    TPartition *Part;
    int PartNr;
    long StartSector;
    long long Sectors;
    int SectorSize;
    int BiosSectorsPerCyl;
    int BiosHeads;

    for (DiscNr = 0; DiscNr < 25; DiscNr++)
    {
        if (RdosGetDiscInfo(DiscNr, &SectorSize, &Sectors, &BiosSectorsPerCyl, &BiosHeads))
        {
            Disc = new TDisc(DiscNr);

            if (Disc->IsGpt())
            {
                GptDisc = new TGptDiscPartition(Disc);
                GptDisc->Read();
                StartSector = GptDisc->GetEnd() - 128;
                Sectors = 128;
                RdosDefineFaultSave(Disc->GetDiscNr(), StartSector, Sectors);
            }
            delete Disc;
            break;
        }
    }    
}

/*##################  HandleFaultSave  #####################################
*   Purpose....: Handle fault save                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleFaultSave()
{
    int ok;

    FaultThreads = 0;

    for (;;)
    {
        ok = RdosGetFaultThreadState(FaultThreads, &FaultStateArr[FaultThreads]);
        if (ok)
            ok = RdosGetFaultThreadTss(FaultThreads, &FaultTssArr[FaultThreads]);

        if (ok)
            FaultThreads++;
        else
            break;        
    }
}

/*##################  WriteFaultState  #####################################
*   Purpose....: Write fault state info to file                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteFaultState(TFile &file, ThreadActionState *state)
{
    char str[128];
        
    sprintf(str, "Thread %04hX:", state->ID);
    file.Write(str);    

    strncpy(str, state->Name, 32);
    str[31] = 0;
    file.Write(str);    

    file.Write("\r\n");
}

/*##################  WriteFaultTss  #####################################
*   Purpose....: Write fault TSS info to file                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteFaultTss(TFile &file, Tss *tss)
{
    char str[128];
    
    sprintf(str, "CS:EIP = %04hX:%08lX\r\n", tss->cs, tss->eip);
    file.Write(str);
    
    sprintf(str, "SS:ESP = %04hX:%08lX\r\n", tss->ss, tss->esp);    
    file.Write(str);


    sprintf(str,"EAX = %08lX ", tss->eax);    
    file.Write(str);

    sprintf(str, "EBX = %08lX ", tss->ebx);    
    file.Write(str);

    sprintf(str, "ECX = %08lX ", tss->ecx);    
    file.Write(str);

    sprintf(str, "EDX = %08lX\r\n", tss->edx);    
    file.Write(str);


    sprintf(str, "ESI = %08lX ", tss->esi);    
    file.Write(str);

    sprintf(str, "EDI = %08lX ", tss->edi);    
    file.Write(str);

    sprintf(str, "EBP = %08lX ", tss->ebp);    
    file.Write(str);

    sprintf(str, "EFL = %08lX\r\n", tss->eflags);        
    file.Write(str);


    sprintf(str, "DS = %04hX ", tss->ds);    
    file.Write(str);

    sprintf(str, "ES = %04hX ", tss->es);    
    file.Write(str);

    sprintf(str, "FS = %04hX ", tss->fs);    
    file.Write(str);

    sprintf(str, "GS = %04hX\r\n", tss->gs);    
    file.Write(str);
}

/*##################  WriteFaultCallStack  #####################################
*   Purpose....: Write fault call stack                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteFaultCallStack(TFile &file, ThreadActionState *state)
{
    int i;
    char str[128];

    if (state->UserCount)
    {
        file.Write("Calls:");

        for (i = 0; i < state->UserCount; i++)
        {
            file.Write(" ");
            if (state->UserCall[i].Sel != 0x1B3)
            {
                sprintf(str, "%04hX:", state->UserCall[i].Sel);
                file.Write(str);
            }

            sprintf(str, "%08lX", state->UserCall[i].Offset);
            file.Write(str);
        }
        file.Write("\r\n");
    }
    file.Write("\r\n");
}

/*##################  WriteSelector  #####################################
*   Purpose....: Write core selector                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteSelector(TFile &file, const char *Name, TCrashSelectorInfo *info)
{
    char str[81];

    file.Write(Name);
    file.Write("=");

    sprintf(str,"%04hX", info->Selector);    
    file.Write(str);

    if (info->Valid)
    {    
        sprintf(str," %08lX (%08lX) ", info->Base, info->Limit);    
        file.Write(str);

        file.Write(info->InfoText);
    }
    file.Write("\r\n");
}

/*##################  WriteDt  #####################################
*   Purpose....: Write core descriptor table                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteDt(TFile &file, const char *Name, TCrashSelectorInfo *info)
{
    char str[81];

    file.Write(Name);
    file.Write("=");

    sprintf(str,"%08lX (%08lX)\r\n", info->Base, info->Limit);    
    file.Write(str);
}

/*##################  WriteFlags  #####################################
*   Purpose....: Write core flags                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteFlags(TFile &file, long long flags)
{
    int iopl = (((int)flags) >> 12) & 0x3;
    char str[10];
     
    if (flags & 0x1)
        file.Write("CY ");
    else
        file.Write("NC ");

    if (flags & 0x40)
        file.Write("ZR ");
    else
        file.Write("NZ ");

    if (flags & 0x200)
        file.Write("EI ");
    else
        file.Write("DI ");

    if (flags & 0x4000)
        file.Write("NT ");
     else
        file.Write("PR ");

    if (flags & 0x20000)
        file.Write("VM ");
    else
        file.Write("PM ");

    sprintf(str, "IOPL=%d\r\n", iopl);
    file.Write(str);
}

/*##################  WriteThread  #####################################
*   Purpose....: Write core thread                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteThread(TFile &file, TCrashThreadInfo *info)
{
    char str[81];

    sprintf(str,"%04hX ", info->Selector);    
    file.Write(str);

    sprintf(str,"PRIO=%d ", info->Prio);    
    file.Write(str);

    if (info->Core)
    {
        sprintf(str,"CORE=%d ", info->Core);    
        file.Write(str);
    }

    if (info->WantedCore)
    {
        sprintf(str,"WCORE=%d ", info->WantedCore);    
        file.Write(str);
    }

    file.Write(info->NameText);
    file.Write(" ");
    file.Write(info->StateText);
    file.Write("\r\n");
}

/*##################  WriteStack  #####################################
*   Purpose....: Write core stack                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteStack(TFile &file, char *data, int sel, int base, int size)
{
    int ads;
    char *ptr;
    char str[10];
    int i;
    short int sval;
    
    while (size >= 16)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        sprintf(str,"%04hX:%04hX ", sel, ads);
        file.Write(str);

        for (i = 0; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            sprintf(str,"%04hX", sval);
            file.Write(str);

            if (i == 7)
                file.Write("\r\n");
            else
                file.Write(" ");
        }
        size -= 16;                
    }

    if (size)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        sprintf(str,"%04hX:%04hX ", sel, ads);
        file.Write(str);

        size = size / 2;
    
        for (i = 0; i < 8 - size; i++)
            file.Write("     ");

        for (i = 8 - size; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            sprintf(str,"%04hX", sval);
            file.Write(str);

            if (i == 7)
                file.Write("\r\n");
            else
                file.Write(" ");
        }        
    }
}

/*##################  WriteCore  #####################################
*   Purpose....: Write core fault                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteCore(TFile &file, int core, TCrashCoreInfo *info)
{
    int i;
    char str[81];

    sprintf(str, "Core=%d (%04hX)\r\n", core, info->Core);
    file.Write(str);
    
    sprintf(str, "CS:EIP=%04hX:%08lX\r\n", info->Cs.Selector, (int)info->Rip);
    file.Write(str);
    
    sprintf(str, "SS:ESP=%04hX:%08lX\r\n", info->Ss.Selector, (int)info->Rsp); 
    file.Write(str);

    sprintf(str,"EAX=%08lX ", (int)info->Rax);    
    file.Write(str);

    sprintf(str, "EBX=%08lX ", (int)info->Rbx);    
    file.Write(str);

    sprintf(str, "ECX=%08lX ", (int)info->Rcx);    
    file.Write(str);

    sprintf(str, "EDX=%08lX\r\n", (int)info->Rdx);    
    file.Write(str);

    sprintf(str, "ESI=%08lX ", (int)info->Rsi);    
    file.Write(str);

    sprintf(str, "EDI=%08lX ", (int)info->Rdi);    
    file.Write(str);

    sprintf(str, "EBP=%08lX\r\n", (int)info->Rbp);    
    file.Write(str);

    WriteFlags(file, info->Rflags);

    WriteSelector(file, "CS", &info->Cs);
    WriteSelector(file, "DS", &info->Ds);
    WriteSelector(file, "ES", &info->Es);
    WriteSelector(file, "FS", &info->Fs);
    WriteSelector(file, "GS", &info->Gs);
    WriteSelector(file, "SS", &info->Ss);
    WriteSelector(file, "LDT", &info->Ldt);
    WriteDt(file, "GDT", &info->Gdt);
    WriteDt(file, "IDT", &info->Idt);

    sprintf(str, "CR0=%08lX ", info->Cr0);    
    file.Write(str);

    sprintf(str, "CR2=%08lX ", info->Cr2);    
    file.Write(str);

    sprintf(str, "CR3=%08lX ", info->Cr3);    
    file.Write(str);

    sprintf(str, "CR4=%08lX\r\n", info->Cr4);    
    file.Write(str);

    sprintf(str, "NEST=%d\r\n", (int)info->Nesting);    
    file.Write(str);

    WriteSelector(file, "TR", &info->Tr);

    for (i = 0; i < info->ThreadCount; i++)
        WriteThread(file, info->ThreadArr[i]);

    if (info->StackData)
        WriteStack(file, info->StackData, info->Ss.Selector, (int)info->Rsp, info->StackSize);

    file.Write("\r\n");
}

/*##################  CreateFaultFile  #####################################
*   Purpose....: Create fault file                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void CreateFaultFile()
{
    int i;    
    TFile File("d:\\boot\\temp.dat", 0);

    if (RdosHasCrashInfo())
    {
        TCrashInfo info;
        int core;

        for (core = 0; core < MAX_CRASH_INFO_CORES; core++)
        {
            if (info.CrashInfo[core])
                WriteCore(File, core, info.CrashInfo[core]);
        }
    }

    for (i = 0; i < FaultThreads; i++)
    {
        WriteFaultState(File, &FaultStateArr[i]);
        WriteFaultTss(File, &FaultTssArr[i]);
        WriteFaultCallStack(File, &FaultStateArr[i]);
    }
}

/*##################  GetRuntimeError  #####################################
*   Purpose....: Get for runtime error text                                                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TString GetRuntimeError()
{
    char *str;
    int size;
    TFile File("d:/heat/error.txt");

    size = File.GetSize();

    if (size > 0xFF00)
        size = 0xFF00;

    str = new char[size + 1];
    File.Read(str, size);
    str[size] = 0;

    return TString(str);
}

/*##################  WatchdogThread  ##############################################
 *   Purpose....: Watchdog thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void WatchdogThread(void *ptr)
{    
    int kick;
    
    RdosStartWatchdog(5000);

    for (;;)
    {
        if (Timeout)
        {
            if (Timeout > 1)
            {
                Timeout--;
                kick = TRUE;
            }
            else
                kick = FALSE;
        }
        else
            kick = TRUE;

        if (kick)
            RdosKickWatchdog();

        RdosWaitMilli(500);
    }
}

/*##################  DebuggerThread  ##############################################
 *   Purpose....: Debugger thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void DebuggerThread(void *ptr)
{    
    TWdSupplFactory *suppl;
    TWdSocketServerFactory fact(0xDEB, 16, 0x7000);

    fact.OnMsg = OnMsg;

    suppl = new TWdFileFactory(&fact);
    suppl = new TWdFileInfoFactory(&fact);
    suppl = new TWdEnvFactory(&fact);
    suppl = new TWdRunThreadFactory(&fact);
    suppl = new TWdCapFactory(&fact);
    suppl = new TWdAsyncFactory(&fact);

    for (;;)
        fact.WaitForever();
}

/*##################  FtpThread  ##############################################
 *   Purpose....: Ftp thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void FtpThread(void *ptr)
{    
    TFtpSocketServerFactory Factory(21, 50, 0x4000);

    Factory.AddUser("b-drive", "rdos", "b:\\");
    Factory.AddUser("c-drive", "rdos", "c:\\");
    Factory.AddUser("d-drive", "rdos", "d:\\");
    Factory.AddUser("e-drive", "rdos", "e:\\");
    Factory.AddUser("f-drive", "rdos", "f:\\");
    Factory.AddUser("g-drive", "rdos", "g:\\");
    Factory.AddUser("h-drive", "rdos", "h\\");
    Factory.AddUser("i-drive", "rdos", "i:\\");
    Factory.AddUser("j-drive", "rdos", "j:\\");
    Factory.AddUser("k-drive", "rdos", "k:\\");
    Factory.AddUser("l-drive", "rdos", "l:\\");
    Factory.AddUser("m-drive", "rdos", "m:\\");
    Factory.AddUser("n-drive", "rdos", "n:\\");
    Factory.AddUser("x-drive", "rdos", "x:\\");
    Factory.AddUser("y-drive", "rdos", "y:\\");
    Factory.AddUser("z-drive", "rdos", "z:\\");
    Factory.OnCommand = WriteCommand;
    Factory.SetDataPort(2100);

    for (;;)
        Factory.WaitForever();
}

/*##################  StartApp  #####################################
*   Purpose....: Start application program                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void StartApp()
{
    int PrevOutput;
    int PrevError;
    int handle;
    int AppHandle;

    RdosSetCurDir("d:/heat");
    RdosCreateThread(DebuggerThread, "Debug server", 0, 0x2000);
    RdosCreateThread(FtpThread, "Ftp server", 0, 0x2000);

    PrevOutput = dup(1);
    PrevError = dup(2);

    handle = open("d:/heat/output.txt", O_CREAT | O_WRONLY | O_TRUNC);
    if (handle >= 0)
    {
        dup2(handle, 1);
        close(handle);
    }

    handle = open("d:/heat/error.txt", O_CREAT | O_WRONLY | O_TRUNC);
    if (handle >= 0)
    {
        dup2(handle, 2);
        close(handle);
    }

    AppHandle = spawnl(P_NOWAIT, "d:/heat", "heat.exe", 0);

    dup2(PrevOutput, 1);
    dup2(PrevError, 2);
}

/*##################  main  #####################################
*   Purpose....: program startup                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int main()
{
    TString FaultText;

    printf("Starting loader\r\n");

    RdosWaitMilli(1000);

    Timeout = 2 * 90 * 60;

    RdosCreateThread(WatchdogThread, "Loader WD", 0, 0x2000);

    SetupFaultSave();
    HandleFaultSave();

    if (FaultThreads || RdosHasCrashInfo())
        CreateFaultFile();

    FaultText = GetRuntimeError();

    if (FaultThreads || RdosHasCrashInfo() || FaultText.GetSize())
        RdosClearFaultSave();

    Timeout = 2 * 60;

    StartApp();

    Timeout = 0;

    for (;;)
        RdosWaitMilli(250);
}
