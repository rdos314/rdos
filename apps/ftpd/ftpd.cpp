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
#include "ftpfact.h"

#define FALSE 0
#define TRUE !FALSE

// this one must be globally defined!

TFtpSocketServerFactory Factory;

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	Factory.AddUser("c-drive", "rdos", "c:\\");
	Factory.AddUser("d-drive", "rdos", "d:\\");
	Factory.AddUser("e-drive", "rdos", "e:\\");
	Factory.AddUser("f-drive", "rdos", "f:\\");
	Factory.AddUser("g-drive", "rdos", "g:\\");
	Factory.AddUser("h-drive", "rdos", "h\\");
	Factory.AddUser("i-drive", "rdos", "i:\\");
	Factory.AddUser("j-drive", "rdos", "j:\\");
	Factory.AddUser("k-drive", "rdos", "k:\\");
	Factory.AddUser("l-drive", "rdos", "l:\\");
	Factory.AddUser("m-drive", "rdos", "m:\\");
	Factory.AddUser("n-drive", "rdos", "n:\\");
	Factory.AddUser("z-drive", "rdos", "z:\\");
	TSocket::Listen(&Factory, 21, 0x4000);
}

