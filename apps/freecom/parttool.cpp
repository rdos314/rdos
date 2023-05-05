/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
