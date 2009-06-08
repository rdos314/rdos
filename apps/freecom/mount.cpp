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
# mount.cpp
# Mount file onto a drive command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "mount.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TMountFactory::TMountFactory
#
#   Purpose....: Constructor for TMountFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMountFactory::TMountFactory()
  : TCommandFactory("MOUNT")
{
}

/*##########################################################################
#
#   Name       : TMountFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TMountFactory::Create(TSession *session, const char *param)
{
        return new TMountCommand(session, param);
}

/*##########################################################################
#
#   Name       : TMountCommand::TMountCommand
#
#   Purpose....: Constructor for TMountCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMountCommand::TMountCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_MOUNT);
        FDrive = 0;
}

/*##########################################################################
#
#   Name       : TMountCommand::~TMountCommand
#
#   Purpose....: Destructor for TMountCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMountCommand::~TMountCommand()
{
    if (FDrive)
        delete FDrive;
}

/*##########################################################################
#
#   Name       : TMountCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMountCommand::InitOptions()
{
        FOptD = FALSE;
}

/*##########################################################################
#
#   Name       : TMountCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMountCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        switch (ch)
        {
                case 'D': 
                        return OptScanBool(optstr, bool, strarg, &FOptD);
        }  
        OptError(optstr);
        return E_Useage;
}

/*##########################################################################
#
#   Name       : TMountCommand::Mount
#
#   Purpose....: Mount file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMountCommand::Mount(TString filename)
{
    if (!FDrive->OpenFileDrive(filename.GetData()))
    {
        FMsg.printf(TEXT_ERROR_BADCOMMAND, filename.GetData());
            Write(FMsg.GetData());
                return E_Useage;
    }
    return 0;
}

/*##########################################################################
#
#   Name       : TMountCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMountCommand::Execute(char *param)
{
        const char *DriveStr;
        char str[3];

        InitOptions();

        if (!ScanCmdLine(param, 0))
                return 1;

    if (FOptD)
    {
        if (FArgCount == 2)
        {
            DriveStr = FArgList->FName.GetData();

            if (strlen(DriveStr) == 1 ||
                (strlen(DriveStr) == 2 && DriveStr[1] == ':'))
            {
                str[0] = DriveStr[0];
                str[1] = ':';
                str[2] = 0;
                strupr(str);
                                FDrive = TDrive::AllocateFixed(str[0] - 'A');
                return Mount(FArgList->FList->FName);
            }
            else
                {
                        ErrorSyntax(0);
                        return 1;
                }
            
        
        }
        else
        {
                FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
                Write(FMsg.GetData());
                    return E_Useage;
                }
    }
    else
    {
        if (FArgCount == 1)
        {
            FDrive = TDrive::AllocateDynamic(); 
                return Mount(FArgList->FName);
        }
        else
        {
                FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
                Write(FMsg.GetData());
                    return E_Useage;
                }
    }

    return 0;
}

