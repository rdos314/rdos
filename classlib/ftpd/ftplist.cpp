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
# ftplist.cpp
# List command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "ftpserv.h"
#include "ftplist.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpListFactory::TFtpListFactory
#
#   Purpose....: Constructor for TFtpListFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpListFactory::TFtpListFactory()
  : TFtpCommandFactory("LIST")
{
}

/*##########################################################################
#
#   Name       : TFtpListFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpListFactory::Create(TFtpSocketServer *Server, const char *param)
{
        return new TFtpListCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpListCommand::TFtpListCommand
#
#   Purpose....: Constructor for TFtpListCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpListCommand::TFtpListCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpListCommand::~TFtpListCommand
#
#   Purpose....: Destructor for TFtpListCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpListCommand::~TFtpListCommand()
{
}

/*##########################################################################
#
#   Name       : TFtpListCommand::WriteEntry
#
#   Purpose....: Write detailed listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpListCommand::WriteEntry(const TDirEntryData &entry)
{
    TDateTime CurrTime;
    char str[31];
    long long size;

        if (entry.Attribute & FILE_ATTRIBUTE_DIRECTORY)
        {
        FServer->Write("drw-rw-rw- ");
                FDirCount++;
                }
        else
        {
        FServer->Write("-rw-rw-rw- ");
                FFileCount++;
                FTotalSize += (int)entry.FileSize;

        }

        FServer->Write(" 0 pg92075 ");

        if (entry.Attribute & FILE_ATTRIBUTE_DIRECTORY)
                FServer->Write("4096");
        else
        {
                sprintf(str, "%d", entry.FileSize);
                FServer->Write(str);
        }

        switch (entry.ModifyTime.GetMonth())
        {
                case 1:
                        FServer->Write(" Jan ");
                        break;

                case 2:
                        FServer->Write(" Feb ");
                        break;

                case 3:
                                                FServer->Write(" Mar ");
                        break;

                case 4:
                        FServer->Write(" Apr ");
                        break;

                case 5:
                        FServer->Write(" May ");
                        break;

                case 6:
                        FServer->Write(" Jun ");
                        break;

                case 7:
                        FServer->Write(" Jul ");
                        break;

                case 8:
                        FServer->Write(" Aug ");
                        break;

                case 9:
                        FServer->Write(" Sep ");
                        break;

                case 10:
                        FServer->Write(" Oct ");
                        break;

                case 11:
                        FServer->Write(" Nov ");
            break;

        case 12:
            FServer->Write(" Dec ");
            break;
    }

    if (CurrTime.GetYear() == entry.ModifyTime.GetYear())
        sprintf(str, "%02d %02d:%02d ",
                                        entry.ModifyTime.GetDay(),
                                        entry.ModifyTime.GetHour(),
                                        entry.ModifyTime.GetMin());
        else
                sprintf(str, "%02d %04d ",
                                        entry.ModifyTime.GetDay(),
                                        entry.ModifyTime.GetYear());

        FServer->Write(str);

        size = entry.EntryName.GetSize();
        strncpy(str, entry.EntryName.GetData(), 30);

        FServer->Write(str);

        FServer->Write("\r\n");
}

/*##########################################################################
#
#   Name       : TFtpListCommand::WriteEntry
#
#   Purpose....: Write detailed listing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpListCommand::WriteEntry()
{
        int ok;

    ok = FDirList.GotoFirst();
    while (ok)
    {
        WriteEntry(FDirList.Get().Get());
        ok = FDirList.GotoNext();
    }

        ok = FFileList.GotoFirst();
        while (ok)
        {
                WriteEntry(FFileList.Get().Get());
                ok = FFileList.GotoNext();
        }
}

/*##########################################################################
#
#   Name       : TFtpListCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpListCommand::Execute(char *param)
{
        TFtpArg *arg;
        int ArgCount;
        TFtpLangString msg;
        int ok;
        TPathName path(FServer->RootDir);

        path += FServer->CurrDir;

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

                        FFileCount = 0;
                        FDirCount = 0;
                        FTotalSize = 0;

                        arg = FArgList;

                        FFileList.SetIgnoredAttributes(FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_DIRECTORY);
                        FDirList.SetRequiredAttributes(FILE_ATTRIBUTE_DIRECTORY);
                        FDirList.SetIgnoredAttributes(FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM);

                        if (arg)
                        {
                                while (arg)
                                {
                                        FFileList.Add(path + arg->FName);
                                        FDirList.Add(path + arg->FName);
                                        arg = arg->FList;
                                }
                        }
                        else
                        {
                                FFileList.Add(path + "*");
                                FDirList.Add(path + "*");
                        }

                        FFileList.RemoveDuplicates();
                        FDirList.RemoveDuplicates();

                        FFileList.Sort();
                        FDirList.Sort();

                        msg.Load(150);
                        FServer->Reply(&msg);

                        WriteEntry();

                        FServer->Push();

                        msg.Load(226);
                }
                else
                        msg.Load(501);
        }
        else
                msg.Load(530);

        FServer->Reply(&msg);

}
