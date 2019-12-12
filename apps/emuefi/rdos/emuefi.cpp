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
* EMUEFI.CPP
* UEFI simulator 
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include <memory.h>
#include "path.h"
#include "sigdev.h"
#include "cpu.h"
#include "pic.h"
#include "pit.h"
#include "keyb.h"
#include "pci.h"
#include "cmos.h"
#include "flash.h"
#include "ram.h"
#include "pciide.h"
#include "video.h"
#include "dispmsg.h"

struct UefiParam
{
    short int Pad;
    long long LfbBase;
    int Width;
    int Height;
    int LineSize;
    int Flags;
    int MemEntries;
    long long AcpiTable;
};

struct MemMap
{
    int Len;
    long long Base;
    long long Size;
    int Type;
};

struct AcpiRsdp
{
    char Sign[8];
    char CheckSum;
    char OemId[6];
    char Revision;
    unsigned int RsdtAddress;
    int Len;
    long long XsdtAddress;
    char extchksum;
    char Resv[3];
};

struct AcpiDt
{
    char Sign[4];
    int Len;
    char Revision;
    char CheckSum;
    char OemId[6];
    long long OemTableId;
    int OemRev;
    int CreatorId;
    int CreatorRev;
};

struct AcpiXsdt
{
    char Sign[4];
    int Len;
    char Revision;
    char CheckSum;
    char OemId[6];
    long long OemTableId;
    int OemRev;
    int CreatorId;
    int CreatorRev;
    long long EntryArr[2];
};



void OpenScreen(const char *FileName);
void CloseScreen();

#define HIGH_BASE    0x100000
#define ACPI_BASE    0x120000000
#define TABLE_BASE   0x200000000

#define STACK_SIZE  0x4000

#define FALSE 0
#define TRUE !FALSE

TBus Isa;
TPci Pci(&Isa, 0);
TPic Pic0(&Isa, 0x20);
TPit Pit(&Isa, 0x40);
TVideo Video(&Isa);
TKeyb Keyb(&Isa, 0x60, &Pic0, 1);
TRam LowRam(&Isa, 0, 0xA0000);
TRam HighRam(&Isa, HIGH_BASE,  0x700000);
TRam Ram64(&Isa, 0x100000000, 0x100000);
TRam RamAcpi(&Isa, ACPI_BASE, 0x10000);
TRam RamTable(&Isa, TABLE_BASE, 0x10000);
TCpu Cpu;

TSignalDevice RemoteSignal;

int RemoteHandle;
char GlobalReply[0x100];

char MyFocus;
char DispFocus;

