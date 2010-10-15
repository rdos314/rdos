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
# wdasync.cpp
# WD async supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdasync.h"
#include "wdmsg.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdAsyncFactory::TWdAsyncFactory
#
#   Purpose....: Supplementary async factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncFactory::TWdAsyncFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Asynch")
{
}

/*##########################################################################
#
#   Name       : TWdAsyncFactory::~TWdAsyncFactory
#
#   Purpose....: Supplementary async factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncFactory::~TWdAsyncFactory()
{
}

/*##########################################################################
#
#   Name       : TWdAsyncFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdAsyncFactory::Create(TWdSocketServer *server)
{
    return new TWdAsyncService(server);
}

/*##########################################################################
#
#   Name       : TWdAsyncService::TWdAsyncService
#
#   Purpose....: Supplementary thread service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncService::TWdAsyncService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdAsyncService::~TWdAsyncService
#
#   Purpose....: Supplementary thread service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncService::~TWdAsyncService()
{
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqError()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdAsyncService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {

        default:
            ReqError();
            break;
    }
}
