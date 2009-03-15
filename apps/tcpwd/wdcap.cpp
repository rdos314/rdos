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
# wdcap.cpp
# WD capabilities supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdcap.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdCapFactory::TWdCapFactory
#
#   Purpose....: Supplementary capabilities factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapFactory::TWdCapFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Capabilities")
{
}

/*##########################################################################
#
#   Name       : TWdCapFactory::~TWdCapFactory
#
#   Purpose....: Supplementary capabilities factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapFactory::~TWdCapFactory()
{
}

/*##########################################################################
#
#   Name       : TWdCapFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdCapFactory::Create(TWdSocketServer *server)
{
    return new TWdCapService(server);
}

/*##########################################################################
#
#   Name       : TWdCapService::TWdCapService
#
#   Purpose....: Supplementary capabilities service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapService::TWdCapService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdCapService::~TWdCapService
#
#   Purpose....: Supplementary capabilities service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdCapService::~TWdCapService()
{
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqGetBp
#
#   Purpose....: Get 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqGetBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqSetBp
#
#   Purpose....: Set 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqSetBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqExactBp
#
#   Purpose....: Get exact 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqExactBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::ReqSetExactBp
#
#   Purpose....: Set exact 8 byte breakpoints
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::ReqSetExactBp()
{
    PutDword(0);
    PutDword(1);
}

/*##########################################################################
#
#   Name       : TWdCapService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdCapService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqGetBp();
            break;

        case 1:
            ReqSetBp();
            break;

        case 2:
            ReqExactBp();
            break;

        case 3:
            ReqSetExactBp();
            break;
    }

}
