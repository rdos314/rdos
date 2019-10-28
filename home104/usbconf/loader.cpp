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

TRdosLog *Log;

/*##################  OnMsg  #####################################
*   Purpose....: Debug message                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void OnMsg(TWdSocketServerFactory *fact, const char *msg)
{
    Log->Log(0, "Debugger", msg);
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
    Log->Log(0, "Ftpd", str);
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

/*##################  AddFaultState  #####################################
*   Purpose....: Add fault state info to string                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddFaultState(TString &fstr, ThreadActionState *state)
{
    char str[128];
        
    sprintf(str, "Thread %04hX:", state->ID);
    fstr += str;

    strncpy(str, state->Name, 32);
    str[31] = 0;

    fstr += str;
    fstr += "\r\n";
}

/*##################  AddFaultTss  #####################################
*   Purpose....: Add fault TSS info to file                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddFaultTss(TString &fstr, Tss *tss)
{
    TString str;
    
    str.printf("CS:EIP = %04hX:%08lX\r\n", tss->cs, tss->eip);
    fstr += str;
    
    str.printf("SS:ESP = %04hX:%08lX\r\n", tss->ss, tss->esp);    
    fstr += str;

    str.printf("EAX = %08lX ", tss->eax);    
    fstr += str;

    str.printf("EBX = %08lX ", tss->ebx);    
    fstr += str;

    str.printf("ECX = %08lX ", tss->ecx);    
    fstr += str;

    str.printf("EDX = %08lX\r\n", tss->edx);    
    fstr += str;

    str.printf("ESI = %08lX ", tss->esi);    
    fstr += str;

    str.printf("EDI = %08lX ", tss->edi);    
    fstr += str;

    str.printf("EBP = %08lX ", tss->ebp);    
    fstr += str;

    str.printf("EFL = %08lX\r\n", tss->eflags);        
    fstr += str;

    str.printf("DS = %04hX ", tss->ds);    
    fstr += str;

    str.printf("ES = %04hX ", tss->es);    
    fstr += str;

    str.printf("FS = %04hX ", tss->fs);    
    fstr += str;

    str.printf("GS = %04hX\r\n", tss->gs);    
    fstr += str;
}

/*##################  AddFaultCallStack  #####################################
*   Purpose....: Add fault call stack                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddFaultCallStack(TString &fstr, ThreadActionState *state)
{
    int i;
    TString str;

    if (state->UserCount)
    {
        fstr += "Calls:";

        for (i = 0; i < state->UserCount; i++)
        {
            fstr += " ";
            if (state->UserCall[i].Sel != 0x1B3)
            {
                str.printf("%04hX:", state->UserCall[i].Sel);
                fstr += str;
            }

            str.printf("%08lX", state->UserCall[i].Offset);
            fstr += str;
        }
        fstr += "\r\n";
    }
    fstr += "\r\n";
}

/*##################  AddCoreSelector  #####################################
*   Purpose....: Add core selector                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCoreSelector(TString &fstr, const char *Name, TCrashSelectorInfo *info)
{
    TString str;

    fstr += Name;
    fstr += "=";

    str.printf("%04hX", info->Selector);    
    fstr += str;

    if (info->Valid)
    {    
        str.printf(" %08lX (%08lX) ", info->Base, info->Limit);    
        fstr += str;
        fstr += info->InfoText;
    }
    fstr += "\r\n";
}

/*##################  AddCoreDt  #####################################
*   Purpose....: Add core descriptor table                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCoreDt(TString &fstr, const char *Name, TCrashSelectorInfo *info)
{
    TString str;

    fstr += Name;
    fstr += "=";

    str.printf("%08lX (%08lX)\r\n", info->Base, info->Limit);    
    fstr += str;
}

/*##################  AddCoreFlags  #####################################
*   Purpose....: Add core flags                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCoreFlags(TString &fstr, long long flags)
{
    int iopl = (((int)flags) >> 12) & 0x3;
    TString str;
     
    if (flags & 0x1)
        fstr += "CY ";
    else
        fstr += "NC ";

    if (flags & 0x40)
        fstr += "ZR ";
    else
        fstr += "NZ ";

    if (flags & 0x200)
        fstr += "EI ";
    else
        fstr += "DI ";

    if (flags & 0x4000)
        fstr += "NT ";
     else
        fstr += "PR ";

    if (flags & 0x20000)
        fstr += "VM ";
    else
        fstr += "PM ";

    str.printf("IOPL=%d\r\n", iopl);
    fstr += str;
}

/*##################  AddCoreThread  #####################################
*   Purpose....: Add core thread                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCoreThread(TString &fstr, TCrashThreadInfo *info)
{
    TString str;

    str.printf("%04hX ", info->Selector);    
    fstr += str;

    str.printf("PRIO=%d ", info->Prio);    
    fstr += str;

    if (info->Core)
    {
        str.printf("CORE=%d ", info->Core);    
        fstr += str;
    }

    if (info->WantedCore)
    {
        str.printf("WCORE=%d ", info->WantedCore);    
        fstr += str;
    }

    fstr += info->NameText;
    fstr += " ";
    fstr += info->StateText;
    fstr += "\r\n";
}

/*##################  AddCoreStack  #####################################
*   Purpose....: Add core stack                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCoreStack(TString &fstr, char *data, int sel, int base, int size)
{
    int ads;
    char *ptr;
    int i;
    short int sval;
    TString str;
    
    while (size >= 16)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        str.printf("%04hX:%04hX ", sel, ads);
        fstr += str;

        for (i = 0; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            str.printf("%04hX", sval);
            fstr += str;

            if (i == 7)
                fstr += "\r\n";
            else
                fstr += " ";
        }
        size -= 16;                
    }

    if (size)
    {
        ads = base + size - 16;
        ptr = data + size - 16;

        str.printf("%04hX:%04hX ", sel, ads);
        fstr += str;

        size = size / 2;
    
        for (i = 0; i < 8 - size; i++)
            fstr += "     ";

        for (i = 8 - size; i < 8; i++)
        {
            sval = *((short int *)(ptr + 2 * i));
            str.printf("%04hX", sval);
            fstr += str;

            if (i == 7)
                fstr += "\r\n";
            else
                fstr += " ";
        }        
    }
}

/*##################  AddCore  #####################################
*   Purpose....: Add core fault                                                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void AddCore(TString &fstr, int core, TCrashCoreInfo *info)
{
    int i;
    TString str;

    str.printf("Core=%d (%04hX)\r\n", core, info->Core);
    fstr += str;
    
    str.printf("CS:EIP=%04hX:%08lX\r\n", info->Cs.Selector, (int)info->Rip);
    fstr += str;
    
    str.printf("SS:ESP=%04hX:%08lX\r\n", info->Ss.Selector, (int)info->Rsp); 
    fstr += str;

    str.printf("EAX=%08lX ", (int)info->Rax);    
    fstr += str;

    str.printf("EBX=%08lX ", (int)info->Rbx);    
    fstr += str;

    str.printf("ECX=%08lX ", (int)info->Rcx);    
    fstr += str;

    str.printf("EDX=%08lX\r\n", (int)info->Rdx);    
    fstr += str;

    str.printf("ESI=%08lX ", (int)info->Rsi);    
    fstr += str;

    str.printf("EDI=%08lX ", (int)info->Rdi);    
    fstr += str;

    str.printf("EBP=%08lX\r\n", (int)info->Rbp);    
    fstr += str;

    AddCoreFlags(fstr, info->Rflags);

    AddCoreSelector(fstr, "CS", &info->Cs);
    AddCoreSelector(fstr, "DS", &info->Ds);
    AddCoreSelector(fstr, "ES", &info->Es);
    AddCoreSelector(fstr, "FS", &info->Fs);
    AddCoreSelector(fstr, "GS", &info->Gs);
    AddCoreSelector(fstr, "SS", &info->Ss);
    AddCoreSelector(fstr, "LDT", &info->Ldt);
    AddCoreDt(fstr, "GDT", &info->Gdt);
    AddCoreDt(fstr, "IDT", &info->Idt);

    str.printf("CR0=%08lX ", info->Cr0);    
    fstr += str;

    str.printf("CR2=%08lX ", info->Cr2);    
    fstr += str;

    str.printf("CR3=%08lX ", info->Cr3);    
    fstr += str;

    str.printf("CR4=%08lX\r\n", info->Cr4);    
    fstr += str;

    str.printf("NEST=%d\r\n", (int)info->Nesting);    
    fstr += str;

    AddCoreSelector(fstr, "TR", &info->Tr);

    for (i = 0; i < info->ThreadCount; i++)
        AddCoreThread(fstr, info->ThreadArr[i]);

    if (info->StackData)
        AddCoreStack(fstr, info->StackData, info->Ss.Selector, (int)info->Rsp, info->StackSize);

    fstr += "\r\n";
}

/*##################  LogFault  #####################################
*   Purpose....: Log fault                                                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void LogFault()
{
    int i;    
    TFile File("d:/heat/error.txt");
    int size;
    TString FaultStr;

    if (RdosHasCrashInfo())
    {
        TCrashInfo info;
        int core;

        for (core = 0; core < MAX_CRASH_INFO_CORES; core++)
        {
            if (info.CrashInfo[core])
                AddCore(FaultStr, core, info.CrashInfo[core]);
        }

        if (FaultStr.GetSize())
        {
            Log->Log(0, "CoreFault", FaultStr.GetData());
            FaultStr = "";
        }
    }


    for (i = 0; i < FaultThreads; i++)
    {
        AddFaultState(FaultStr, &FaultStateArr[i]);
        AddFaultTss(FaultStr, &FaultTssArr[i]);
        AddFaultCallStack(FaultStr, &FaultStateArr[i]);
    }

    if (FaultStr.GetSize())
    {
        Log->Log(0, "Fault", FaultStr.GetData());
        FaultStr = "";
    }

    size = File.GetSize();

    if (size > 0xFF00)
        size = 0xFF00;

    if (size)
    {
        char *buf = new char[size + 1];
        File.Read(buf, size);
        buf[size] = 0;
        Log->Log(0, "Error", buf);
        delete buf;
    }
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
    printf("Starting loader\r\n");

    RdosWaitMilli(1000);

    Log = new TRdosDefaultLog("d:/log", 200, 0x20000, "Loader Log", "");

    Timeout = 2 * 90 * 60;

    RdosCreateThread(WatchdogThread, "Loader WD", 0, 0x2000);

    SetupFaultSave();
    HandleFaultSave();
    LogFault();

    if (FaultThreads || RdosHasCrashInfo())
        RdosClearFaultSave();

    Timeout = 2 * 60;

    StartApp();

    Timeout = 0;

    for (;;)
        RdosWaitMilli(250);
}
