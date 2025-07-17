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
# parttool.cpp
# Partition tool command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include <rdos.h>

#include "cmdhelp.h"
#include "lang.h"
#include "parttool.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPartToolFactory::TPartToolFactory
#
#   Purpose....: Constructor for TPartToolFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolFactory::TPartToolFactory()
  : TCommandFactory("PARTTOOL")
{
}

/*##########################################################################
#
#   Name       : TPartToolFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPartToolFactory::Create(TSession *session, const char *param)
{
    return new TPartToolCommand(session, param);
}

/*##########################################################################
#
#   Name       : TPartToolInteract::TPartToolInteract
#
#   Purpose....: Constructor for TPartToolInteract
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolInteract::TPartToolInteract(TKeyboardDevice *Keyboard)
 : TInteract(Keyboard)
{
}

/*##########################################################################
#
#   Name       : TPartToolInteract::~TPartToolInteract
#
#   Purpose....: Destructor for TPartToolInteract
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolInteract::~TPartToolInteract()
{
}

/*##########################################################################
#
#   Name       : TPartToolInteract::Setup
#
#   Purpose....: Setup disc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolInteract::Setup(int DiscNr)
{
    FDiscNr = DiscNr;
}

/*##########################################################################
#
#   Name       : TPartToolInteract::DisplayPrompt
#
#   Purpose....: Display prompt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolInteract::DisplayPrompt()
{
    TString str;

    str.printf("parttool.%d>", FDiscNr);
    Write(str.GetData());
}

/*##########################################################################
#
#   Name       : TPartToolInteract::RunDisc
#
#   Purpose....: Run disc command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolInteract::RunDisc(const char *param)
{
    TWait Wait;
    TPartToolDisc cmd(this, FDiscNr, param);

    Wait.Add(&cmd);

    while (!cmd.IsDone())
        Wait.WaitForever();
}

/*##########################################################################
#
#   Name       : TPartToolInteract::Run
#
#   Purpose....: Run interaction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolInteract::Run()
{
    int ok;
    char param[256];

    for (;;)
    {
        if (FEcho)
            DisplayPrompt();

        ok = ReadCmd(param, 256);
        if (ok)
        {
            if (!strcmp(param, "exit"))
                break;
            else
                RunDisc(param);
        }
    }
}

/*##########################################################################
#
#   Name       : TPartToolDisc::TPartToolDisc
#
#   Purpose....: Constructor for TPartToolDisc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolDisc::TPartToolDisc(TPartToolInteract *interact, int disc, const char *cmd)
 : TVfsDiscCmd(disc, cmd)
{
    FInteract = interact;
}

/*##########################################################################
#
#   Name       : TPartToolDisc::~TPartToolDisc
#
#   Purpose....: Destructor for TPartToolDisc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolDisc::~TPartToolDisc()
{
}

/*##########################################################################
#
#   Name       : TPartToolDisc::NotifyDone
#
#   Purpose....: Notify done
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolDisc::NotifyDone()
{
    FInteract->Write("\r\n\r\n");
}

/*##########################################################################
#
#   Name       : TPartToolDisc::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPartToolDisc::NotifyMsg(const char *msg)
{
    FInteract->Write(msg);
}

/*##########################################################################
#
#   Name       : TPartToolCommand::TPartToolCommand
#
#   Purpose....: Constructor for TPartToolCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolCommand::TPartToolCommand(TSession *session, const char *param)
  : TCommand(session, param),
    FInteract(session->GetKeyboard())
{
}

/*##########################################################################
#
#   Name       : TPartToolCommand::~TPartToolCommand
#
#   Purpose....: Destructor for TPartToolCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPartToolCommand::~TPartToolCommand()
{
}

/*##########################################################################
#
#   Name       : TPartToolCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPartToolCommand::Execute(char *param)
{
    int DiscNr;

    if (!ScanCmdLine(param, 0))
         return 1;

    if (FArgCount < 1)
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

    if (RdosIsVfsDisc(DiscNr))
    {
        FInteract.Setup(DiscNr);
        FInteract.Run();
        return 0;
    }
    else
    {
        ErrorSyntax(0);
        return 1;
    }

}
