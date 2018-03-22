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
# wdfact.cpp
# WD factory class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "wdserv.h"
#include "wdfact.h"
#include "wdsuppl.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : OnMsg
#
#   Purpose....: Notification of message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void OnMsg(TWdSocketServer *serv, const char *msg)
{
    ((TWdSocketServerFactory *)(serv->Owner))->LogMsg(msg);
}

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::TWdSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServerFactory::TWdSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    FSupplList = 0;
    OnMsg = 0;
}

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::~TWdSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSocketServerFactory::~TWdSocketServerFactory()
{
    TWdSupplFactory *fact;

    while (FSupplList)
    {
        fact = FSupplList->FNext;
        delete FSupplList;
        FSupplList = fact;
    }
}        

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::LogMsg
#
#   Purpose....: Log message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServerFactory::LogMsg(const char *msg)
{
    if (OnMsg)
        (*OnMsg)(this, msg);
}

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::AddSuppl
#
#   Purpose....: Add supplementary service factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdSocketServerFactory::AddSuppl(TWdSupplFactory *SupplService)
{
    SupplService->FNext = FSupplList;
    FSupplList = SupplService;
}

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::GetSuppl
#
#   Purpose....: Get supplementary service factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplFactory *TWdSocketServerFactory::GetSuppl(const char *name)
{
    int done;
    TWdSupplFactory *fact;

    fact = FSupplList;
    done = FALSE;

    while (fact && !done)
    {
        if (strcmpi(fact->FName, name) == 0)
            done = TRUE;
        else
            fact = fact->FNext;
    }

    return fact;
}

/*##########################################################################
#
#   Name       : TWdSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TWdSocketServerFactory::Create(TTcpSocket *Socket)
{
    TWdSocketServer *server;
    server = new TWdSocketServer(this, "WD", 0x7000, Socket);
    server->OnMsg = ::OnMsg;
    server->Owner = this;

    return server;
}
