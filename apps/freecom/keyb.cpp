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
# keyb.cpp
# Keyboard mapping command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "keyb.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TKeybFactory::TKeybFactory
#
#   Purpose....: Constructor for TKeybFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeybFactory::TKeybFactory()
  : TCommandFactory("KEYB")
{
}

/*##########################################################################
#
#   Name       : TKeybFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TKeybFactory::Create(TSession *session, const char *param)
{
        return new TKeybCommand(session, param);
}

/*##########################################################################
#
#   Name       : TKeybCommand::TKeybCommand
#
#   Purpose....: Constructor for TKeybCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeybCommand::TKeybCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_KEYB);
}

/*##########################################################################
#
#   Name       : TKeybCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TKeybCommand::Execute(char *param)
{
    char MapStr[10];

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (*param == 0)
    {
        RdosGetKeyMap(MapStr);
        FMsg.printf(TEXT_MSG_CURRENT_KEYB, MapStr);
        Write(FMsg.GetData());
        param = 0;
    }
    else
    {
        if (!RdosSetKeyMap(param))
        {
             FMsg.Load(TEXT_ERROR_INVALID_KEYB);
            Write(FMsg.GetData());
        }
    }

    return 0;
}
