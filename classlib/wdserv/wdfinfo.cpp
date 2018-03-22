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
# wdfinfo.cpp
# WD file info supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdfinfo.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::TWdFileInfoFactory
#
#   Purpose....: Supplementary file info factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoFactory::TWdFileInfoFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "FileInfo")
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::~TWdFileInfoFactory
#
#   Purpose....: Supplementary file info factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoFactory::~TWdFileInfoFactory()
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdFileInfoFactory::Create(TWdSocketServer *server)
{
    return new TWdFileInfoService(server);
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::TWdFileInfoService
#
#   Purpose....: Supplementary file info service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoService::TWdFileInfoService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::~TWdFileInfoService
#
#   Purpose....: Supplementary file info service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdFileInfoService::~TWdFileInfoService()
{
}

/*##########################################################################
#
#   Name       : TWdFileInfoService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdFileInfoService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    _asm int 3
}
