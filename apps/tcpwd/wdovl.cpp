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
# wdovl.cpp
# WD overlay supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdovl.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TWdOverlayFactory::TWdOverlayFactory
#
#   Purpose....: Supplementary overlay factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdOverlayFactory::TWdOverlayFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Overlays")
{
}

/*##########################################################################
#
#   Name       : TWdOverlayFactory::~TWdOverlayFactory
#
#   Purpose....: Supplementary overlay factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdOverlayFactory::~TWdOverlayFactory()
{
}

/*##########################################################################
#
#   Name       : TWdOverlayFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdOverlayFactory::Create(TWdSocketServer *server)
{
    return new TWdOverlayService(server);
}

/*##########################################################################
#
#   Name       : TWdOverlayService::TWdOverlayService
#
#   Purpose....: Supplementary overlay service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdOverlayService::TWdOverlayService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdOverlayService::~TWdOverlayService
#
#   Purpose....: Supplementary overlay service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdOverlayService::~TWdOverlayService()
{
}

/*##########################################################################
#
#   Name       : TWdOverlayService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdOverlayService::NotifyMsg()
{
    char ch;

    ch = GetByte();

}
