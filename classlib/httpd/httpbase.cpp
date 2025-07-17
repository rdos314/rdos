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
