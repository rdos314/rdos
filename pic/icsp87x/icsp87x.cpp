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
# icsp87x.cpp
# ICSP programming of Microship's PIC16F87x. Requires a device-driver that
# implements the ICSP related functions
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "file.h"

#define FALSE	0
#define	TRUE	!FALSE

/*##########################################################################
#
#   Name       : DoICSP
#
#   Purpose....: Do ICSP programming
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DoICSP(int handle, TFile &file)
{
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Entry point
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main(int argc, char **argv)
{
    char DeviceStr[256];
	char FileName[256];
	int id;
	int handle;

	if (argc != 3)
	{
		printf("usage: icsp87x device-id hex-filename\r\n");
		return 1;
	}

	RdosWaitMilli(250);

	strcpy(DeviceStr, argv[1]);

	strcpy(FileName, argv[2]);
	strlwr(FileName);

	TFile file(FileName);

	if (file.IsOpen())
	{
    	id = atoi(DeviceStr);

    	if (id > 0)
	        handle = RdosOpenICSP(id);
    	else
	        handle = 0;

    	if (handle)
	    {
    	    DoICSP(handle, file);
    	    RdosCloseICSP(handle);
	    }
    	else
	    	printf("Invalid device-id or no ICSP available\r\n");
    }
    else
        printf("File not found\r\n");

	return 0;
}
