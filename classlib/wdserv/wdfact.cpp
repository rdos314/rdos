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
