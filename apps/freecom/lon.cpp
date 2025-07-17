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
# lon.cpp
# Lon command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "lon.h"

#define FALSE 0
#define TRUE !FALSE

TString LonFileName = "z:\\lon.raw";
int LonHandle = 0;

/*##########################################################################
#
#   Name       : TLonFactory::TLonFactory
#
#   Purpose....: Constructor for TLonFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonFactory::TLonFactory()
  : TCommandFactory("LON")
{
}

/*##########################################################################
#
#   Name       : TLonFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TLonFactory::Create(TSession *session, const char *param)
{
    return new TLonCommand(session, param);
}

/*##########################################################################
#
#   Name       : TLonCommand::TLonCommand
#
#   Purpose....: Constructor for TLonCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonCommand::TLonCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_LON);
}

/*##########################################################################
#
#   Name       : TLonCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLonCommand::Execute(char *param)
{
    TString Str;
    const char *str;
    const char *file;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 1)
    {
         FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
         Write(FMsg.GetData());
         return E_Useage;
    }

    Str = FArgList->FName;
    Str.Lower();
    str = Str.GetData();

    if (!strcmp(str, "off"))
    {
        RdosStopLonCapture();

        if (LonHandle)
        {
            RdosCloseFile(LonHandle);
            LonHandle = 0;
        }

        FMsg.Load(TEXT_LON_OFF);
        Write(FMsg.GetData());
        return 0;
    }

    if (strcmp(str, "on"))
        LonFileName = FArgList->FName;

    if (LonHandle)
    {
        RdosStopLonCapture();
        RdosCloseFile(LonHandle);
        LonHandle = 0;
    }

    file = LonFileName.GetData();
    LonHandle = RdosOpenFile(file, 0);
    if (!LonHandle)
        LonHandle = RdosCreateFile(file, 0);

    if (LonHandle)
    {
        RdosStartLonCapture(LonHandle);
        FMsg.printf(TEXT_LON_ON, file);
        Write(FMsg.GetData());
        return 0;
    }
    else
    {
         FMsg.Load(TEXT_ERROR_FILE_NOT_FOUND);
         Write(FMsg.GetData());
         return E_Useage;
    }
}
