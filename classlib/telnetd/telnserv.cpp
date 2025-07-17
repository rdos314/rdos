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
