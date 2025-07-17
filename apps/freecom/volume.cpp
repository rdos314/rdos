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
# volume.cpp
# Volume command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "volume.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TVolumeFactory::TVolumeFactory
#
#   Purpose....: Constructor for TVolumeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVolumeFactory::TVolumeFactory()
  : TCommandFactory("VOLUME")
{
}

/*##########################################################################
#
#   Name       : TVolumeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TVolumeFactory::Create(TSession *session, const char *param)
{
        return new TVolumeCommand(session, param);
}

/*##########################################################################
#
#   Name       : TVolumeCommand::TVolumeCommand
#
#   Purpose....: Constructor for TVolumeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVolumeCommand::TVolumeCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_VOLUME);
}

/*##########################################################################
#
#   Name       : TVolumeCommand::ShowVolume
#
#   Purpose....: Show current volume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVolumeCommand::ShowVolume()
{
    int L, R;

    RdosGetOutputVolume(&L, &R);

        if (L == R)
        {
                if (L < 0)
                {
                        FMsg.Load(TEXT_VOLUME_OFF);
                        Write(FMsg.GetData());
                }
                else
                {
                        FMsg.printf(TEXT_VOLUME_ON, L);
                        Write(FMsg.GetData());
                }
        }
        else
        {
                if (L < 0)
                {
                        FMsg.Load(TEXT_VOLUME_L_OFF);
                        Write(FMsg.GetData());
                }
                else
                {
                        FMsg.printf(TEXT_VOLUME_L_ON, L);
                        Write(FMsg.GetData());
                }

                if (R < 0)
                {
                        FMsg.Load(TEXT_VOLUME_R_OFF);
                        Write(FMsg.GetData());
                }
                else
                {
                        FMsg.printf(TEXT_VOLUME_R_ON, R);
                        Write(FMsg.GetData());
                }
        }
}

/*##########################################################################
#
#   Name       : TVolumeCommand::SetVolume1
#
#   Purpose....: Set same volune for both channels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::SetVolume1()
{
        const char *str;
    TString Str;
    int Volume;

        Str = FArgList->FName;
        Str.Lower();
        str = Str.GetData();

        if (!strcmp(str, "off"))
                Volume = -1;
        else
                Volume = atoi(str);

        RdosSetOutputVolume(Volume, Volume);

        return 0;
}

/*##########################################################################
#
#   Name       : TVolumeCommand::SetVolume2
#
#   Purpose....: Set different volune for both channels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::SetVolume2()
{
        const char *str;
        int L, R;
        TArg *arg;
        TString Str;

        arg = FArgList;

        Str = arg->FName;
        Str.Lower();
        str = Str.GetData();

        if (!strcmp(str, "off"))
                L = -1;
        else
                L = atoi(str);

        arg = arg->FList;

        Str = arg->FName;
        Str.Lower();
        str = Str.GetData();

        if (!strcmp(str, "off"))
                R = -1;
        else
                R = atoi(str);

        RdosSetOutputVolume(L, R);

        return 0;
}

/*##########################################################################
#
#   Name       : TVolumeCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::Execute(char *param)
{
        if (!ScanCmdLine(param, 0))
                return 1;

        switch (FArgCount)
        {
                case 0:
                        ShowVolume();
                        return 0;

                case 1:
                        return SetVolume1();

                case 2:
                        return SetVolume2();

                default:
                        FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
                        Write(FMsg.GetData());
                        return E_Useage;
        }
}
