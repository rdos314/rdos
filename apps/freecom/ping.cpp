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
# ping.cpp
# Ping command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "ping.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPingFactory::TPingFactory
#
#   Purpose....: Constructor for TPingFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPingFactory::TPingFactory()
  : TCommandFactory("PING")
{
}

/*##########################################################################
#
#   Name       : TPingFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPingFactory::Create(TSession *session, const char *param)
{
	return new TPingCommand(session, param);
}

/*##########################################################################
#
#   Name       : TPingCommand::TPingCommand
#
#   Purpose....: Constructor for TPingCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPingCommand::TPingCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_PING);
}

/*##########################################################################
#
#   Name       : TPingCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPingCommand::Execute(char *param)
{
	const char *NodeName;
	int n0,n1,n2,n3;
	long Node;
	unsigned long Temp;
	int i;

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgCount != 1)
	{
		FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		Write(FMsg.GetData());
		return E_Useage;
	}

	NodeName = FArgList->FName.GetData();

	if (isdigit(NodeName[0]))
	{
		if (sscanf(NodeName, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
			Node = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
		else
		{
			Node = 0;
    		FMsg.Load(TEXT_ERROR_INVALID_IP);
    		Write(FMsg.GetData());
    		return 0;
		}
	}
	else
	{
		Node = RdosNameToIp(NodeName);
		if (Node == 0)
		{
			FMsg.Load(TEXT_ERROR_INVALID_HOSTNAME);
			Write(FMsg.GetData());
			return 0;
		}
	}

	if (Node)
	{
		Temp = (unsigned long)Node;
		n3 = Temp & 0xFF;
		Temp = Temp >> 8;
		n2 = Temp & 0xFF;
		Temp = Temp >> 8;
		n1 = Temp & 0xFF;
		Temp = Temp >> 8;
		n0 = Temp & 0xFF;
		FMsg.printf(TEXT_PING_NODE, n3, n2, n1, n0);
		Write(FMsg.GetData());

		for (i = 0; i < 10; i++)
		{
			if (RdosPing(Node, 2000))
			{
				FMsg.Load(TEXT_PING_OK);
				Write(FMsg.GetData());
			}
			else
			{
				FMsg.Load(TEXT_PING_TIMEOUT);
				Write(FMsg.GetData());
			}
		}
		return 0;
    }
	return 1;
}

