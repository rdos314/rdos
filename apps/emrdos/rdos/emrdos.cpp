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
* SIM.CPP
* Main simulator
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
#include "rdosimg.h"

#pragma pack( push, 1 )

typedef struct TRomAdapter
{
    int Base;
    int Size;
    short int Crc;
    short int Pad;
} TRomAdapter;

typedef struct TSystemData
{
    int pad1;
    short int MapSize;
    int Feature;
    int LongIdt;
    int MapBase;
    int LongBase;
    int LongSize;
    short int DebugList;
    short int ThreadArr[256];
    short int NextPid;
    short int RomShadow;
    int Ram1Size;
    int Ram2Base;
    int Ram2Size;
    int Rom1Base;
    int Rom1Size;
    int Rom2Base;
    int Rom2Size;
    int AllocBase;   
    short int RomModules;
    TRomAdapter RomAdapters[16];
} TSystemData;

typedef struct TMemMap
{
    int len;
    unsigned long long Base;
    unsigned long long Size;
    int Type;
} TMemMap;

#pragma pack( pop )

#define RDOS_BASE    0x121000
#define HIGH_BASE    0x100000
#define GDT_BASE       0x1000
#define SYSTEM_BASE    0x2000
#define ALLOC_BASE     0x3000
#define MEM_MAP_BASE  0x9E000

void OpenScreen(const char *FileName);
void CloseScreen();

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
TCpu Cpu;

TSignalDevice RemoteSignal;

int VideoChange[25];

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

    Handle = RdosSpawn("emdisp.exe", "", StartupDir.Get().GetData(), 0, 0, &ThreadId);
    if (Handle)
    {
        RdosFreeProcessHandle(Handle);
        return TRUE;
    }
    return FALSE;
}

