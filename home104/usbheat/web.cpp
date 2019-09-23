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
# web.h
# Heat web server class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "web.h"

#define BUF_SIZE	0x4000
#define STACK_SIZE      0x4000

/*##########################################################################
#
#   Name       : THeatHttpServerFactory::THeatHttpServerFactory
#
#   Purpose....: server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServerFactory::THeatHttpServerFactory(int Port, int MaxConnections, int BufferSize)
  : THttpSocketServerFactory(Port, MaxConnections, BufferSize)
{
}

/*##########################################################################
#
#   Name       : THeatHttpServerFactory::~THeatHttpServerFactory
#
#   Purpose....: Heat server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServerFactory::~THeatHttpServerFactory()
{
}

/*##########################################################################
#
#   Name       : THeatHttpServerFactory::Create
#
#   Purpose....: Create socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *THeatHttpServerFactory::Create(TTcpSocket *Socket)
{
    THttpSocketServer *server = new THeatHttpServer("Web socket", 0x10000, Socket);
    LinkServer(server);
    return server;
}

/*##########################################################################
#
#   Name       : THeatHttpServer::THeatHttpServer
#
#   Purpose....: server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServer::THeatHttpServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : THttpSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : THeatHttpServer::~THeatHttpServer
#
#   Purpose....: Heat server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatHttpServer::~THeatHttpServer()
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::THeatJsonDirFactory
#
#   Purpose....: JSON factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonDirFactory::THeatJsonDirFactory(const char *ReqName)
  : THttpCustomDirFactory(ReqName)
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::~THeatJsonDirFactory
#
#   Purpose....: JSON factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonDirFactory::~THeatJsonDirFactory()
{
}

/*##########################################################################
#
#   Name       : THeatJsonDirFactory::Create
#
#   Purpose....: Create JSON page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *THeatJsonDirFactory::Create(THttpCommand *cmd)
{
    return new THeatJsonPage(cmd);
}

/*##########################################################################
#
#   Name       : THeatJsonPage::THeatJsonPage
#
#   Purpose....: JSON page constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonPage::THeatJsonPage(THttpCommand *Cmd)
  : THttpCustomPage(Cmd)
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::~THeatJsonPage
#
#   Purpose....: JSON page destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THeatJsonPage::~THeatJsonPage()
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Get(const char *MatchName, const char *UrlName, THttpParam *Param)
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Post(const char *MatchName, const char *UrlName, THttpParam *Param)
{
}

/*##########################################################################
#
#   Name       : THeatJsonPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THeatJsonPage::Post(const char *Var, const char *Val)
{
}

/*##########################################################################
#
#   Name       : WebSocketThread
#
#   Purpose....: Web socket thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void WebSocketThread(void *ptr)
{
    THeatHttpServerFactory fact(80, 10, BUF_SIZE);
    THeatJsonDirFactory dir("json");
    fact.AddCustomDir(&dir);

    for (;;)
        fact.WaitForever();
}

/*##########################################################################
#
#   Name       : InitWeb
#
#   Purpose....: Init web
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitWeb()
{
    RdosCreateThread(WebSocketThread, "Web listner", 0, STACK_SIZE);
}
