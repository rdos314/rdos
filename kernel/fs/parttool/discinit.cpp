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
# discinit.cpp
# Disc init command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "discinit.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TInitFactory::TInitFactory
#
#   Purpose....: Constructor for TInitFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitFactory::TInitFactory(TDiscServer *Server)
  : TCommandFactory("INIT")
{
    FServer = Server;
}

/*##########################################################################
#
#   Name       : TInitFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TInitFactory::Create(TCommandOutput *out, const char *param)
{
    return new TInitCommand(FServer, out, param);
}

/*##########################################################################
#
#   Name       : TInitCommand::TInitCommand
#
#   Purpose....: Constructor for TInitCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInitCommand::TInitCommand(TDiscServer *server, TCommandOutput *out, const char *param)
  : TCommand(out, param)
{
    FHelpScreen = "Init disc";
    FServer = server;
}

/*##########################################################################
#
#   Name       : TInitCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInitCommand::Execute(char *param)
{
    TString str;

    str.printf("Creating %s disc\r\n", param);
    Write(str.GetData());

    if (!FServer->InitDisc(param))
        Write("Init failed\r\n");

    return 0;
}
