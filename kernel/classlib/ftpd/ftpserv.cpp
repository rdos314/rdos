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
	CurrDir = "/";
	FDataSocket = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::~TFtpSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::~TFtpSocketServer()
{
    if (FDataSocket)
        delete FDataSocket;
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
#   Name       : TFtpSocketServer::Reply
#
#   Purpose....: Reply to socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Reply(TLangString *msg)
{
    msg->Write(FSocket);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::VerifyUser
#
#   Purpose....: Verify a valid user is logged in
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::VerifyUser()
{
    if (User == "leif" && Pass == "vals")
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::OpenDataConnection
#
#   Purpose....: Open data connection to client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::OpenDataConnection(long IP, int port)
{
	if (IP == FSocket->GetRemoteIP())
	{
        if (FDataSocket)
            delete FDataSocket;
            
	    FDataSocket = new TSocket(FWait, IP, port, 6000, 0x2000);
	    
	    if (FDataSocket->WaitForConnection(6000))
        	return TRUE;
        else
        {
            delete FDataSocket;
            FDataSocket = 0;
        }
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::ListenForDataConnection
#
#   Purpose....: Listen for data connection from client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::ListenForDataConnection(long *IP, int *port)
{
	*IP == FSocket->GetRemoteIP();

    if (FDataSocket)
        delete FDataSocket;
            
	FDataSocket = new TSocket(FWait, FSocket->GetRemoteIP(), 0, 6000, 0x2000);
	*port = FDataSocket->GetLocalPort();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write character to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FDataSocket)
		FDataSocket->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write string to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(const char *str)
{
	int size = strlen(str);

	if (FDataSocket)
		FDataSocket->Write(str, size);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::WriteLong
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::WriteLong(long value)
{
	char str[4];
	int tmp;
	int use = FALSE;

	tmp = value / 1000000000;
	if (tmp)
	{
		use = TRUE;
		sprintf(str, "%2d", tmp);
	}
	else
		strcpy(str, "  ");
	Write(str);
	Write(" ");
	value = value % 1000000000;

	tmp = value / 1000000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000000;

	tmp = value / 1000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000;

	tmp = value;
	if (use)
		sprintf(str, "%03d", tmp);
	else
		sprintf(str, "%3d", tmp);
	Write(str);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Push
#
#   Purpose....: Push data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Push()
{
	if (FDataSocket)
		FDataSocket->Push();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Quit
#
#   Purpose....: Quit session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Quit()
{
    FSocket->Close();
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

		while (FSocket->IsOpen())
		{
			count = FSocket->Read(Buf, 512);
			Buf[count] = 0;

			if (count == 0)
				break;

			printf(Buf);

			cmd = TCommandFactory::Parse(this, Buf);

			if (cmd)
				cmd->Run();
			else
			{
				msg.Load(502);
				msg.Write(FSocket);
			}
		}
	}
}
