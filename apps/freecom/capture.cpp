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
		Write(FMsg.GetData());
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
