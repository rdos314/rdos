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
# ftpstor.cpp
# Stor command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpstor.h"
#include "path.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpStorFactory::TFtpStorFactory
#
#   Purpose....: Constructor for TFtpStorFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpStorFactory::TFtpStorFactory()
  : TFtpCommandFactory("STOR")
{
}

/*##########################################################################
#
#   Name       : TFtpStorFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpStorFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpStorCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpStorCommand::TFtpStorCommand
#
#   Purpose....: Constructor for TFtpStorCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpStorCommand::TFtpStorCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpStorCommand::~TFtpStorCommand
#
#   Purpose....: Destructor for TFtpStorCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpStorCommand::~TFtpStorCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpStorCommand::SaveFile
#
#   Purpose....: Save file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpStorCommand::SaveFile(const char *name)
{
    TFtpLangString msg;
    int size;
    int totalsize = 0;
    int res;
    char *buf = new char[512];
    TPathName relpath = TPathName(FServer->CurrDir) + TString(name);
    TPathName abspath = TPathName(FServer->RootDir) + relpath.Get();
    TFile file = abspath.CreateFile(0);

    if (file.IsOpen())
    {
        msg.Load(150);
        FServer->Reply(&msg);    

        while (FServer->IsOpen())
        {
            size = FServer->Read(buf, 512);
            totalsize += size;
            file.Write(buf, size);
        }

        size = FServer->Read(buf, 512);
        while (size)
        {
            totalsize += size;
            file.Write(buf, size);
            size = FServer->Read(buf, 512);
        }

        FServer->Push();

        res = 226;
    }
    else
        res = 450;

    delete buf;

    return res;
}

/*##########################################################################
#
#   Name       : TFtpStorCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpStorCommand::Execute(char *param)
{
    TFtpArg *arg;
    int ArgCount;
    TFtpLangString msg;
    int res;
    int ok;

    if (FServer->VerifyUser())
    {
        ok = ScanCmdLine(param, 0);
        if (ok)
        {
            ArgCount = 0;
            arg = FArgList;
            while (arg)
            {
                ArgCount++;
                arg = arg->FList;
            }

            ok = (FArgCount == 1);
        }

        if (ok)
        {
            res = SaveFile(FArgList->FName.GetData()); 
            msg.Load(res);
        }
        else
            msg.Load(501);
    }
    else
        msg.Load(530);

    FServer->Reply(&msg);    

}
