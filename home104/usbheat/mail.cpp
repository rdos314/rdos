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
TMailServerFactory::TMailServerFactory(int MaxConnections, int BufferSize)
  : TSocketServerFactory(25, MaxConnections, BufferSize)
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
    TSocketServer *server = new TMailServer("Mail socket", 0x10000, Socket);
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
TMailServer::TMailServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
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
static void MailSocketThread(void *ptr)
{
    TMailServerFactory fact(10, BUF_SIZE);

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
void InitMail()
{
    RdosCreateThread(MailSocketThread, "Mail listner", 0, STACK_SIZE);
}
