/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# mail.h
# Mail server class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "mail.h"

#define BUF_SIZE        0x4000
#define STACK_SIZE      0x4000
#define SOCK_BUF_SIZE      513

static TSocketServerFactory *sockfact = 0;

/*##########################################################################
#
#   Name       : GetMailConnectionCount
#
#   Purpose....: Get mail connection count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetMailConnectionCount()
{
    if (sockfact)
        return sockfact->GetConnectionCount();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TMailServerFactory::TMailServerFactory
#
#   Purpose....: server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMailServerFactory::TMailServerFactory(int MaxConnections, int BufferSize, const char *Host)
  : TSocketServerFactory(25, MaxConnections, BufferSize),
    FHost(Host)
{
}

/*##########################################################################
#
#   Name       : TMailServerFactory::~TMailServerFactory
#
#   Purpose....: Mail server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMailServerFactory::~TMailServerFactory()
{
}

/*##########################################################################
#
#   Name       : TMailServerFactory::Create
#
#   Purpose....: Create socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TMailServerFactory::Create(TTcpSocket *Socket)
{
    TSocketServer *server = new TMailServer("Mail socket", 0x10000, Socket, FHost);
    return server;
}

/*##########################################################################
#
#   Name       : TMailServer::TMailServer
#
#   Purpose....: server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMailServer::TMailServer(const char *Name, int StackSize, TTcpSocket *Socket, TString &Host)
  : TSocketServer(Name, StackSize, Socket),
    FLog("Mail"),
    FHost(Host)
{
}

/*##########################################################################
#
#   Name       : TMailServer::~TMailServer
#
#   Purpose....: Mail server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMailServer::~TMailServer()
{
}

/*##########################################################################
#
#   Name       : TMailServer::Reply
#
#   Purpose....: Reply
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMailServer::Reply(int Id, const char *Text)
{
    char str[10];

    sprintf(str, "%03d ", Id);

    FSocket->Write(str);
    FSocket->Write(Text);
    
    str[0] = 0xd;
    str[1] = 0xa;
    str[2] = 0;
    FSocket->Write(str);

    FSocket->Push();
}

/*##########################################################################
#
#   Name       : TMailServer::IsOpen
#
#   Purpose....: Check if data socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TMailServer::IsOpen()
{
    return FSocket && FSocket->IsOpen();
}

/*##########################################################################
#
#   Name       : TMailServer::IsEmpty
#
#   Purpose....: Check if data socket is empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TMailServer::IsEmpty()
{
    if (FBufCount == FBufPos)
    {
        if (FSocket->GetSize() == 0)
            return true;
        else
            return false;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TMailServer::ReadLine
#
#   Purpose....: Read a single line from socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TMailServer::ReadLine()
{
    char *ptr;
    char *result;
    int pos;

    if (FSocketBuf == 0)
    {
        FSocketBuf = new char[SOCK_BUF_SIZE + 1];
        FBufCount = 0;
        FBufPos = 0;
    }

    if (FBufCount <= FBufPos)
    {
        FBufPos -= FBufCount;

        if (FSocket->WaitForData(5000))
        {
            FBufCount = FSocket->Read(FSocketBuf, SOCK_BUF_SIZE);
            FSocketBuf[FBufCount] = 0;
        }
        else
            return 0;
    }

    ptr = strchr(&FSocketBuf[FBufPos], 0xd);

    while (!ptr)
    {
        if (FBufPos == 0)
        {
            FBufCount = 0;
            return 0;
        }

        if (!FSocket->WaitForData(5000))
        {
            result = &FSocketBuf[FBufPos];
            FBufPos = 0;
            FBufCount = 0;
            return result;
        }

        memcpy(FSocketBuf, &FSocketBuf[FBufPos], FBufCount - FBufPos);
        FBufCount -= FBufPos;
        FBufPos = 0;
        pos = FBufCount;
        FBufCount += FSocket->Read(&FSocketBuf[pos], BUF_SIZE - FBufCount);
        FSocketBuf[FBufCount] = 0;

        ptr = strchr(&FSocketBuf[pos], 0xd);
    }

    *ptr = 0;
    result = &FSocketBuf[FBufPos];
    FBufPos = ptr - FSocketBuf + 2;

    return result;
}

/*##########################################################################
#
#   Name       : TMailServer::HandleData
#
#   Purpose....: Handle message data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMailServer::HandleData()
{
    char *ptr;
    bool ok = false;

    ptr = ReadLine();
    while (ptr)
    {
        if (!strcmp(ptr, "."))
        {
            Reply(250, "OK");
            ok = true;
            break;
        }
        else
        {
            FLog.Log(0, "Data", ptr);
            ptr = ReadLine();
        }
    }

    if (!ok)
        Reply(502, "No end");
}

/*##########################################################################
#
#   Name       : TMailServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMailServer::HandleSocket()
{
    char *ptr;
    bool handled;
    char cmd[5];
    TString rp;

    Reply(220, FHost.GetData());

    while (FSocket->IsOpen() || !IsEmpty())
    {
        ptr = ReadLine();
        if (ptr)
        {
            FLog.Log(0, "Mail", ptr);

            handled = false;

            if (strlen(ptr) >= 4 && ptr[4] == ' ')
            {
                strncpy(cmd, ptr, 4);
                cmd[4] = 0;

                if (!strcmp(cmd, "HELO"))
                {
                    FClient = ptr + 5;
                    rp = FHost + " RDOS Mailserver"; 
                    Reply(250, rp.GetData());
                    handled = true;
                }

                if (!strcmp(cmd, "EHLO"))
                {
                    FClient = ptr + 5;
                    rp = FHost + " RDOS Mailserver"; 
                    Reply(250, rp.GetData());
                    handled = true;
                }

                if (!strcmp(cmd, "QUIT"))
                {
                    Reply(221, "Quiting");
                    handled = true;
                    break;
                }

                if (!strcmp(cmd, "MAIL"))
                {
                    FSource = ptr + 5;
                    Reply(250, "OK");
                    handled = true;
                }

                if (!strcmp(cmd, "RCPT"))
                {
                    FDest = ptr + 5;
                    Reply(250, "OK");
                    handled = true;
                }

                if (!strcmp(cmd, "DATA"))
                {
                    Reply(354, "OK");
                    handled = true;
                    HandleData();
                }
            }

            if (!handled)
                Reply(502, "Not supported");

        }
        else
            break;
    }
}

/*##########################################################################
#
#   Name       : MailSocketThread
#
#   Purpose....: Mail socket thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void MailSocketThread(void *Param)
{
    char *Host = (char *)Param;

    TMailServerFactory fact(10, BUF_SIZE, Host);

    delete Host;

    sockfact = &fact;

    for (;;)
        fact.WaitForever();
}

/*##########################################################################
#
#   Name       : InitMail
#
#   Purpose....: Init mail
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitMail(const char *Host)
{
    int len = strlen(Host);
    char *HostName = new char[len+1];

    strcpy(HostName, Host);

    RdosCreateThread(MailSocketThread, "Mail listner", HostName, STACK_SIZE);
}
