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
# gremserv.cpp
# GDB remote socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "socket.h"
#include "gremserv.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::TGdbRemoteSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGdbRemoteSocketServer::TGdbRemoteSocketServer(const char *Name, int StackSize, TSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
	OnCommand = 0;
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::~TGdbRemoteSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TGdbRemoteSocketServer::~TGdbRemoteSocketServer()
{
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::HandleSocket()
{
	int count;
	char Buf[513];

	while (FSocket->IsOpen())
	{
		count = FSocket->Read(Buf, 512);
		Buf[count] = 0;

		if (count == 0)
			break;

        if (OnCommand)
            (*OnCommand)(this, Buf);

	}
}

