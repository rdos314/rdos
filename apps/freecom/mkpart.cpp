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
# mkpart.cpp
# Make partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "mkpart.h"
#include "gptpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMakePartitionFactory::TMakePartitionFactory
#
#   Purpose....: Constructor for TMakePartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMakePartitionFactory::TMakePartitionFactory()
  : TCommandFactory("MKPART")
{
}

/*##########################################################################
#
#   Name       : TMakePartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMakePartitionFactory::Create(TSession *session, const char *param)
{
        return new TMakePartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::TMakePartitionCommand
#
#   Purpose....: Constructor for TMakePartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMakePartitionCommand::TMakePartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_MKPART);
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::Make
#
#   Purpose....: Make partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMakePartitionCommand::Make(TDisc *Disc, const char *FsName, int Size)
{
    TIdeDiscPartition *DiscPart;
    TGptDiscPartition *GptDisc;
    int ok;
    char *BootCode;
    int BootSize;

    if (Disc->IsValid())
    {
        BootCode = new char[512];
        BootSize = RdosReadBinaryResource(0, 100, BootCode, 0x1BE);

        if (Disc->IsGpt())
        {
            GptDisc = new TGptDiscPartition(Disc);
            GptDisc->Read();
            ok = GptDisc->Add(FsName, Size, BootCode, BootSize);
            if (ok)
                GptDisc->Write();        

            RdosWaitMilli(1000);
            Disc->WaitForIdle();
            delete GptDisc;
        }
        else
        {
            DiscPart = new TIdeDiscPartition(Disc);
            ok = DiscPart->Add(FsName, Size, BootCode, BootSize);

            RdosWaitMilli(1000);
            Disc->WaitForIdle();
            delete DiscPart;
        }

        delete BootCode;

        if (ok)
            return 0;
        else
        {
            FMsg.Load(TEXT_MKPART_ERROR);
            Write(FMsg.GetData());
            return 1;
        }
    }
    return 0;    
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::AddVfs
#
#   Purpose....: Make partition
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMakePartitionCommand::AddVfs(int DiscNr, const char *Cmd)
{
    TWait Wait;
    TVfsDiscCmdWrapper cmd(this, DiscNr, Cmd);

    Wait.Add(&cmd);

    while (!cmd.IsDone())
        Wait.WaitForever();
}

/*##########################################################################
#
#   Name       : TMakePartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMakePartitionCommand::Execute(char *param)
{
    int DiscNr;
    int d;
    TDisc *Disc;
    long Size;
    const char *FsName;
    int ret;
    long long sectors;
    TString cmd;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 3)
    {
        FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
        Write(FMsg.GetData());
        return E_Useage;
    }

    if (sscanf(FArgList->FName.GetData(), "%d", &DiscNr) != 1)
    {
        ErrorSyntax(0);
        return 1;
    }

    FsName = FArgList->FList->FName.GetData();

    if (sscanf(FArgList->FList->FList->FName.GetData(), "%d", &Size) != 1)
    {
        ErrorSyntax(0);
        return 1;
    }

    ret = 1;

    if (RdosIsVfsDisc(DiscNr))
    {
        sectors = (long long)Size * 0x800;
        cmd.printf("add %s %lld", FsName, sectors);
        AddVfs(DiscNr, cmd.GetData());
    }
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

        if (Disc && Disc->IsValid())
            ret = Make(Disc, FsName, Size * 0x800);
        delete Disc;
    }
        
    return ret;
}

