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
TCommand *TPingFactory::Create(const char *param)
{
	return new TPingCommand(param);
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
TPingCommand::TPingCommand(const char *param)
  : TCommand(param)
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

