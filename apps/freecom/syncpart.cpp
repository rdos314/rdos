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
# syncpart.cpp
# Sync partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "syncpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TSyncPartitionFactory::TSyncPartitionFactory
#
#   Purpose....: Constructor for TSyncPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSyncPartitionFactory::TSyncPartitionFactory()
  : TCommandFactory("SYNCPART")
{
}

/*##########################################################################
#
#   Name       : TSyncPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TSyncPartitionFactory::Create(TSession *session, const char *param)
{
    return new TSyncPartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TSyncPartitionCommand::TSyncPartitionCommand
#
#   Purpose....: Constructor for TSyncPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSyncPartitionCommand::TSyncPartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_SYNCPART);
}

/*##########################################################################
#
#   Name       : TSyncPartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSyncPartitionCommand::Execute(char *param)
{
    int DiscNr;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 1)
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

    RdosSyncDiscPart(DiscNr);

    return 0;
}

