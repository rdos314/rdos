/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# ftpd.cpp
# FTP server application for RDOS
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "rdos.h"
#include "socket.h"
#include "langstr.h"
#include "ftpserv.h"
#include "user.h"
#include "pass.h"

#define FALSE 0
#define TRUE !FALSE

class TFtpSocketServerFactory : public TSocketServerFactory
{
public:
	virtual char *GetThreadName();
	virtual int GetStackSize();
	virtual TSocketServer *Create();
};

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetThreadName
#
#   Purpose....: Return thread name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFtpSocketServerFactory::GetThreadName()
{
	return "FTP";
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetStackSize
#
#   Purpose....: Return thread stack size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServerFactory::GetStackSize()
{
	return 0x2000;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TFtpSocketServerFactory::Create()
{
	return new TFtpSocketServer;
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/

TFtpSocketServerFactory Factory;

void cdecl main()
{
    TUserFactory *user = new TUserFactory;
    TPassFactory *pass = new TPassFactory;
    
	TSocket::Listen(&Factory, 21, 0x4000);
}

