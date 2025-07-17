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
# showpart.cpp
# Show partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "disc.h"
#include "showpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TShowPartitionFactory::TShowPartitionFactory
#
#   Purpose....: Constructor for TShowPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionFactory::TShowPartitionFactory()
  : TCommandFactory("PART")
{
}

/*##########################################################################
#
#   Name       : TShowPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TShowPartitionFactory::Create(TSession *session, const char *param)
{
    return new TShowPartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::TShowPartitionCommand
#
#   Purpose....: Constructor for TShowPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionCommand::TShowPartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_SHOWPART);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        switch(ch)
        {
                case 'D':
                        return OptScanBool(optstr, bool, strarg, &FOptD);
        }
        OptError(optstr);
        return E_Useage;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::InitOptions()
{
        FOptD = 0;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowEntry
#
#   Purpose....: Show entry table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowEntry(int Nr, TIdePartition *Entry)
{
    const char *Name;
    int Typ;
    double TotalSpace;
    double FreeSpace;
    int DriveNr;
    TDrive *Drive;
    char DriveStr[4];
    char str[100];

    if (Entry)
    {
        Name = Entry->GetPartName();
        Typ = Entry->GetType();
        TotalSpace = Entry->GetTotalSpace();

        if (Entry->Size)
        {
            if (Entry->IsFs() && Entry->GetDrive())
            {
                Drive = Entry->GetDrive();
                if (Drive)
                    DriveNr = Drive->GetDriveNr();
                else
                    DriveNr = 0;
            }
            else
                DriveNr = 0;

            if (DriveNr)
            {
                DriveStr[0] = 'A' + (char)DriveNr;
                DriveStr[1] = ':';
                DriveStr[2] = 0;

                FreeSpace = Entry->GetFreeSpace();

                sprintf(str,
                             "%d: %s %02hX %08lX-%08lX %8s %15.3f MB %15.3f MB\r\n",
                             Nr,
                             DriveStr,
                             Typ,
                             Entry->Start,
                             Entry->Start + Entry->Size - 1,
                             Name,
                             TotalSpace,
                             FreeSpace);
            }
            else
                sprintf(str,
                            "%d: -- %02hX %08lX-%08lX %8s %15.3f MB\r\n",
                            Nr,
                            Typ,
                            Entry->Start,
                            Entry->Start + Entry->Size - 1,
                            Name,
                            TotalSpace);
            Write(str);
        }
        else
        {
            FMsg.printf(TEXT_SHOWPART_FREE_ENTRY, Nr);
            Write(FMsg.GetData());
        }
    }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowFreeEntry
#
#   Purpose....: Show free entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowFreeEntry(int Nr, TPartition *Entry)
{
    const char *Name;
    double TotalSpace;
    char str[100];

    Name = Entry->GetPartName();
    TotalSpace = Entry->GetTotalSpace();

    sprintf(str,
            "%d: -- -- %08lX-%08lX %8s %15.3f MB\r\n",
             Nr,
             Entry->Start,
             Entry->Start + Entry->Size - 1,
             Name,
             TotalSpace);
    Write(str);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTreeTable
#
#   Purpose....: Show tree table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTreeTable(TIdePartitionTable *Part)
{
        int i;
        TIdePartition *Entry;
        double TotalSpace;
        char str[100];

        TotalSpace = Part->GetTotalSpace();

        sprintf(str, "%08lX-%08lX %15.3f MB\r\n",
                                Part->Start,
                                Part->Start + Part->Size - 1,
                                TotalSpace);

        Write(str);

        FMsg.Load(TEXT_SHOWPART_HEADER);
        Write(FMsg.GetData());

        for (i = 0; i < 4; i++)
                ShowEntry(i, Part->PartArr[i]);

        for (i = 0; i < 4; i++)
        {
                Entry = (TIdePartition *)Part->PartArr[i];
                if (Entry)
                        if (Entry->IsTable())
                                ShowTreeTable((TIdePartitionTable *)Entry);
        }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTree
#
#   Purpose....: Show tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTree(TIdeDiscPartition *Part)
{
    if (Part->PartRoot)
        ShowTreeTable(Part->PartRoot);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTable
#
#   Purpose....: Show table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTable(TIdeDiscPartition *Part)
{
    int i;
    TDisc *Disc;
    long long TotalSectors;
    TPartition *Entry;

    Disc = Part->GetDisc();
    TotalSectors = Disc->GetTotalSectors();

    FMsg.printf(TEXT_SHOWPART_DISC_LONG, (int)(TotalSectors >> 32), (int)(TotalSectors & 0xFFFFFFFF), Disc->GetSectorsPerCyl(), Disc->GetHeads());
    Write(FMsg.GetData());

    FMsg.Load(TEXT_SHOWPART_HEADER);
    Write(FMsg.GetData());

    for (i = 0; i < Part->PartCount; i++)
    {
        Entry = Part->PartArr[i];
        if (Entry)
        {
            if (Entry->IsFree())
                ShowFreeEntry(i, Entry);
            else
                ShowEntry(i, (TIdePartition *)Entry);
        }
    }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowGpt
#
#   Purpose....: Show GPT partitions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowGpt(TDisc *Disc)
{
    int i;
    TGptDiscPartition *DiscPart;
    TGptPartition *Entry;
    long double TotalSpace;
    char name[10];
    char guid[32];
    char str[256];
    long long TotalSectors = Disc->GetTotalSectors();
    long long Start;
    long long End;
    long long CurrLba;
    int DriveNr;

    DiscPart = new TGptDiscPartition(Disc);
    DiscPart->Read();

    FMsg.printf(TEXT_SHOWPART_DISC_GPT, (int)(TotalSectors >> 32), (int)(TotalSectors & 0xFFFFFFFF));
    Write(FMsg.GetData());

    FMsg.Load(TEXT_SHOWPART_GPT_HEADER);
    Write(FMsg.GetData());

    CurrLba = DiscPart->GetStart();

    for (i = 0; i < DiscPart->PartCount; i++)
    {
        Entry = DiscPart->PartArr[i];

        if (CurrLba < Entry->Start)
        {
            Start = CurrLba;
            End = Entry->Start - 1;
            TotalSpace = (double)(Entry->Start - CurrLba) * (double)512 / (double)0x100000;
            sprintf(str,
                    "-: -- %04lX_%08lX-%04lX_%08lX     Free %8ld MB \r\n",
                    (int)(Start >> 32), (int)(Start & 0xFFFFFFFF),
                    (int)(End >> 32), (int)(End & 0xFFFFFFFF),
                    (int)TotalSpace);
            Write(str);
        }

        memcpy(name, Entry->Name, 8);
        name[8] = 0;
        TotalSpace = Entry->GetTotalSpace();
        memcpy(guid, Entry->GuidStr, 24);
        guid[24] = 0;

        Start = Entry->Start;
        End = Entry->Start + Entry->Size - 1;
        DriveNr = Disc->GetDrive(Entry->Start, Entry->Size);

        if (DriveNr)
            sprintf(str,
                    "%d: %c: %04lX_%08lX-%04lX_%08lX %8s %8ld MB %s\r\n",
                    i,
                    (char)DriveNr + 'A',
                    (int)(Start >> 32), (int)(Start & 0xFFFFFFFF),
                    (int)(End >> 32), (int)(End & 0xFFFFFFFF),
                    Entry->Name,
                    (int)TotalSpace,
                    guid);
        else
            sprintf(str,
                    "%d: -- %04lX_%08lX-%04lX_%08lX %8s %8ld MB %s\r\n",
                    i,
                    (int)(Start >> 32), (int)(Start & 0xFFFFFFFF),
                    (int)(End >> 32), (int)(End & 0xFFFFFFFF),
                    Entry->Name,
                    (int)TotalSpace,
                    guid);

        Write(str);

        CurrLba = Entry->Start + Entry->Size + 1;
    }

    if (CurrLba < DiscPart->GetEnd())
    {
        Start = CurrLba;
        End = DiscPart->GetEnd();
        TotalSpace = (double)(End - Start + 1) * (double)512 / (double)0x100000;
        sprintf(str,
                "-: -- %04lX_%08lX-%04lX_%08lX     Free %8ld MB \r\n",
                (int)(Start >> 32), (int)(Start & 0xFFFFFFFF),
                (int)(End >> 32), (int)(End & 0xFFFFFFFF),
                (int)TotalSpace);
        Write(str);
    }

    delete DiscPart;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowHeader
#
#   Purpose....: Show disc header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowHeader(TDisc *Disc)
{
    char str[256];
    long long CacheSize = Disc->GetCached();
    long long LockSize = Disc->GetLocked();
    long double cached;
    long double locked;

    Write("\r\n");

    RdosGetDiscVendorInfo(Disc->GetDiscNr(), str, 256);
    FMsg.printf(TEXT_SHOWPART_DISC_HEADER, Disc->GetDiscNr(), str);
    Write(FMsg.GetData());

    if (CacheSize)
    {
        cached = (long double)CacheSize / 1024.0 / 1024.0;
        locked = (long double)LockSize / 1024.0 / 1024.0;
        FMsg.printf(TEXT_SHOWPART_DISC_CACHE, cached, locked);
        Write(FMsg.GetData());
    }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Show
#
#   Purpose....: Show result
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::Show(TDisc *Disc)
{
    TIdeDiscPartition *DiscPart;

    if (Disc->IsValid())
    {
        ShowHeader(Disc);

        if (Disc->IsGpt())
        {
            ShowGpt(Disc);
            return TRUE;
        }
        else
        {
            DiscPart = new TIdeDiscPartition(Disc);

            if (FOptD)
                ShowTree(DiscPart);
            else
                ShowTable(DiscPart);

            delete DiscPart;
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowVfs
#
#   Purpose....: Show VFS disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowVfs(int DiscNr)
{
    TWait Wait;
    TVfsDiscCmdWrapper cmd(this, DiscNr, "info");

    Write("\r\n");

    Wait.Add(&cmd);

    while (!cmd.IsDone())
        Wait.WaitForever();
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::Execute(char *param)
{
    int DiscNr;
    int d;
    TDisc *Disc;

    InitOptions();

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    /* if no parameters, show all */
    if (*param == 0)
    {
        for (DiscNr = 0; DiscNr < 16; DiscNr++)
        {
            if (RdosIsVfsDisc(DiscNr))
                ShowVfs(DiscNr);
            else
            {
                Disc = new TDisc(DiscNr);
                if (Disc->IsValid())
                    Show(Disc);
                delete Disc;
            }
        }
        return 0;
    }

    if (sscanf(param, "%d", &DiscNr) == 1)
    {
        if (RdosIsVfsDisc(DiscNr))
            ShowVfs(DiscNr);
        else
        {
            for (d = 0; d < 16; d++)
            {
                Disc = new TDisc(d);
                if (Disc->IsValid())
                    if (Disc->GetDiscNr() == DiscNr)
                        break;
                delete Disc;
                Disc = 0;
            }

            if (Disc == 0 || !Show(Disc))
            {
                FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
                Write(FMsg.GetData());
            }
        }
    }
    else
    {
        ErrorSyntax(0);
        return 1;
    }

    return 0;
}

