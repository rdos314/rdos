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
#   Name       : TGdbRemoteSocketServer::SendPacket
#
#   Purpose....: Send a packet
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::SendPacket(const char *msg)
{
    int count;
    int i;
    char Buf[513];
    char *ptr;
    char crc;
    char crcstr[6];
    int val;

    if (OnCommand)
        (*OnCommand)(this, msg);

    ptr = Buf;
    *ptr = '$';
    ptr++;

    crc = 0;
    count = strlen(msg);
    
    for (i = 0; i < count; i++)
    {
        *ptr = msg[i];
        crc += *ptr;
        ptr++;
    }        

    *ptr = '#';
    ptr++;

    sprintf(crcstr, "%04hX", (int)((unsigned char)crc));
    count = strlen(crcstr);

    *ptr = crcstr[count - 2];
    ptr++;
    *ptr = crcstr[count - 1];
    ptr++;
    *ptr = 0;

    FSocket->Write(Buf);
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::SetThread
#
#   Purpose....: Set current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::SetThread(const char *msg)
{
    SendPacket("OK");
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::SendPid
#
#   Purpose....: Send current PID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::SendPid()
{
    SendPacket("QC12345678");
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::SendOffsets
#
#   Purpose....: Send offsets
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::SendOffsets()
{
    SendPacket("Text=0;Data=0;Bss=0");
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::SendReason
#
#   Purpose....: Send reason code
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::SendReason()
{
    SendPacket("T03");
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::Query
#
#   Purpose....: Handle query packet
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::Query(const char *msg)
{
	if (!strcmp(msg, "C"))
    {
        SendPid();
        return;
    }

    if (!strcmp(msg, "Offsets"))
    {
        SendOffsets();
        return;
    }
        
    SendPacket("");
}

/*##########################################################################
#
#   Name       : TGdbRemoteSocketServer::HandlePacket
#
#   Purpose....: Handle received packet
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TGdbRemoteSocketServer::HandlePacket(const char *msg)
{
    switch (*msg)
    {
        case 'H':
            SetThread(msg+1);
            break;

        case 'q':
            Query(msg+1);
            break;

        case '?':
            SendReason();
            break;

        default:
            SendPacket("");
            break;
    }
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
	char *ptr;
	char *cmdptr;
	char *crcptr;
	char crc;
	int val;
	char msgcrc;
	int i;

	while (FSocket->IsOpen())
	{
		count = FSocket->Read(Buf, 512);
               
		if (count == 0)
			break;

		Buf[count] = 0;

		ptr = Buf;

        while (*ptr)
        {
    		while (*ptr && *ptr != '$')
	    	    ptr++;

	    	if (*ptr)
	    	    ptr++;

    		cmdptr = ptr;
	    	crc = 0;

            while (*ptr && *ptr != '#')
            {
                crc += *ptr;
                ptr++;
            }

            if (*ptr)
                ptr++;

            crcptr = ptr;        

			for (i = 0; i < 2 && *ptr; i++)
				ptr++;

            if (i == 2)
            {
                sscanf(crcptr, "%02hX", &val);

                msgcrc = (char)val;

                if (msgcrc == crc)
                {
                    *(crcptr - 1) = 0;
                    if (OnCommand)
                        (*OnCommand)(this, cmdptr);

                    FSocket->Write('+');

                    HandlePacket(cmdptr);
                }
            }
        }
	}
}