/*##################  StartRemote  ###############
*   Purpose....: Start remote                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int StartRemote()
{
    TPathName StartupDir;
    int ThreadId;
    int Handle;
    char env[2] = {0, 0};

    Handle = RdosSpawn("emrem.exe", "", StartupDir.Get().GetData(), 0, &ThreadId);
    if (Handle)
        return TRUE;
    return FALSE;
}

/*##################  GetRemoteIpc  ###############
*   Purpose....: Get remote IPC                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int GetRemoteIpc()
{
    return RdosGetLocalMailslot("emdisp");
//    return RdosGetRemoteMailslot(0x4101A8C0, "emdisp");
//    return RdosGetRemoteMailslot(0xB70AA8C0, "emdisp");
}

/*##################  RemoteThread  ###############
*   Purpose....: Remote thread                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void RemoteThread(void *Param)
{
    int row;
    int size;
    char *msg = new char[0x1000];
    char *reply = new char[0x1000];
    struct TBaseReq *BaseReq = (struct TBaseReq *)msg;
    RemoteHandle = GetRemoteIpc();

    if (!RemoteHandle)
    {
        StartRemote();

        while (!RemoteHandle)
        {
            RdosWaitMilli(100);
            RemoteHandle = GetRemoteIpc();
        }
    }

    BaseReq->MsgType = DISP_MSG_FOCUS;

    size = RdosSendMailslot(RemoteHandle, msg, sizeof(struct TBaseReq), reply, 0x1000); 

    if (size == 1)
        DispFocus = reply[0];

    for (;;)
    {
        RemoteSignal.WaitTimeout(100);

        if (Keyb.IsEnabled())
        {
            BaseReq->MsgType = DISP_MSG_KEY;
            size = RdosSendMailslot(RemoteHandle, msg, sizeof(struct TBaseReq), reply, 0x1000); 
            if (size == 1)
                Keyb.NotifyKey(reply[0]);
        }
    }
}

/*##################  SetInt  ###############
*   Purpose....: Set int line                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void SetInt(TInterrupt *Interrupt, TCpu *Cpu)
{
    Cpu->SetInt(Interrupt);
}

/*##################  ResetInt  ###############
*   Purpose....: Reset int line                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ResetInt(TInterrupt *Interrupt, TCpu *Cpu)
{
    Cpu->ResetInt(Interrupt);
}

/*##################  ExtClk  ###############
*   Purpose....: Clk notification                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ExtClk(TCpu *Cpu)
{
    static int PollDelay = 512;
    
    PollDelay--;

    if (PollDelay == 0)
    {
        PollDelay = 512;

        if (RdosPollKeyboard())
        {
            RdosReadKeyboard();
            Cpu->Break();
        }
    }

    Pit.Counter[0]->ExtClk();
    Pit.Counter[2]->ExtClk();
}

/*##################  VideoDwordChange  ###############
*   Purpose....: Video data changed                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void VideoDwordChange(TBusFunction *BusFunction, unsigned long Offset, long Val)
{
    struct TVgaReq VgaReq;

    VgaReq.MsgType = DISP_MSG_VGA;
    VgaReq.y = Offset / (640 * 4);
    VgaReq.x = (Offset - VgaReq.y * 640 * 4) / 4;
    VgaReq.val = Val;
    RdosSendMailslot(RemoteHandle, &VgaReq, sizeof(struct TVgaReq), GlobalReply, 0x100); 
}

/*##################  Start  ###############
*   Purpose....: Start emulator                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void Start()
{
    TPic Pic1(&Isa, 0xA0);
    Pic0.Cascade(2, &Pic1);
    TCmos Cmos(&Isa, 0x70);
    TFlash Bios(&Isa, 0xFFFF0000, 0x10000);
    TFlash BiosShadow(&Isa, 0xF0000, 0x10000, Bios.GetData());
    struct UefiParam *UefiParam;
    struct MemMap *UefiMemMap;
    struct AcpiRsdp *AcpiRsdp;
    struct AcpiXsdt *AcpiXsdt;
    struct AcpiDt *AcpiDt;
    char *ptr;
    int i;
    char sum;

    TRam Video(&Isa, 0x800000, 0x200000);
    Video.Clear();
    Video.OnDwordChange = VideoDwordChange;

    TFile LoaderFile("boot32.bin");
    HighRam.Load(0x110000 - HIGH_BASE, &LoaderFile);
    TFile RdosFile("rdos.bin");
    HighRam.Load(0x121000 - HIGH_BASE, &RdosFile);

    ptr = HighRam.GetData();
    ptr += 0x110000 - HIGH_BASE;

    UefiParam = (struct UefiParam *)ptr;
    UefiParam->LfbBase = 0x800000;
    UefiParam->Width = 640;
    UefiParam->Height = 480;
    UefiParam->LineSize = 4 * 640;
    UefiParam->Flags = 0;
    UefiParam->MemEntries = 3;
    UefiParam->AcpiTable = ACPI_BASE + 0x120;

    ptr = LowRam.GetData();
    ptr += 0x400;

    UefiMemMap = (struct MemMap *)ptr;
    UefiMemMap->Len = 0x14;
    UefiMemMap->Base = 0x100000;
    UefiMemMap->Size = 0x021000;
    UefiMemMap->Type = 1;

    UefiMemMap++;
    UefiMemMap->Len = 0x14;
    UefiMemMap->Base = 0x004000;
    UefiMemMap->Size = 0x7FC000;
    UefiMemMap->Type = 1;

    UefiMemMap++;
    UefiMemMap->Len = 0x14;
    UefiMemMap->Base = 0x100000000;
    UefiMemMap->Size =  0x100000;
    UefiMemMap->Type = 1;

    ptr = RamAcpi.GetData();
    ptr += 0x120;
    AcpiRsdp = (struct AcpiRsdp *)ptr;

    strcpy(AcpiRsdp->Sign, "RSD PTR ");
    AcpiRsdp->OemId[0] = 0;
    AcpiRsdp->OemId[1] = 0;
    AcpiRsdp->OemId[2] = 0;
    AcpiRsdp->OemId[3] = 0;
    AcpiRsdp->OemId[4] = 0;
    AcpiRsdp->OemId[5] = 0;
    AcpiRsdp->Revision = 2;
    AcpiRsdp->RsdtAddress = 0;
    AcpiRsdp->XsdtAddress = ACPI_BASE + 0x400;
    AcpiRsdp->Len = sizeof(struct AcpiRsdp);

    sum = 0;
    for (i = 0; i < 20; i++)
        sum += ptr[i];
    AcpiRsdp->CheckSum = -sum;

    ptr = RamAcpi.GetData();
    ptr += 0x400;
    AcpiXsdt = (struct AcpiXsdt *)ptr;

    strcpy(AcpiXsdt->Sign, "XSDT");
    AcpiXsdt->Len = sizeof(struct AcpiXsdt);
    AcpiXsdt->Revision = 1;
    AcpiXsdt->CheckSum = 0;
    AcpiXsdt->OemId[0] = 0;
    AcpiXsdt->OemId[1] = 0;
    AcpiXsdt->OemId[2] = 0;
    AcpiXsdt->OemId[3] = 0;
    AcpiXsdt->OemId[4] = 0;
    AcpiXsdt->OemId[5] = 0;
    AcpiXsdt->OemTableId = 1;
    AcpiXsdt->OemRev = 1;
    AcpiXsdt->CreatorId = 1;
    AcpiXsdt->CreatorRev = 1;
    AcpiXsdt->EntryArr[0] = TABLE_BASE + 0xC00;
    AcpiXsdt->EntryArr[1] = TABLE_BASE + 0x1400;

    sum = 0;
    for (i = 0; i < AcpiXsdt->Len; i++)
        sum += ptr[i];
    AcpiXsdt->CheckSum = -sum;

    ptr = RamTable.GetData() + 0xC00;
    AcpiDt = (struct AcpiDt *)ptr;

    strcpy(AcpiDt->Sign, "XYZ0");
    AcpiDt->Len = sizeof(struct AcpiDt) + 1;
    AcpiDt->Revision = 1;
    AcpiDt->CheckSum = 0;
    AcpiDt->OemId[0] = 0;
    AcpiDt->OemId[1] = 0;
    AcpiDt->OemId[2] = 0;
    AcpiDt->OemId[3] = 0;
    AcpiDt->OemId[4] = 0;
    AcpiDt->OemId[5] = 0;
    AcpiDt->OemTableId = 1;
    AcpiDt->OemRev = 1;
    AcpiDt->CreatorId = 1;
    AcpiDt->CreatorRev = 1;

    sum = 0;
    for (i = 0; i < AcpiDt->Len; i++)
        sum += ptr[i];
    AcpiDt->CheckSum = -sum;


    ptr = RamTable.GetData() + 0x1400;
    AcpiDt = (struct AcpiDt *)ptr;

    strcpy(AcpiDt->Sign, "XYZ1");
    AcpiDt->Len = sizeof(struct AcpiDt) + 1;
    AcpiDt->Revision = 1;
    AcpiDt->CheckSum = 0;
    AcpiDt->OemId[0] = 0;
    AcpiDt->OemId[1] = 0;
    AcpiDt->OemId[2] = 0;
    AcpiDt->OemId[3] = 0;
    AcpiDt->OemId[4] = 0;
    AcpiDt->OemId[5] = 0;
    AcpiDt->OemTableId = 1;
    AcpiDt->OemRev = 1;
    AcpiDt->CreatorId = 1;
    AcpiDt->CreatorRev = 1;

    sum = 0;
    for (i = 0; i < AcpiDt->Len; i++)
        sum += ptr[i];
    AcpiDt->CheckSum = -sum;


    int sel;
    int offset;
    int count;

    int Key;

    RdosCreateThread(RemoteThread, "empc remote", 0, 0x4000);

    Cpu.DefineBus(&Isa);
    Cpu.OnExtClk = ExtClk;
    Cpu.Reset();

    Pit.Counter[0]->Define(&Pic0, 0);
    
    Pic0.DefineCpu(&Cpu);
    Pic0.OnSet = SetInt;
    Pic0.OnReset = ResetInt;

    Cpu.CpuState.Reg_eip = 0x110000;
//    Cpu.CpuState.Reg_efer = EFER_LME;
    Cpu.CpuState.Reg_cs.base = 0;
    Cpu.CpuState.Reg_cs.limit = 0xFFFFFFFF;
//    Cpu.CpuState.Reg_cs.access = ACCESS_64 | ACCESS_READ;
    Cpu.CpuState.Reg_cs.access = ACCESS_32 | ACCESS_READ;
    Cpu.CpuState.Reg_cr0 = 1;
    Cpu.CpuState.Reg_esp = 0x120000;

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

            case 'd':
            case 'D':
                count = scanf("%X:%X", &sel, &offset);
                if (count == 2)
                {
                    for (;;)
                    {
                        Cpu.ShowData(sel, offset);
                        Key = RdosReadKeyboard() & 0xFF;
                        if (Key == 0xd)
                            offset += 0x10;
                        else
                            break;
                    }
                }
                break;

        }
    }
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
    Start();
}
