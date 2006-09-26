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
# capture.cpp
# Capture command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "capture.h"

#define FALSE 0
#define TRUE !FALSE

TString CaptureFileName = "z:\\net.cap";
int CaptureHandle = 0;

/*##########################################################################
#
#   Name       : TCaptureFactory::TCaptureFactory
#
#   Purpose....: Constructor for TCaptureFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCaptureFactory::TCaptureFactory()
  : TCommandFactory("CAPTURE")
{
}

/*##########################################################################
#
#   Name       : TCaptureFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TCaptureFactory::Create(TSession *session, const char *param)
{
	return new TCaptureCommand(session, param);
}

/*##########################################################################
#
#   Name       : TCaptureCommand::TCaptureCommand
#
#   Purpose....: Constructor for TCaptureCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCaptureCommand::TCaptureCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_CAPTURE);
}

/*##########################################################################
#
#   Name       : TCaptureCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCaptureCommand::Execute(char *param)
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
        RdosStopNetCapture();

        if (CaptureHandle)
        {
            RdosCloseFile(CaptureHandle);
            CaptureHandle = 0;
        }
            
		FMsg.Load(TEXT_CAPTURE_OFF);
        return 0;        
    }

    if (strcmp(str, "on"))
        CaptureFileName = FArgList->FName;
    
    if (CaptureHandle)
    {
        RdosStopNetCapture();
        RdosCloseFile(CaptureHandle);
        CaptureHandle = 0;
    }

    file = CaptureFileName.GetData();
    CaptureHandle = RdosOpenFile(file, 0);
    if (!CaptureHandle)
        CaptureHandle = RdosCreateFile(file, 0);
        
    if (CaptureHandle)
    {
		  RdosStartNetCapture(CaptureHandle);
		FMsg.printf(TEXT_CAPTURE_ON, file);
        return 0;        
    }
    else
    {
		 FMsg.Load(TEXT_ERROR_FILE_NOT_FOUND);
		 Write(FMsg.GetData());
		 return E_Useage;
    }
}
