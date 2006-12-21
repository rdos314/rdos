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
# userkey.cpp
# User-mode keyboard class
#
########################################################################*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "userkey.h"

#define	FALSE		0
#define	TRUE		1

#define	BUFFER_SIZE	64
#define BUFFER_POLL_INTERVALL	10

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::TUserKeyboardDevice
#
#   Purpose....: Constructor for user-mode keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserKeyboardDevice::TUserKeyboardDevice(const char *IniSection, int Enabled)
	: TKeyboardDevice(IniSection)
{
	FCurrentSize = 0;
	FBuffer = (int *)new char[2 * BUFFER_SIZE];
	FInPtr = FBuffer;
	FOutPtr = FBuffer;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::TUserKeyboardDevice
#
#   Purpose....: Constructor for user-mode keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserKeyboardDevice::TUserKeyboardDevice(int Enabled)
{
	FCurrentSize = 0;
	FBuffer = (int *)new char[2 * BUFFER_SIZE];
	FInPtr = FBuffer;
	FOutPtr = FBuffer;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::~TUserKeyboardDevice
#
#   Purpose....: Destructor for user-mode keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUserKeyboardDevice::~TUserKeyboardDevice()
{
	delete FBuffer;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Put
#
#   Purpose....: Put on character in buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUserKeyboardDevice::Put(int ch)
{
	int Done = FALSE;

	if (KeyPreview != 0)
		Done = (*KeyPreview)(this, ch);

	if (!Done && BUFFER_SIZE > FCurrentSize)			/* Check if space is available. */
		if (FInPtr)
		{
			*FInPtr = ch;
			if (++FInPtr >= FBuffer + BUFFER_SIZE)
				FInPtr = FBuffer;
			FCurrentSize++;
		}
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Put
#
#   Purpose....: Poll keyboard buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUserKeyboardDevice::Poll() const
{
	if (FCurrentSize)
		return *FOutPtr;
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Get
#
#   Purpose....: Get one character from buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUserKeyboardDevice::Get()
{
	int 	ch = 0;

	if (FCurrentSize)
	{
		ch = *FOutPtr;
		if (++FOutPtr >= FBuffer + BUFFER_SIZE)
			FOutPtr = FBuffer;
		FCurrentSize--;
	}
	return ch;
}

/*##########################################################################
#
#   Name       : TUserKeyboardDevice::Clear
#
#   Purpose....: Clear keyboard buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUserKeyboardDevice::Clear()
{
	FInPtr = FBuffer;
	FOutPtr = FBuffer;
	FCurrentSize = 0;
}