/*##################  TextChange  ###############
*   Purpose....: Text change notification                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TextChange(TVideo *Video, int Row)
{
    if (!VideoChange[Row])
    {
        VideoChange[Row] = TRUE;    
        RemoteSignal.Signal();
    }    
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
//    return RdosGetLocalMailslot("emdisp");
//    return RdosGetRemoteMailslot(0x4101A8C0, "emdisp");
    return RdosGetRemoteMailslot(0xA70AA8C0, "emdisp");
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
    int RemoteHandle = GetRemoteIpc();
    char *msg = new char[0x1000];
    char *reply = new char[0x1000];
    struct TBaseReq *BaseReq = (struct TBaseReq *)msg;
    struct TVideoReq *VideoReq = (struct TVideoReq *)msg;
    
    for (row = 0; row < 25; row++)
        VideoChange[row] = FALSE;

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

    Video.OnTextChange = TextChange;

    for (;;)
    {
        RemoteSignal.WaitTimeout(100);

        for (row = 0; row < 25; row++)
        {
            if (VideoChange[row])
            {
                VideoChange[row] = FALSE;
                VideoReq->MsgType = DISP_MSG_VIDEO;
                VideoReq->Row = row;
                memcpy(VideoReq->Data, Video.GetRow(row), 2 * 80);
                RdosSendMailslot(RemoteHandle, msg, sizeof(struct TVideoReq), reply, 0x1000); 
            }                
        }

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
    TFlash Video(&Isa, 0xC0000, 0x10000);
    TFile VideoFile("video.bin");
    Video.LoadBottom(&VideoFile);
    int sel;
    int offset;
    int count;

    int Key;

    MyFocus = RdosGetFocus();

    RdosCreateThread(RemoteThread, "empc remote", 0, 0x4000);

    Pit.Counter[0]->Define(&Pic0, 0);
    
    Pic0.DefineCpu(&Cpu);
    Pic0.OnSet = SetInt;
    Pic0.OnReset = ResetInt;

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

/*##################  CreateCodeSel ##########################
*   Purpose....: Create code selector                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateCodeSel(char *Descr, unsigned long Base, int Size)
{
    short int *sptr;
    int *iptr;

    sptr = (short int *)Descr;
    *sptr = Size - 1;

    iptr = (int *)(Descr + 2);
    *iptr = Base;

    Descr[5] = 0x9A;
    Descr[6] = 0;
    Descr[7] = 0;    
}

/*##################  CreateDataSel ##########################
*   Purpose....: Create data selector                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateDataSel(char *Descr, unsigned long Base, int Size)
{
    short int *sptr;
    int *iptr;

    sptr = (short int *)Descr;
    *sptr = Size - 1;

    iptr = (int *)(Descr + 2);
    *iptr = Base;

    Descr[5] = 0x92;
    Descr[6] = 0;
    Descr[7] = 0;    
}

/*##################  CreateFlatSel ##########################
*   Purpose....: Create flat selector                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CreateFlatSel(char *Descr)
{
    Descr[0] = 0xFF;
    Descr[1] = 0xFF;
    Descr[2] = 0;
    Descr[3] = 0;
    Descr[4] = 0;
    Descr[5] = 0x92;
    Descr[6] = 0xCF;
    Descr[7] = 0;
}

/*##################  Load ##########################
*   Purpose....: Load image file                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int Load(char *FileName)
{
    TRdosImage img;
    TRdosObject *obj;
    TFile File(FileName);
    unsigned long Base;
    char *data;
    int Size;
    char *DescrBase = LowRam.GetData() + GDT_BASE;
    TSystemData *SysData = (TSystemData *)(LowRam.GetData() + SYSTEM_BASE);
    TMemMap *MemMap = (TMemMap *)(LowRam.GetData() + MEM_MAP_BASE);
    short int *VmInt = (short int *)LowRam.GetData();
                
    img.AddImage(FileName);

    if (img.HasKernel())
    {
        Cpu.DefineBus(&Isa);
        Cpu.OnExtClk = ExtClk;
        Cpu.Reset();

        Cpu.CpuState.Reg_gdt.base = GDT_BASE;
        Cpu.CpuState.Reg_gdt.limit = 0xFFF;

        Cpu.CpuState.Reg_ss.base = GDT_BASE;
        Cpu.CpuState.Reg_ss.limit = 0xFFF;
        Cpu.CpuState.Reg_esp = 0x1000;

        CreateFlatSel(DescrBase + 0x20);
        CreateDataSel(DescrBase + 0x28, SYSTEM_BASE, 0x1000);
        CreateDataSel(DescrBase + 0x10, GDT_BASE, 0x1000);

        HighRam.Load(RDOS_BASE - HIGH_BASE, &File);


        data = LowRam.GetData();
        data[0x40E] = 0;
        data[0x40F] = 0x9E;

        VmInt[2 * 0x10] = 0;
        VmInt[2 * 0x10 + 1] = 0xC000;

        SysData->Ram1Size = MEM_MAP_BASE;
        SysData->Ram2Base = RDOS_BASE + File.GetSize();
        SysData->Ram2Base--;
        SysData->Ram2Base &= 0xFFFFF000;
        SysData->Ram2Base += 0x1000;
        SysData->Ram2Size = 0;
        SysData->Rom1Base = RDOS_BASE;
        SysData->Rom1Size = File.GetSize();
        SysData->Rom2Size = 0;
        SysData->AllocBase = ALLOC_BASE;

        SysData->MapBase = MEM_MAP_BASE; 
        SysData->MapSize = 0;

        SysData->RomModules = 1;
        SysData->RomAdapters[0].Base = SysData->Rom1Base;
        SysData->RomAdapters[0].Size = SysData->Rom1Size;
        SysData->RomAdapters[0].Crc = 0;

        MemMap->len = sizeof(TMemMap) - 4;
        MemMap->Base = LowRam.GetBase();
        MemMap->Size = SysData->MapBase - MemMap->Base;
        MemMap->Type = 1;
        MemMap++;
        SysData->MapSize += sizeof(TMemMap);

        MemMap->len = sizeof(TMemMap) - 4;
        MemMap->Base = HIGH_BASE;
        MemMap->Size = RDOS_BASE - HIGH_BASE;
        MemMap->Type = 1;        
        MemMap++;
        SysData->MapSize += sizeof(TMemMap);

        MemMap->len = sizeof(TMemMap) - 4;
        MemMap->Base = SysData->Ram2Base;
        MemMap->Size = HIGH_BASE + HighRam.GetSize() - SysData->Ram2Base;
        MemMap->Type = 1;
        MemMap++;
        SysData->MapSize += sizeof(TMemMap);

        MemMap->len = sizeof(TMemMap) - 4;
        MemMap->Base = Ram64.GetBase();
        MemMap->Size = Ram64.GetSize();
        MemMap->Type = 1;
        SysData->MapSize += sizeof(TMemMap);
             
        obj = img.FObjectList;

        while (obj)
        {
            Cpu.CpuState.Reg_cr0 |= 1;
        
            if (obj->GetType() == RDOS_OBJECT_KERNEL)
            {
                Base = RDOS_BASE + obj->FImageOffset + sizeof(TRdosSimpleDeviceHeader);
                Size = obj->GetSize();
                CreateCodeSel(DescrBase + 0x30, Base, Size);
                Cpu.CpuState.Reg_cs.base = Base;
                Cpu.CpuState.Reg_cs.limit = Size - 1;
                Cpu.CpuState.Reg_cs.selector = 0x30;

                data = HighRam.GetData() + obj->FImageOffset + RDOS_BASE - HIGH_BASE;
                TRdosSimpleDeviceHeader *khdr = (TRdosSimpleDeviceHeader *)data;
                Cpu.CpuState.Reg_eip = khdr->StartIp;
            }

            if (obj->GetType() == RDOS_OBJECT_SHUTDOWN)
            {
                Base = RDOS_BASE + obj->FImageOffset + sizeof(TRdosSimpleDeviceHeader);
                Size = obj->GetSize();
                CreateCodeSel(DescrBase + 0x38, Base, Size);

                Cpu.CpuState.Reg_esp -= 4;
                short int *sdata = (short int *)(LowRam.GetData() + GDT_BASE + Cpu.CpuState.Reg_esp);
                sdata[0] = Cpu.CpuState.Reg_eip;
                sdata[1] = Cpu.CpuState.Reg_cs.selector;
                
                Cpu.CpuState.Reg_cs.base = Base;
                Cpu.CpuState.Reg_cs.limit = Size - 1;
                Cpu.CpuState.Reg_cs.selector = 0x38;

                data = HighRam.GetData() + obj->FImageOffset + RDOS_BASE - HIGH_BASE;
                TRdosSimpleDeviceHeader *khdr = (TRdosSimpleDeviceHeader *)data;
                Cpu.CpuState.Reg_eip = khdr->StartIp;                
            }
            
            obj = obj->FLink;            
        }
        return TRUE;
    }
    return FALSE;
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    char FileName[256];

    if (argc == 2)
    {
        strcpy(FileName, argv[1]);
        strcat(FileName, ".bin");

        if (Load(FileName))
            Start();
    }
    else
        printf("usage: emrdos image base name\r\n");        
}
