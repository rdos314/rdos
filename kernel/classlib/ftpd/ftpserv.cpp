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
# ftpserv.cpp
# FTP socket server class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "socket.h"
#include "ftpserv.h"
#include "langstr.h"
#include "cmd.h"
#include "cmdfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpSocketServer::TFtpSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::TFtpSocketServer()
{
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"FTP",MaxLen);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::HandleSocket()
{
	int Major;
	int Minor;
	int Release;
	TLangString msg;
	TCommand *cmd;

	int count;
	char Buf[513];

	if (FSocket->WaitForConnection(6000))
	{

		RdosGetVersion(&Major, &Minor, &Release);
		msg.printf(220, Major, Minor, Release);
		msg.Write(FSocket);

		count = FSocket->Read(Buf, 512);
		Buf[count] = 0;
		printf(Buf);

        cmd = TCommandFactory::Parse(Buf);

        if (cmd)
            cmd->Run();
        else
        {
    		msg.Load(502);
	    	msg.Write(FSocket);
	    }
	}
}
