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
    int RemoteHandle = RdosGetLocalMailslot("emdisp");
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
            RemoteHandle = RdosGetLocalMailslot("emdisp");
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

        BaseReq->MsgType = DISP_MSG_KEY;
        size = RdosSendMailslot(RemoteHandle, msg, sizeof(struct TBaseReq), reply, 0x1000); 
        if (size == 1)
            Keyb.NotifyKey(reply[0]);
    }
}

/*##################  Idle  ###############
*   Purpose....: Idle                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void Idle(TCpu *Cpu)
{
    if (RdosPollKeyboard())
    {
        RdosReadKeyboard();
        Cpu->Break();
    }
}

/*##################  SetClk  ###############
*   Purpose....: 1 / 8 clk high notification                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void SetClk(TCpu *Cpu)
{
    Pit.Counter[0]->SetClk();
    Pit.Counter[2]->SetClk();
}

/*##################  ResetClk  ###############
*   Purpose....: 1 / 8 clk low notification                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void ResetClk(TCpu *Cpu)
{
    Pit.Counter[0]->ResetClk();
    Pit.Counter[2]->ResetClk();
    Cpu->PendingInt = Pic0.IsIntActive();
}

/*##################  GetIntVector  ###############
*   Purpose....: Get interrupt vector                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char __cdecl GetIntVector(TCpu *Cpu)
{
    return Pic0.GetVector();
}

/*##################  ReadFromMemory  ###############
*   Purpose....: Read from memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadFromMemory(TCpu *Cpu, unsigned long Address)
{
    return Isa.ReadMem(Address);
}

/*##################  WriteToMemory  ###############
*   Purpose....:  Write to memory                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToMemory(TCpu *Cpu, unsigned long Address, char Value)
{
    Isa.WriteMem(Address, Value);
}

/*##################  ReadFromIo  ###############
*   Purpose....: Read from IO                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char ReadFromIo(TCpu *Cpu, unsigned short int Port)
{
    return Isa.In(Port);
}

/*##################  WriteToIo  ###############
*   Purpose....: Read from IO                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void WriteToIo(TCpu *Cpu, unsigned short int Port, char Value)
{
    Isa.Out(Port, Value);
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
    TPic Pic1(&Isa, 0xA0);
    Pic0.Cascade(2, &Pic1);
    TCmos Cmos(&Isa, 0x70);

    TFlash Bios(&Isa, 0xFFFF0000, 0x10000);
    TFlash BiosShadow(&Isa, 0xF0000, 0x10000, Bios.GetData());
    TFile BiosFile("bios.bin");
    Bios.LoadBottom(&BiosFile);
    TRam LowRam(&Isa, 0, 0x80000);
    TRam HighRam(&Isa, 0x100000, 0x700000);
    TCpu Cpu;
    TPciIde PciIde(&Pci);
    int Key;


    MyFocus = RdosGetFocus();

    PciIde.AddDisc(1);

    RdosCreateThread(RemoteThread, "empc remote", 0, 0x4000);

//    OpenScreen("f:\\sim.log");

    Pit.Counter[0]->Define(&Pic0, 0);

    Cpu.Define(&Pic0);
    Cpu.OnSetClk = SetClk;
    Cpu.OnResetClk = ResetClk;
    Cpu.OnIdle = Idle;
    Cpu.OnReadFromMemory = ReadFromMemory;
    Cpu.OnWriteToMemory = WriteToMemory;
    Cpu.OnReadFromIo = ReadFromIo;
    Cpu.OnWriteToIo = WriteToIo;
    Cpu.Reset();

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

            case 'd':
            case 'D':
                Cpu.ShowData();
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
                Cpu.ShowInstruction(20);
                RdosReadKeyboard();
                break;

            case 'b':
            case 'B':
                Cpu.ShowPreviousInstruction();
                RdosReadKeyboard();
                break;
        }
    }
    CloseScreen();
}
