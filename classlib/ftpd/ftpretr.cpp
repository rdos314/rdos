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
# ftpretr.cpp
# Ftp Retr command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftpretr.h"
#include "path.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpRetrFactory::TFtpRetrFactory
#
#   Purpose....: Constructor for TFtpRetrFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRetrFactory::TFtpRetrFactory()
  : TFtpCommandFactory("RETR")
{
}

/*##########################################################################
#
#   Name       : TFtpRetrFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpRetrFactory::Create(TFtpSocketServer *Server, const char *param)
{
        return new TFtpRetrCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpRetrCommand::TFtpRetrCommand
#
#   Purpose....: Constructor for TFtpRetrCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRetrCommand::TFtpRetrCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpRetrCommand::~TFtpRetrCommand
#
#   Purpose....: Destructor for TFtpRetrCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpRetrCommand::~TFtpRetrCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpRetrCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpRetrCommand::Execute(char *param)
{
        TFtpArg *arg;
        int ArgCount;
        TFtpLangString msg;
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
                        TPathName relpath = TPathName(FServer->CurrDir) + TString(FArgList->FName);
                        TPathName abspath = TPathName(FServer->RootDir) + relpath.Get();
                        if (abspath.IsFile())
                        {
                                msg.Load(150);
                                FServer->Reply(&msg);

                                TFile file = abspath.OpenFile();
                                char *buf = new char[0x1000];
                                int len = file.Read(buf, 0x1000);

                                while (len)
                                {
                                        FServer->Write(buf, len);
                                        len = file.Read(buf, 0x1000);
                                }

                                delete buf;
                                FServer->Push();
                        }

                        msg.Load(226);
                }
                else
                        msg.Load(501);
        }
        else
                msg.Load(530);

        FServer->Reply(&msg);

}
