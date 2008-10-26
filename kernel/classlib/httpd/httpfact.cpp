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
# httpfact.cpp
# HTTP Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "httpserv.h"
#include "httpcmd.h"
#include "httpfact.h"
#include "httpcust.h"

#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::THttpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpSocketServerFactory::THttpSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
	Init();
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::~THttpSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpSocketServerFactory::~THttpSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServerFactory::Init()
{
    OnCommand = 0;
    KeepAlive = 15;
    FPageList = 0;
    FDirList = 0;
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::AddCustomPage
#
#   Purpose....: Add a custom page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServerFactory::AddCustomPage(THttpCustomPageFactory *page)
{
	THttpCustomPageFactory *curr;

    page->FList = 0;
	curr = FPageList;
   
	if (curr)
	{
		while (curr->FList)
			curr = curr->FList;

		curr->FList = page;
	}
	else
		FPageList = page;    
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::AddCustomDir
#
#   Purpose....: Add a custom directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServerFactory::AddCustomDir(THttpCustomDirFactory *dir)
{
	THttpCustomDirFactory *curr;

    dir->FList = 0;
	curr = FDirList;
   
	if (curr)
	{
		while (curr->FList)
			curr = curr->FList;

		curr->FList = dir;
	}
	else
		FDirList = dir;    
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *THttpSocketServerFactory::Create(TSocket *Socket)
{
	THttpSocketServer *server;

	server = new THttpSocketServer("HTTP", 0x2000, Socket);
	server->OnCommand = OnCommand;
	server->RootDir = RootDir;
	server->KeepAlive = KeepAlive;
	server->FPageList = FPageList;
	server->FDirList = FDirList;

	return server;
}
