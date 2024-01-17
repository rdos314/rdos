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
# httpbase.cpp
# HTTP factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "httpserv.h"
#include "httpcmd.h"
#include "httpbase.h"
#include "httpcust.h"

#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : THttpServerFactory::THttpServerFactory
#
#   Purpose....: Server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpServerFactory::THttpServerFactory()
{
    OnCommand = 0;
    OnAuthorize = 0;
    KeepAlive = 15;
    FPageList = 0;
    FDirList = 0;
}

/*##########################################################################
#
#   Name       : THttpServerFactory::~THttpServerFactory
#
#   Purpose....: Server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpServerFactory::~THttpServerFactory()
{
}

/*##########################################################################
#
#   Name       : THttpServerFactory::AddCustomPage
#
#   Purpose....: Add a custom page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpServerFactory::AddCustomPage(THttpCustomPageFactory *page)
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
#   Name       : THttpServerFactory::AddCustomDir
#
#   Purpose....: Add a custom directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpServerFactory::AddCustomDir(THttpCustomDirFactory *dir)
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
#   Name       : THttpServerFactory::LinkServer
#
#   Purpose....: Setup server links
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpServerFactory::LinkServer(THttpSocketServer *server)
{
    server->OnCommand = OnCommand;
    server->OnAuthorize = OnAuthorize;
    server->RootDir = RootDir;
    server->KeepAlive = KeepAlive;
    server->FPageList = FPageList;
    server->FDirList = FDirList;
}
