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
