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
# telnserv.cpp
# TELNET socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "sockobj.h"
#include "telnserv.h"

#define FALSE 0
#define TRUE !FALSE

#define BUF_SIZE    0x1000

/*##########################################################################
#
#   Name       : TTelnetSocketServer::TTelnetSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTelnetSocketServer::TTelnetSocketServer(const char *Name, int StackSize, TTcpSocket *Socket, int IpcHandle)
  : TSocketServer(Name, StackSize, Socket)
{
    FIpcHandle = IpcHandle;
    OnCommand = 0;
}

/*##########################################################################
#
#   Name       : TTelnetSocketServer::~TTelnetSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTelnetSocketServer::~TTelnetSocketServer()
{
}

/*##########################################################################
#
#   Name       : TTelnetSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTelnetSocketServer::HandleSocket()
{
    char *Buf = new char[BUF_SIZE];
    char *Msg = new char[128 + BUF_SIZE];
    char *ReplyBuf = new char[BUF_SIZE];
    int count;
    int InPos;
    int OutPos;
    
    if (FSocket->WaitForConnection(6000))
    {
        if (FSocket->WaitForData(250))
            count = FSocket->Read(Buf, BUF_SIZE);

        while (FSocket->IsOpen())
        {
            OutPos = 0;
            if (FSocket->WaitForData(50))
            {
                count = FSocket->Read(Buf, BUF_SIZE);

                for (InPos = 0; InPos < count; InPos++)
                {
                    Msg[OutPos] = Buf[InPos];
                    OutPos++;
                }
                Msg[OutPos] = 0;

                if (OnCommand)
                    (OnCommand)(this, Msg);
            }
            else
                count = 0;

            count = RdosSendMailslot(FIpcHandle, Msg, OutPos, ReplyBuf, BUF_SIZE);

            if (count)
            {
                FSocket->Write(ReplyBuf, count);
                FSocket->Push();
            }
                
        }
    }

    Msg[0] = 0;
    RdosSendMailslot(FIpcHandle, Msg, 1, ReplyBuf, BUF_SIZE);

    delete Buf;
    delete ReplyBuf;
}
