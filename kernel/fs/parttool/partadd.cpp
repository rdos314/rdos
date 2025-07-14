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
# partadd.cpp
# Add partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "partadd.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TAddPartitionFactory::TAddPartitionFactory
#
#   Purpose....: Constructor for TAddPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAddPartitionFactory::TAddPartitionFactory(TDiscServer *Server)
  : TCommandFactory("ADD")
{
    FServer = Server;
}

/*##########################################################################
#
#   Name       : TAddPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TAddPartitionFactory::Create(TCommandOutput *out, const char *param)
{
    return new TAddPartitionCommand(FServer, out, param);
}

/*##########################################################################
#
#   Name       : TAddPartitionCommand::TAddPartitionCommand
#
#   Purpose....: Constructor for TAddPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAddPartitionCommand::TAddPartitionCommand(TDiscServer *server, TCommandOutput *out, const char *param)
  : TCommand(out, param)
{
    FHelpScreen = "Add (partition) type size (MB)";
    FServer = server;
}

/*##########################################################################
#
#   Name       : TAddPartitionCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAddPartitionCommand::Execute(char *param)
{
    TString str;
    const char *FsName;
    long long Sectors;

    if (!ScanCmdLine(param, 0))
        return 1;

    if (FArgCount != 2)
    {
        Write("Usage: add type sectors\r\n");
        return 1;
    }

    FsName = FArgList->FName.GetData();

    if (sscanf(FArgList->FList->FName.GetData(), "%lld", &Sectors) != 1)
    {
        Write("Invalid sector value\r\n");
        return 1;
    }

    str.printf("Add %s %lld\r\n", FsName, Sectors);
    Write(str.GetData());

    if (FServer->AddPartition(FsName, Sectors))
    {
        while (FServer->IsBusy())
        {
            Write(".");
            RdosWaitMilli(250);
        }

        Write("\r\n");
    }
    else
        Write("Failed to add partition\r\n");

    return 0;
}
