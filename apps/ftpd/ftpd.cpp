/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# ftpd.cpp
# FTP server application for RDOS
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "rdos.h"
#include "socket.h"

#define FALSE 0
#define TRUE !FALSE

class TFtpSocketServerFactory : public TSocketServerFactory
{
public:
    virtual char *GetThreadName();
    virtual int GetStackSize();    
	virtual TSocketServer *Create();
};

class TFtpSocketServer : public TSocketServer
{
public:
	TFtpSocketServer();
	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual void HandleSocket();
};

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetThreadName
#
#   Purpose....: Return thread name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFtpSocketServerFactory::GetThreadName()
{
	return "FTP";
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetStackSize
#
#   Purpose....: Return thread stack size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServerFactory::GetStackSize()
{
	return 0x2000;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TFtpSocketServerFactory::Create()
{
	return new TFtpSocketServer;
}

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
	char VersionStr[16];
	int Major;
	int Minor;
	int Release;
	
	int count;
	char Buf[513];

	if (FSocket->WaitForConnection(6000))
	{

    	RdosGetVersion(&Major, &Minor, &Release);
	    sprintf(VersionStr, "%d.%d.%d", Major, Minor, Release);

    	FSocket->Write("220 FTP for RDOS ");
	    FSocket->Write(VersionStr);
    	FSocket->Write(0xd);
	    FSocket->Write(0xa);
    	FSocket->Push();
    	
		count = FSocket->Read(Buf, 512);
		Buf[count] = 0;
		printf(Buf);

		FSocket->Write("500 Syntax error, command unrecognized.");
		FSocket->Write("This may include errors such as command line");
		FSocket->Write("too long.");
		FSocket->Write(0xd);
		FSocket->Write(0xa);
		FSocket->Push();
	}
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/

TFtpSocketServerFactory Factory;

void cdecl main()
{
	TSocket::Listen(&Factory, 21, 0x4000);
}

